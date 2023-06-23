// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.18;

import "forge-std/Script.sol";
import "../src/Recieve.sol";
import "../src/SigUtils.sol";
import "@hyperlane/solidity/contracts/interfaces/IMailbox.sol";
import "@hyperlane/solidity/contracts/interfaces/IInterchainGasPaymaster.sol";
import "@hyperlane/solidity/contracts/libs/TypeCasts.sol";

/// @notice This Script is used to send inter-chain Message using Hyperlane Messaging Api from sepolia to Fuji chain,
/// the Message contains the parameters to call the counter contract to increment the value and also calls the
/// Permit function on receiving side.It Automatically pays the Interchain Gas Paymaster to relay the message to 
/// destination chain.
contract CounterScript is Script {
    address deployer;
    address user1;
    address sigUtilsAddress;
    address recieve;
    address sepoliaMailbox;
    address igpAddress;

    function setUp() public {
        deployer = vm.envAddress("DEPLOYER");
        user1 = vm.envAddress("USER1");
        sigUtilsAddress = 0x1bC1f4fDd4eCF0BCd7afA38EA3d709EA1C585373;
        recieve = 0x3899012745BA12DF0f1A6CB390807EE932555E17;
        sepoliaMailbox = 0xCC737a94FecaeC165AbCf12dED095BB13F037685;
        igpAddress = 0xF987d7edcb5890cB321437d8145E3D51131298b6;
    }

    function run() public {
        vm.startBroadcast();

        SigUtils.Permit memory permit =
            SigUtils.Permit({owner: deployer, spender: user1, value: 1e18, nonce: 0, deadline: 500000000 days});

        SigUtils sigUtils = SigUtils(sigUtilsAddress);
        bytes32 digest = sigUtils.getTypedDataHash(permit);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(vm.envUint("PRIVATE_KEY"), digest);

        uint256 number = 20;
        uint256 amount = 1e18;
        uint256 duration = 500000000 days;
        bytes memory data = abi.encode(number, deployer, user1, amount, duration, v, r, s);

        uint32 avalancheDomain = 43113;
        bytes32 messageId =
            IMailbox(sepoliaMailbox).dispatch(avalancheDomain, TypeCasts.addressToBytes32(recieve), data);

        IInterchainGasPaymaster igp = IInterchainGasPaymaster(igpAddress);

        uint256 quote = igp.quoteGasPayment(avalancheDomain, 100000);

        igp.payForGas{value: quote}(messageId, avalancheDomain, 100000, msg.sender);
    }
}
