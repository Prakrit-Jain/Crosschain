// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

import "forge-std/Script.sol";
import "../src/contracts/ProxyOFT.sol";
import "../src/contracts/OFT.sol";

/**
 * @notice This is the Deployment Script For the deployment of the ProxyOFT contract on the Polygon - Mumbai chain
 * and OFT contract on Sepolia Chain.Also, It Sets up trusted Remotes for both of the chains.
 */
contract MyScript is Script {
    uint256 polygonFork;
    uint256 sepoliaFork;
    address deployer;

    function run() external {
        deployer = 0xf1a2f4f05c89190Aee18a1311De4ef1180e02037;
        vm.startBroadcast();
        polygonFork = vm.createFork(vm.envString("POLYGON_RPC_URL"));
        sepoliaFork = vm.createFork(vm.envString("SEPOLIA_RPC_URL"));
        vm.stopBroadcast();

        vm.selectFork(polygonFork);
        vm.startBroadcast();
        address token = vm.envAddress("PRAA_POLYGON");
        address _lzEndpoint = vm.envAddress("ENDPOINT_POLYGON");
        ProxyOFT oft_polygon = new ProxyOFT(_lzEndpoint, token);
        vm.stopBroadcast();

        vm.selectFork(sepoliaFork);
        vm.startBroadcast();
        address _lzEndpoint_sepolia = vm.envAddress("ENDPOINT_SEPOLIA");
        OFT oft_sepolia = new OFT("prakrit", "praa", _lzEndpoint_sepolia);
        vm.stopBroadcast();

        vm.selectFork(polygonFork);
        vm.startBroadcast();
        bytes memory trustedRemote1 = abi.encodePacked(address(oft_sepolia), address(oft_polygon));
        oft_polygon.setTrustedRemote(10161, trustedRemote1);
        vm.stopBroadcast();

        vm.selectFork(sepoliaFork);
        vm.startBroadcast();
        bytes memory trustedRemote2 = abi.encodePacked(address(oft_polygon), address(oft_sepolia));
        oft_sepolia.setTrustedRemote(10109, trustedRemote2);
        vm.stopBroadcast();
    }
}
