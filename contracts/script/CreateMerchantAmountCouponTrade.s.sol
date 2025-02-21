// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

import {IDProtocol} from "../src/IDProtocol.sol";
import {MerchantContract} from "../src/MerchantContract.sol";

contract TradeCouponScript is Script {

    IDProtocol idProtocol = IDProtocol(payable(0x187397D17D970de9eB259cAfC3f87a1106Cd5A4A));
    IDProtocol.MerchantRegistReq _req = IDProtocol.MerchantRegistReq({
        owner: address(0x0700Cc6268C9f33C4328530B231271D7FBeFB4fa),
        name: "First Merchant"
    });

    function setUp() public {}

    function logProductInfo(MerchantContract merchant, uint256 _id) public view {
        MerchantContract.Product memory productInfo = merchant.getProduct(_id);
        console.log("Product name: ", productInfo.name);
        console.log("Product price: ", productInfo.price);
        console.log("Product stock: ", productInfo.stock);
    }

    IDProtocol.MerchantRegistReq _req1 = IDProtocol.MerchantRegistReq({
        owner: address(0x0700Cc6268C9f33C4328530B231271D7FBeFB4fa),
        name: "Coffee Shop"
    });

    IDProtocol.MerchantRegistReq _req2 = IDProtocol.MerchantRegistReq({
        owner: address(0x0700Cc6268C9f33C4328530B231271D7FBeFB4fa),
        name: "Sports Retail"
    });

    address public merchant1 = address(0x0700Cc6268C9f33C4328530B231271D7FBeFB4fa);
    address public user2 = address(0x0700Cc6268C9f33C4328530B231271D7FBeFB4fa);

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        console.log("\n1. Registering merchant...");
        address _merchant = idProtocol.register(_req1);
        console.log("Merchant created: ", _merchant);

        MerchantContract merchant = MerchantContract(_merchant);

        console.log("\n2. Creating product 0...");
        merchant.createProduct(0.01 ether, 100, "Lavazza 2 Pack Crema E Gusto Ground Coffee 8.8oz/250g Each");

        logProductInfo(merchant, 0);

        console.log("\n3. Creating product 1...");
        merchant.createProduct(0.02 ether, 2000, "Lavazza Costiera Gran Aroma Ground Coffee 12oz Bag");

        logProductInfo(merchant, 1);


        uint256[] memory prodIds = new uint256[](2);
        prodIds[0] = 0;
        prodIds[1] = 1;

        uint256[] memory prodAmts = new uint256[](2);
        prodAmts[0] = 1;
        prodAmts[1] = 1;

        merchant.purchaseETH{value: 0.03 ether}(prodIds, prodAmts, 0);

        logProductInfo(merchant, 0);
        logProductInfo(merchant, 1);

        console.log("\n4. Creating coupon for first-time-user-only (0.1 ether)...");
        merchant.createCoupon(1, 0, false, 1, 0, 0.01 ether);

        prodIds = new uint256[](2);
        prodIds[0] = 0;
        prodIds[1] = 1;

        prodAmts = new uint256[](2);
        prodAmts[0] = 2;
        prodAmts[1] = 2;


        uint _total = 2 * 0.01 ether + 2 * 0.02 ether;
        vm.deal(user2, _total);
        console.log("\n5. User 2 purchasing products (with applied coupon- 0.1 ether discount)...");
        console.log("User 2 balance before purchase: ", address(user2).balance);
        merchant.purchaseETH{value: _total}(prodIds, prodAmts, 1);

        logProductInfo(merchant, 0);
        logProductInfo(merchant, 1);

        console.log("User 2 balance after purchase: ", address(user2).balance);
        
        vm.stopBroadcast();

        console.log("IDProtocol deployed at address: ", address(idProtocol));
    }
}

