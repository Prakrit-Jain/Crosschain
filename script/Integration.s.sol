// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

import "forge-std/Script.sol";
import "../src/contracts/ProxyOFT.sol";

/**
 * @notice This is the Integration Script For Sending the Cross-chain Transaction to send the
 * tokens from one chain to another.
 * @dev This send token form deployer address to the `user` address on sepolia using sendFrom function.
 */
contract MyScript is Script {
    function run() external {
        address deployer = 0xf1a2f4f05c89190Aee18a1311De4ef1180e02037;
        address ProxyOFTtoken = 0xA60ca44851e0652Bb6f5DCBe02Ea5e62CC7e36fd;
        address user = 0xa1829904358e01526A7589C3feaD8A5b97813A2c;

        vm.startBroadcast();
        ProxyOFT oft_polygon = ProxyOFT(ProxyOFTtoken);
        IERC20 i = IERC20(0x28FA15c44b705271B6FBFc452435016171F7e1bE);
        i.approve(address(oft_polygon), 10000000000000000000);
        bytes memory _toAddress = abi.encodePacked(user);
        oft_polygon.sendFrom{value: 1e18}(
            deployer, 10161, _toAddress, 10000000000000000000, payable(deployer), address(0x0), bytes("")
        );
        vm.stopBroadcast();
    }
}
