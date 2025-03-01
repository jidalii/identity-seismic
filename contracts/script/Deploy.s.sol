// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

import "../src/IDProtocol.sol";

contract DeployScript is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        IDProtocol idProtocol = new IDProtocol();

        vm.stopBroadcast();

        console.log("IDProtocol deployed at address: ", address(idProtocol));
    }
}
