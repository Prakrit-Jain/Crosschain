// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {MockMailbox} from "@hyperlane/solidity/contracts/mock/MockMailbox.sol";
import "@hyperlane/solidity/contracts/libs/TypeCasts.sol";
import "../src/Recieve.sol";
import "../src/Counter.sol";
import "../src/SigUtils.sol";
import {ERC20Token} from "../src/ERC20.sol";

/**
 * @dev This contract is used for testing the functionality of the Mailbox contract To
 * send the Interchain Messages.
 */
contract MailboxTest is Test {
    uint32 constant originDomain = 11155111;
    uint32 constant destinationDomain = 43113;
    MockMailbox originMailbox;
    MockMailbox destinationMailbox;
    ERC20Token internal token;
    SigUtils internal sigUtils;
    Counter internal c;
    Recieve internal recipient;
    uint256 internal ownerPrivateKey;
    uint256 internal spenderPrivateKey;
    address internal owner;
    address internal spender;

    event Received(uint32 origin, address sender, bytes body);

    /**
     * @dev Sets up the initial state for the tests.
     */
    function setUp() public {
        originMailbox = new MockMailbox(originDomain);
        destinationMailbox = new MockMailbox(destinationDomain);
        originMailbox.addRemoteMailbox(destinationDomain, destinationMailbox);
        destinationMailbox.addRemoteMailbox(originDomain, originMailbox);
        token = new ERC20Token();
        sigUtils = new SigUtils(token.DOMAIN_SEPARATOR());
        c = new Counter();
        ownerPrivateKey = 0xA11CE;
        spenderPrivateKey = 0xB0B;
        owner = vm.addr(ownerPrivateKey);
        spender = vm.addr(spenderPrivateKey);
        recipient = new Recieve(address(c), address(token));
    }

    /**
     * @dev Tests the receive functionality when sending a Interchain Message which on receiving side
     * calls the increment function of Counter Contract and permit function.Emit the Received event.
     */
    function testReceive_MessageInterChain() public {
        SigUtils.Permit memory permit =
            SigUtils.Permit({owner: owner, spender: spender, value: 1e18, nonce: 0, deadline: 5000000 days});

        bytes32 digest = sigUtils.getTypedDataHash(permit);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);

        bytes memory data = abi.encode(20, owner, spender, permit.value, permit.deadline, v, r, s);

        originMailbox.dispatch(destinationDomain, TypeCasts.addressToBytes32(address(recipient)), data);
        vm.expectEmit(true, true, true, false);
        emit Received(11155111, address(this), data);
        destinationMailbox.processNextInboundMessage();
        assertEq(c.count(), 20);
        assertEq(token.allowance(owner, spender), 1e18);
    }

    /**
     * @dev Tests the revert scenario when the deadline for the permit has expired.
     */
    function testRevert_ExpiredPermit() public {
        SigUtils.Permit memory permit =
            SigUtils.Permit({owner: owner, spender: spender, value: 1e18, nonce: 0, deadline: 1 days});

        bytes32 digest = sigUtils.getTypedDataHash(permit);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);

        bytes memory data = abi.encode(20, owner, spender, permit.value, permit.deadline, v, r, s);
        vm.warp(1 days + 1 seconds);

        originMailbox.dispatch(destinationDomain, TypeCasts.addressToBytes32(address(recipient)), data);
        vm.expectRevert("ERC20Permit: expired deadline");
        destinationMailbox.processNextInboundMessage();
    }

    /**
     * @dev Tests the revert scenario when the signer is changed for the permit signing.
     */
    function testRevert_InvalidSigner() public {
        SigUtils.Permit memory permit =
            SigUtils.Permit({owner: owner, spender: spender, value: 1e18, nonce: 0, deadline: 1 days});

        bytes32 digest = sigUtils.getTypedDataHash(permit);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(spenderPrivateKey, digest);

        bytes memory data = abi.encode(20, owner, spender, permit.value, permit.deadline, v, r, s);

        originMailbox.dispatch(destinationDomain, TypeCasts.addressToBytes32(address(recipient)), data);
        vm.expectRevert("ERC20Permit: invalid signature");
        destinationMailbox.processNextInboundMessage();
    }

    /**
     * @dev Tests the revert scenario when the nonce is not correctly setUp in signing message.
     */
    function testRevert_InvalidNonce() public {
        SigUtils.Permit memory permit =
            SigUtils.Permit({owner: owner, spender: spender, value: 1e18, nonce: 1, deadline: 1 days});

        bytes32 digest = sigUtils.getTypedDataHash(permit);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);

        bytes memory data = abi.encode(20, owner, spender, permit.value, permit.deadline, v, r, s);

        originMailbox.dispatch(destinationDomain, TypeCasts.addressToBytes32(address(recipient)), data);
        vm.expectRevert("ERC20Permit: invalid signature");
        destinationMailbox.processNextInboundMessage();
    }

    /**
     * @dev Tests the revert scenario when the Permit is called Twice.
     */
    function testRevert_SignatureReplay() public {
        SigUtils.Permit memory permit =
            SigUtils.Permit({owner: owner, spender: spender, value: 1e18, nonce: 0, deadline: 1 days});

        bytes32 digest = sigUtils.getTypedDataHash(permit);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);

        bytes memory data = abi.encode(20, owner, spender, permit.value, permit.deadline, v, r, s);

        originMailbox.dispatch(destinationDomain, TypeCasts.addressToBytes32(address(recipient)), data);
        destinationMailbox.processNextInboundMessage();

        originMailbox.dispatch(destinationDomain, TypeCasts.addressToBytes32(address(recipient)), data);
        vm.expectRevert("ERC20Permit: invalid signature");
        destinationMailbox.processNextInboundMessage();
    }
}
