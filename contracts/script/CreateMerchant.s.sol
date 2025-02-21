// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

import {IDProtocol} from "../src/IDProtocol.sol";

contract CreateMerchantScript is Script {

    IDProtocol idProtocol = IDProtocol(payable(0xA5Ce3b6DC60CC295F4c8bB17016d3524322B25c0));
    IDProtocol.MerchantRegistReq _req = IDProtocol.MerchantRegistReq({
        owner: address(0x221bA23331E5395F2018eDafc2E0E9fF2Acb1aDa),
        name: "First Merchant"
    });

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        
        idProtocol.register(_req);
        vm.stopBroadcast();

        console.log("IDProtocol deployed at address: ", address(idProtocol));
    }
}

