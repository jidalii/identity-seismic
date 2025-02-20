// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "./IDProtocol.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MerchantContract {
    address business;
    string name;
    address core;
    address public ETH_ADDRESS = 0x0;
    mapping(address => bool) allowedTokens;

    constructor(address businessAddr, string memory businessName) {
        business = businessAddr;
        name = businessName;
        core = msg.sender;
        allowedTokens[ETH_ADDRESS] = true;
    }

    struct Coupon {
        uint256 minTxnAmt;
        uint256 minEthAmt;
        bool firstTimeOnly;
        uint256 usage;
        mapping(saddress => uint256) customerCount;
        bool isActive;
    }

    struct Product {
        mapping(address => uint256) prices;
        uint256 stock;
    }

    mapping(uint256 => Product) products;
    mapping(uint256 => Coupon) coupons;
    uint256 newProdId;
    uint256 newCoupId;

    modifier businessOnly() {
        require(msg.sender == business, "Only the business can call this.");
        _;
    }

    function purchaseETH(uint256[][] memory txnDetails, uint256 coupId) external payable {
        uint256 totalPrice;
        for (uint256 i = 0; i < txnDetails.length; i++) {
            uint256 id = txnDetails[i][0];
            uint256 amt = txnDetails[i][1];
            totalPrice += (products[id].prices[ETH_ADDRESS] * amt);
        }

        require(msg.value == totalPrice);

        for (uint256 i = 0; i < txnDetails.length; i++) {
            uint256 id = txnDetails[i][0];
            uint256 amt = txnDetails[i][1];
            adjustStock(id, amt);
        }

        IDProtocol(core).updateUserEntry(business, saddress(msg.sender), suint(msg.value));
    }

    function purchaseERC20(uint256[][] memory txnDetails, uint256 coupId) external payable {
        uint256 totalPrice;
        for (uint256 i = 0; i < txnDetails.length; i++) {
            uint256 id = txnDetails[i][0];
            uint256 amt = txnDetails[i][1];
            totalPrice += (products[id].prices[ETH_ADDRESS] * amt);
        }

        IERC20.transferFrom(msg.sender, address(this), totalPrice);

        for (uint256 i = 0; i < txnDetails.length; i++) {
            uint256 id = txnDetails[i][0];
            uint256 amt = txnDetails[i][1];
            adjustStock(id, amt);
        }

        suint purchaseAmount; // todo: fix this to call price oracle
        IDProtocol(core).updateUserEntry(business, saddress(msg.sender), purchaseAmount);
    }

    function adjustStock(uint256 prodId, uint256 amount) internal {
        products[prodId].stock -= amount;
    }

    function createProduct(uint256 prc, uint256 stck) public businessOnly {
        Product memory newProduct;
        newProduct.price = prc;
        newProduct.stock = stck;
        products[newProdId] = newProduct;
        newProdId++;
    }

    function addStock(uint256 prodId, uint256 amt) public businessOnly {
        products[prodId].stock += amt;
    }

    function createCoupon(uint256 txnAmt, uint256 ethAmt, bool firstTime, uint256 usageNum) public businessOnly {
        Coupon memory newCoupon;
        newCoupon.minTxnAmt = txnAmt;
        newCoupon.minEthAmt = ethAmt;
        newCoupon.firstTimeOnly = firstTime;
        newCoupon.usage = usageNum;
        newCoupon.isActive = true;
        coupons[newCoupId] = newCoupon;
        newCoupId++;
    }

    function deactivateCoupon(uint256 coupId) public businessOnly {
        coupons[coupId].isActive = false;
    }

    function approveToken(address token) public businessOnly {
        allowedTokens[token] = true;
    }

    function collectRevenue(address token) external payable businessOnly {
        require(allowedTokens[token], "Token is not approved.");
        if (token == ETH_ADDRESS) {
            uint256 fee = address(this).balance / 100;
            uint256 remainder = address(this).balance - fee;

            bool success = business.call{value: remainder}("");
            require(success, "Transfer failed.");
            bool feeSuccess = core.call{value: fee}("");
            require(feeSuccess, "Fee transfer failed.");
        } else {
            uint256 fee = address(this).balanceOf(token) / 100;
            uint256 remainder = address(this).balanceOf(token) - fee;

            IERC20.transferFrom(address(this), business, remainder);
            IERC20.transferFrom(address(this), core, fee);
        }
    }
}
