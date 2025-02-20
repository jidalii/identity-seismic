// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "./IDProtocol.sol";

contract MerchantContract {
    address owner;
    string name;
    address IdProtocol;

    constructor(address companyAddr, string companyName) {
        owner = companyAddr;
        name = companyName;
        IdProtocol = msg.sender;
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
        uint price;
        uint stock;
    }

    mapping(uint => Product) products;
    mapping(uint => Coupon) coupons;
    uint newProdId;
    uint newCoupId;


    function purchaseETH(uint[][] txnDetails, uint coupId) external payable {
        uint totalPrice;
        for (uint i =0; i < txnDetails.length; i++){
            uint id = txndetails[i][0];
            uint amt = txndetails[i][1];
            totalPrice += (products[id].price * amt)
        }

        require(msg.value == totalPrice);

        for (uint i =0; i < txnDetails.length; i++){
            uint id = txndetails[i][0];
            uint amt = txndetails[i][1];
            adjustStock(id, amt);
        }
        // todo: call update state function in core contract (totalPrice, 1, false) ... the latter 2 can be hardcorded in the contract itself
    }

    function purchaseERC20(uint prodId, uint coupId) external payable {
        // todo: sort out erc20 stuffs
    }

    function adjustStock(uint prodId, uint amount) internal {
        products[prodId].stock -= amount;
    }

    function createCoupon(uint txnAmt, uint ethAmt, bool firstTime, uint usageNum) public {
        Coupon private newCoupon;
        newCoupon.minTxnAmt = txnAmt;
        newCoupon.minEthAmt = ethAmt;
        newCoupon.firstTimeOnly = firstTime;
        newCoupon.usage = usageNum;
        newCoupon.isActive = true;
        coupons[newCoupId] = newCoupon;
        newCoupId++;
    }

    function createProduct(uint prc, uint stck) public {
        Product private newProduct;
        newProduct.price = prc;
        newProduct.stock = stck;
        products[newProdId] = newProduct;
        newProdId++;
    }

    function deactivateCoupon(uint coupId) public {
        coupons[coupId].isActive = false;
    }

    function addStock(uint prodId, uint amt) public {
        products[prodId].stock += amt;
    }
}
