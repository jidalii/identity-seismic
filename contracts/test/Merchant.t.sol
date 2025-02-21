// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import {CheatCodes} from "./ICheatCodes.sol";

import {IDProtocol} from "src/IDProtocol.sol";
import {ERC20} from "src/ERC20.sol";
import {MerchantContract} from "src/MerchantContract.sol";

contract IDProtocolTest is Test {
    IDProtocol idProtocol;

    CheatCodes cheats = CheatCodes(VM_ADDRESS);

    address admin = address(10000000);
    address merchant1 = address(110000000);
    address user1 = address(1200000000);
    address user2 = address(1300000000);

    IDProtocol.MerchantRegistReq _req1 = IDProtocol.MerchantRegistReq({
        owner: merchant1,
        name: "Coffee Shop"
    });

    IDProtocol.MerchantRegistReq _req2 = IDProtocol.MerchantRegistReq({
        owner: merchant1,
        name: "Sports Retail"
    });

    function setUp() public {
        vm.prank(admin);
        idProtocol = new IDProtocol();
    }

    IDProtocol.OffchainIdentity offchain = IDProtocol.OffchainIdentity({
            isGithub: sbool(true),
            githubStar: suint256(100),
            isTwitter: sbool(true),
            twitterFollower: suint256(100)
        });

    function test_createMerchant() public {
        vm.prank(merchant1);
        idProtocol.register(_req1);
    }

    function logProductInfo(MerchantContract merchant, uint256 _id) public view {
        MerchantContract.Product memory productInfo = merchant.getProduct(_id);
        console.log("Product name: ", productInfo.name);
        console.log("Product price: ", productInfo.price);
        console.log("Product stock: ", productInfo.stock);
    }

    function test_purchaseWithoutCoupon() public {
        console.log("\n1. Registering merchant...");
        vm.prank(merchant1);
        address _merchant = idProtocol.register(_req1);
        console.log("Merchant created: ", _merchant);

        MerchantContract merchant = MerchantContract(_merchant);

        console.log("\n2. Creating product 0...");
        vm.prank(merchant1);
        merchant.createProduct(0.1 ether, 100, "Lavazza 2 Pack Crema E Gusto Ground Coffee 8.8oz/250g Each");

        logProductInfo(merchant, 0);

        console.log("\n3. Creating product 1...");
        vm.prank(merchant1);
        merchant.createProduct(0.2 ether, 2000, "Lavazza Costiera Gran Aroma Ground Coffee 12oz Bag");

        logProductInfo(merchant, 1);


        uint256[] memory prodIds = new uint256[](2);
        prodIds[0] = 0;
        prodIds[1] = 1;

        uint256[] memory prodAmts = new uint256[](2);
        prodAmts[0] = 1;
        prodAmts[1] = 1;

        vm.deal(user1, 0.3 ether);
        console.log("\n4. User 1 purchasing products (without applied coupon)...");
        console.log("User 1 balance before purchase: ", address(user1).balance);
        vm.prank(user1);
        merchant.purchaseETH{value: 0.3 ether}(prodIds, prodAmts, 0);

        logProductInfo(merchant, 0);
        logProductInfo(merchant, 1);
        console.log("User 1 balance after purchase: ", address(user1).balance);
        assertEq(0, address(user1).balance);
    }

    function test_purchaseWithCoupon() public {
        console.log("\n1. Registering merchant...");
        vm.prank(merchant1);
        address _merchant = idProtocol.register(_req1);
        console.log("Merchant created: ", _merchant);

        MerchantContract merchant = MerchantContract(_merchant);

        console.log("\n2. Creating product 0...");
        vm.prank(merchant1);
        merchant.createProduct(0.1 ether, 100, "Lavazza 2 Pack Crema E Gusto Ground Coffee 8.8oz/250g Each");

        logProductInfo(merchant, 0);

        console.log("\n3. Creating product 1...");
        vm.prank(merchant1);
        merchant.createProduct(0.2 ether, 2000, "Lavazza Costiera Gran Aroma Ground Coffee 12oz Bag");

        logProductInfo(merchant, 1);


        uint256[] memory prodIds = new uint256[](2);
        prodIds[0] = 0;
        prodIds[1] = 1;

        uint256[] memory prodAmts = new uint256[](2);
        prodAmts[0] = 1;
        prodAmts[1] = 1;

        vm.deal(user1, 0.3 ether);
        vm.prank(user1);
        merchant.purchaseETH{value: 0.3 ether}(prodIds, prodAmts, 0);

        logProductInfo(merchant, 0);
        logProductInfo(merchant, 1);
        assertEq(0, address(user1).balance);

        console.log("\n4. Creating coupon for first-time-user-only (0.1 ether)...");
        vm.prank(merchant1);
        merchant.createCoupon(0, 0, true, 1, 0, 0.1 ether);

        prodIds = new uint256[](2);
        prodIds[0] = 0;
        prodIds[1] = 1;

        prodAmts = new uint256[](2);
        prodAmts[0] = 10;
        prodAmts[1] = 5;


        uint _total = 10 * 0.1 ether + 5 * 0.2 ether;
        vm.deal(user2, _total);
        console.log("\n5. User 2 purchasing products (with applied coupon- 0.1 ether discount)...");
        console.log("User 2 balance before purchase: ", address(user2).balance);
        vm.prank(user2);
        merchant.purchaseETH{value: _total}(prodIds, prodAmts, 1);

        logProductInfo(merchant, 0);
        logProductInfo(merchant, 1);

        console.log("User 2 balance after purchase: ", address(user2).balance);
        assertEq(0.1 ether, address(user2).balance);
    }

    function test_purchaseWithCouponOff() public {
        console.log("\n1. Registering merchant...");
        vm.prank(merchant1);
        address _merchant = idProtocol.register(_req1);
        console.log("Merchant created: ", _merchant);

        MerchantContract merchant = MerchantContract(_merchant);

        console.log("\n2. Creating product 0...");
        vm.prank(merchant1);
        merchant.createProduct(0.1 ether, 100, "Lavazza 2 Pack Crema E Gusto Ground Coffee 8.8oz/250g Each");

        logProductInfo(merchant, 0);

        console.log("\n3. Creating product 1...");
        vm.prank(merchant1);
        merchant.createProduct(0.2 ether, 2000, "Lavazza Costiera Gran Aroma Ground Coffee 12oz Bag");

        logProductInfo(merchant, 1);


        uint256[] memory prodIds = new uint256[](2);
        prodIds[0] = 0;
        prodIds[1] = 1;

        uint256[] memory prodAmts = new uint256[](2);
        prodAmts[0] = 1;
        prodAmts[1] = 1;

        vm.deal(user1, 0.3 ether);
        // console.log("\n4. User 1 purchasing products (without applied coupon)...");
        // console.log("User 1 balance before purchase: ", address(user1).balance);
        vm.prank(user1);
        merchant.purchaseETH{value: 0.3 ether}(prodIds, prodAmts, 0);

        logProductInfo(merchant, 0);
        logProductInfo(merchant, 1);
        // console.log("User 1 balance after purchase: ", address(user1).balance);
        assertEq(0, address(user1).balance);


        // console.log("5. Creating coupon for first-time-user-only (0.1 ether)...");
        vm.prank(merchant1);
        merchant.createCoupon(0, 0, true, 1, 0, 0.1 ether);

        prodIds = new uint256[](2);
        prodIds[0] = 0;
        prodIds[1] = 1;

        prodAmts = new uint256[](2);
        prodAmts[0] = 10;
        prodAmts[1] = 5;


        uint _total = 10 * 0.1 ether + 5 * 0.2 ether;
        vm.deal(user2, _total);
        // console.log("\n6. User 2 purchasing products (with applied coupon- 0.1 ether discount)...");
        // console.log("User 2 balance before purchase: ", address(user2).balance);
        vm.prank(user2);
        merchant.purchaseETH{value: _total}(prodIds, prodAmts, 1);

        logProductInfo(merchant, 0);
        logProductInfo(merchant, 1);

        // console.log("User 2 balance after purchase: ", address(user2).balance);
        assertEq(0.1 ether, address(user2).balance);


        console.log("\n4. Creating coupon for first-time-user-only 30% OFF)...");
        vm.prank(merchant1);
        merchant.createCoupon(0, 1 ether, false, 1, 3000, 0);

        prodIds = new uint256[](2);
        prodIds[0] = 0;
        prodIds[1] = 1;

        prodAmts = new uint256[](2);
        prodAmts[0] = 20;
        prodAmts[1] = 10;


        _total = 20 * 0.1 ether + 10 * 0.2 ether;
        uint refund = _total * 3000 / 10000;
        vm.deal(user2, _total);
        console.log("\n5. User 2 purchasing products (with applied coupon- 30% OFF)...");
        console.log("User 2 balance before purchase: ", address(user2).balance);
        vm.prank(user2);
        merchant.purchaseETH{value: _total}(prodIds, prodAmts, 2);

        logProductInfo(merchant, 0);
        logProductInfo(merchant, 1);

        console.log("User 2 balance after purchase: ", address(user2).balance);
        assertEq(refund, address(user2).balance);

    }

    function test_purchaseWithERC20() public {
        console.log("\n0. Deploying ERC20 token...");
        ERC20 token = new ERC20("USD Thether", "USDT", 18);
        console.log("ERC20 Token address: ", address(token));
        
        console.log("\n1. Registering merchant...");
        vm.prank(merchant1);
        address _merchant = idProtocol.register(_req1);
        console.log("Merchant created: ", _merchant);

        MerchantContract merchant = MerchantContract(_merchant);

        console.log("\n2. Creating product 0...");
        vm.prank(merchant1);
        merchant.createProduct(0.1 ether, 100, "Lavazza 2 Pack Crema E Gusto Ground Coffee 8.8oz/250g Each");

        logProductInfo(merchant, 0);

        console.log("\n3. Creating product 1...");
        vm.prank(merchant1);
        merchant.createProduct(0.2 ether, 2000, "Lavazza Costiera Gran Aroma Ground Coffee 12oz Bag");

        logProductInfo(merchant, 1);


        uint256[] memory prodIds = new uint256[](2);
        prodIds[0] = 0;
        prodIds[1] = 1;

        uint256[] memory prodAmts = new uint256[](2);
        prodAmts[0] = 1;
        prodAmts[1] = 1;

        // vm.deal(user1, 0.3 ether);
        vm.startPrank(user1);
        token.mint(user1, 0.3 * 2000 ether);
        token.approve(address(merchant), 0.3 * 2000 ether);
        vm.stopPrank();
        console.log("\n4. User 1 purchasing products (without applied coupon)...");
        console.log("User 1 USDT balance before purchase: ", token.balanceOf(user1));
        vm.prank(user1);
        merchant.purchaseERC20(address(token), prodIds, prodAmts, 0);

        logProductInfo(merchant, 0);
        logProductInfo(merchant, 1);
        console.log("User 1 USDT balance after purchase: ", token.balanceOf(user1));
        assertEq(0, token.balanceOf(user1));
    }

    function test_withdrawProfits() public {
        vm.prank(merchant1);
        address _merchant = idProtocol.register(_req1);

        MerchantContract merchant = MerchantContract(_merchant);

        vm.prank(merchant1);
        merchant.createProduct(1 ether, 100, "Lavazza 2 Pack Crema E Gusto Ground Coffee 8.8oz/250g Each");

        vm.prank(merchant1);
        merchant.createProduct(2 ether, 2000, "Lavazza Costiera Gran Aroma Ground Coffee 12oz Bag");

        uint256[] memory prodIds = new uint256[](2);
        prodIds[0] = 0;
        prodIds[1] = 1;

        uint256[] memory prodAmts = new uint256[](2);
        prodAmts[0] = 10;
        prodAmts[1] = 10;

        uint _total = 10 * 1 ether + 10 * 2 ether;
        console.log("User 1 made a purchase of total: ", _total);
        vm.deal(user1, _total);
        vm.prank(user1);
        merchant.purchaseETH{value: _total}(prodIds, prodAmts, 0);

        assertEq(0, address(user1).balance);

        vm.prank(merchant1);

        merchant.collectRevenue(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE, merchant1);
        console.log("Merchant balance after withdrawal: ", merchant1.balance);
        console.log("Transaction fee for withdrawal: ", 30 ether - merchant1.balance);
    }
}
