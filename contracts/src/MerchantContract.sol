// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "./IDProtocol.sol";
import "../lib/openzepplin-contracts/contract/token/ERC20/IERC20.sol";

contract MerchantContract {
    address business;
    string name;
    address core;
    address public ETH_ADDRESS = 0x0;
    mapping(address => bool) allowedTokens;
    constructor(address businessAddr, string businessName) {
        business = businessAddr;
        name = businessName;
        core = msg.sender;
        allowedToken[ETH_ADDRESS] = true;
    }

    struct Coupon {
        uint minTxnAmt;
        uint minEthAmt;
        bool firstTimeOnly;
        uint usage;
        mapping(saddress => uint) customerCount;
        bool isActive;
    }

    struct Product {
        mapping(address => uint) prices;
        uint stock;
    }

    mapping(uint => Product) products;
    mapping(uint => Coupon) coupons;
    uint newProdId;
    uint newCoupId;

    modifier businessOnly() {
        require(msg.sender == business, "Only the business can call this.");
        _;
    }

    function purchaseETH(uint[][] txnDetails, uint coupId) external payable {
        uint totalPrice;
        for (uint i =0; i < txnDetails.length; i++){
            uint id = txndetails[i][0];
            uint amt = txndetails[i][1];
            totalPrice += (products[id].prices[ETH_ADDRESS] * amt)
        }

        require(msg.value == totalPrice);

        for (uint i =0; i < txnDetails.length; i++){
            uint id = txndetails[i][0];
            uint amt = txndetails[i][1];
            adjustStock(id, amt);
        }
        // todo: call update state function in core contract (totalPrice, transaction amount, first time) ... the latter 2 can be hardcorded in the contract itself
    }

    function purchaseERC20(uint[][] txnDetails, uint coupId) external payable {
        uint totalPrice;
        for (uint i =0; i < txnDetails.length; i++){
            uint id = txndetails[i][0];
            uint amt = txndetails[i][1];
            totalPrice += (products[id].prices[ETH_ADDRESS] * amt)
        }

        require(IERC20.allowance(msg.sender, address(this)) >= totalPrice, "Insufficient allowance");
        require(IERC20.balanceOf(msg.sender) == totalPrice, "Insufficient balance");

        bool success = IERC20.transferFrom(msg.sender, address(this), totalPrice);
        require(success, "Token transfer failed");

        for (uint i =0; i < txnDetails.length; i++){
            uint id = txndetails[i][0];
            uint amt = txndetails[i][1];
            adjustStock(id, amt);
        }
        // todo: call update state function in core contract (totalPrice, transaction amount, first time) ... the latter 2 can be hardcorded in the contract itself
    }

    function adjustStock(uint prodId, uint amount) internal {
        products[prodId].stock -= amount;
    }

    function createCoupon(uint txnAmt, uint ethAmt, bool firstTime, uint usageNum) public businessOnly() {
        Coupon private newCoupon;
        newCoupon.minTxnAmt = txnAmt;
        newCoupon.minEthAmt = ethAmt;
        newCoupon.firstTimeOnly = firstTime;
        newCoupon.usage = usageNum;
        newCoupon.isActive = true;
        coupons[newCoupId] = newCoupon;
        newCoupId++;
    }

    function createProduct(uint prc, uint stck) public businessOnly() {
        Product private newProduct;
        newProduct.price = prc;
        newProduct.stock = stck;
        products[newProdId] = newProduct;
        newProdId++;
    }

    function deactivateCoupon(uint coupId) public businessOnly() {
        coupons[coupId].isActive = false;
    }

    function addStock(uint prodId, uint amt) public businessOnly() {
        products[prodId].stock += amt;
    }

    function approveToken(address token) public businessOnly() {
        allowedTokens[token] = true;
    }
    function collectRevenue(address token) external payable businessOnly() {
        require(allowedTokens[token],"Token is not approved.");
        if (token == ETH_ADDRESS){
            uint fee = address(this).balance / 100;
            uint remainder = address(this).balance - fee;

            bool success = business.call{value: remainder}("");
            require(success, "Transfer failed.");
            bool success = core.call{value: fee}("");
            require(success, "Transfer failed.");
        } else {
            uint fee = address(this).balanceOf(token) / 100;
            uint remainder = address(this).balanceOf(token) - fee;

            bool success = IERC20.transferFrom(address(this), business, remainder);
            require(success, "Token transfer failed");
            bool success = IERC20.transferFrom(address(this), core, fee);
            require(success, "Token transfer failed");
        }
    }
}
