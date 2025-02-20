// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "./IDProtocol.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MerchantContract {
    /// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~merchant data~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    /// @notice vars about the contract details
    address payable business;
    string name;
    address payable core;
    address public ETH_ADDRESS = address(0x0);
    mapping(address => bool) allowedTokens;

    constructor(address businessAddr, string memory businessName) {
        business = payable(businessAddr);
        name = businessName;
        core = payable(msg.sender);
        allowedTokens[ETH_ADDRESS] = true;
    }

    /// @notice struct detailing the business products
    struct Product {
        uint256 price;
        uint256 stock;
    }

    /// @notice struct detailing the coupon
    struct Coupon {
        uint256 minTxnAmt;
        uint256 minEthAmt;
        bool firstTimeOnly;
        uint256 usage;
        mapping(saddress => uint256) customerCount;
        bool isActive;
    }

    /// @notice active mappings/global vars
    mapping(uint256 => Product) products;
    mapping(uint256 => Coupon) coupons;
    uint256 newProdId;
    uint256 newCoupId;

    /// @notice modifier to determine if only the business can call the function
    modifier businessOnly() {
        require(msg.sender == business, "Only the business can call this.");
        _;
    }

/// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~transaction functions~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    /// @notice ETH/native token specific transaction function
    function purchaseETH(uint256[] memory txnProds, uint256[] memory txnAmts, uint256 coupId) external payable {
        require(txnProds.length == txnAmts.length, "Incorrect transaction details.");
        uint256 totalPrice;
        for (uint256 i = 0; i < txnProds.length; i++) {
            totalPrice += (products[txnProds[i]] * txnAmts[i]);
        }

        require(msg.value == totalPrice);

        for (uint256 i = 0; i < txnProds.length; i++) {
            uint256 id = txnProds[i];
            uint256 amt = txnAmts[i];
            adjustStock(id, amt);
        }

        IDProtocol(core).updateUserEntry(business, saddress(msg.sender), suint(msg.value));
    }

    /// @notice token transaction function
    function purchaseERC20(address token, uint256[] memory txnProds, uint256[] memory txnAmts, uint256 coupId) external payable {
        require(txnProds.length == txnAmts.length, "Incorrect transaction details.");
        uint256 totalPrice;
        for (uint256 i = 0; i < txnProds.length; i++) {
            totalPrice += (products[txnProds[i]] * txnAmts[i]);
        }

        IERC20(token).transferFrom(msg.sender, address(this), totalPrice);

        for (uint256 i = 0; i < txnProds.length; i++) {
            uint256 id = txnProds[i];
            uint256 amt = txnAmts[i];
            adjustStock(id, amt);
        }

        suint purchaseAmount; // todo: fix this to call price oracle
        IDProtocol(core).updateUserEntry(business, saddress(msg.sender), purchaseAmount);
    }

    /// @notice helper function to adjust the stock of a prod
    function adjustStock(uint256 prodId, uint256 amount) internal {
        products[prodId].stock -= amount;
    }
/// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~merchant functions~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    /// @notice function for businesses to create products
    function createProduct(uint256 prc, uint256 stck) public businessOnly {
        Product storage newProduct;
        newProduct.price = prc;
        newProduct.stock = stck;
        products[newProdId] = newProduct;
        newProdId++;
    }

    /// @notice function to adjust a products' stock
    function addStock(uint256 prodId, uint256 amt) public businessOnly {
        products[prodId].stock += amt;
    }

    /// @notice function for businesses to create coupons
    function createCoupon(uint256 txnAmt, uint256 ethAmt, bool firstTime, uint256 usageNum) public businessOnly {
        Coupon storage newCoupon;
        newCoupon.minTxnAmt = txnAmt;
        newCoupon.minEthAmt = ethAmt;
        newCoupon.firstTimeOnly = firstTime;
        newCoupon.usage = usageNum;
        newCoupon.isActive = true;
        coupons[newCoupId] = newCoupon;
        newCoupId++;
    }

    /// @notice function to deactivate a coupon
    function deactivateCoupon(uint256 coupId) public businessOnly {
        coupons[coupId].isActive = false;
    }

    /// @notice ERC20 approval process
    function approveToken(address token) public businessOnly {
        allowedTokens[token] = true;
    }

    /// @notice function for business to move revenue to their wallet 
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
