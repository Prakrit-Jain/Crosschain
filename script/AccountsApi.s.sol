// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.18;

import "forge-std/Script.sol";
import "../src/Counter.sol";
import "../src/SigUtils.sol";
import "@hyperlane/solidity/contracts/interfaces/middleware/IInterchainAccountRouter.sol";
import "@hyperlane/solidity/contracts/interfaces/IInterchainGasPaymaster.sol";
import "@hyperlane/solidity/contracts/libs/Call.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";

/// @notice This Script is used to send inter-chain call using Hyperlane Accounts Api from sepolia to Fuji chain,
/// Here 2 calls are done simultaneously. First one to counter contract deployed on fuji chain to increase the
/// value of its variable and Second To call the permit funciton to set Allowance for the spender account on
/// receiving side.It Automatically pays the Interchain Gas Paymaster to relay the message to
/// destination chain.
contract CounterScript is Script {
    address deployer;
    address user1;
    address igpAddress;
    address recipient1;
    address recipient2;

    function setUp() public {
        deployer = vm.envAddress("DEPLOYER");
        user1 = vm.envAddress("USER1");
        igpAddress = 0xF987d7edcb5890cB321437d8145E3D51131298b6;
        recipient1 = 0x0e46caFAE2A3Aab7070A300ADd05077c18457098;
        recipient2 = 0xf500Fe3FeB50a807024299d9e2657D2c6142687c;
    }

    function run() public {
        vm.startBroadcast();
        SigUtils sigUtils = new SigUtils(vm.envBytes32("DOMAIN_SEPARATOR"));

        SigUtils.Permit memory permit =
            SigUtils.Permit({owner: deployer, spender: user1, value: 1e18, nonce: 1, deadline: 5000000 days});

        bytes32 digest = sigUtils.getTypedDataHash(permit);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(vm.envUint("PRIVATE_KEY"), digest);

        uint32 ethereumDomain = 43113;
        address icaRouter = 0xB057Fb841027a8554521DcCdeC3c3474CaC99AB5;

        CallLib.Call memory call1 = CallLib.Call({
            to: bytes32(uint256(uint160(recipient1))),
            value: 0,
            data: abi.encodeCall(Counter.increment, (20))
        });

        CallLib.Call memory call2 = CallLib.Call({
            to: bytes32(uint256(uint160(address(recipient2)))),
            value: 0,
            data: abi.encodeCall(IERC20Permit.permit, (deployer, user1, 1e18, 5000000 days, v, r, s))
        });

        CallLib.Call[] memory arrayOfCalls = new CallLib.Call[](2);
        arrayOfCalls[0] = call1;
        arrayOfCalls[1] = call2;

        bytes32 messageId = IInterchainAccountRouter(icaRouter).callRemote(ethereumDomain, arrayOfCalls);

        IInterchainGasPaymaster igp = IInterchainGasPaymaster(igpAddress);
        igp.payForGas{value: 1e16}(messageId, ethereumDomain, 55000, msg.sender);
        vm.stopBroadcast();
    }
}
