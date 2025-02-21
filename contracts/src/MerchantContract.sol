// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "./IDProtocol.sol";
import "./IERC20.sol";
import {MockOracle} from "./MockOracle.sol";

// import "forge-std/console.sol";

contract MerchantContract {
    /// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~merchant data~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    /// @notice vars about the contract details
    address payable public business;
    string public name;
    address payable public core;
    address public oracle;
    address public ETH_ADDRESS = address(0x0);
    mapping(address => bool) allowedTokens;

    constructor(address businessAddr, string memory businessName, address _oracle) {
        business = payable(businessAddr);
        name = businessName;
        core = payable(msg.sender);
        allowedTokens[ETH_ADDRESS] = true;
        oracle = _oracle;

        newCoupId = 1;
    }

    /// @notice struct detailing the business products
    struct Product {
        uint256 price;
        uint256 stock;
        string name;
    }

    /// @notice struct detailing the coupon
    struct Coupon {
        uint256 minTxnAmt;
        uint256 minEthAmt;
        bool firstTimeOnly;
        uint256 usage;
        mapping(address => suint256) customerCount;
        uint256 discountBp;
        uint256 discountAmt;
        bool isActive;
    }

    /// @notice active mappings/global vars
    mapping(uint256 => Product) private products;
    mapping(uint256 => Coupon) private coupons;
    uint256 newProdId;
    uint256 newCoupId;

    error InvalidCouponCreation();
    error InvalidCouponUsage();

    /// @notice modifier to determine if only the business can call the function
    modifier businessOnly() {
        require(msg.sender == business, "Only the business can call this.");
        _;
    }

    function transferETH(address _address, uint256 amount) private returns (bool) {
        require(_address != address(0), "Zero addresses are not allowed.");

        (bool os,) = payable(_address).call{value: amount}("");

        return os;
    }

    function getProduct(uint256 id) public view returns (Product memory) {
        return products[id];
    }

    /// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~transaction functions~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    /// @notice ETH/native token specific transaction function
    function purchaseETH(uint256[] memory prodIds, uint256[] memory prodAmts, uint256 coupId) external payable {
        _validatePurchase(prodIds, prodAmts, coupId);

        uint256 totalPrice = _calculateTotalPrice(prodIds, prodAmts);

        Coupon storage _coupon = coupons[coupId];

        uint256 finalPriceTk = _calculateDiscountedPrice(_coupon, totalPrice);

        // update coupon state
        uint256 newCnt = uint(_coupon.customerCount[address(msg.sender)]) +1;
        _coupon.customerCount[address(msg.sender)] = suint(newCnt);

        uint256 gap = msg.value - finalPriceTk;
        // console.log("gap: ", gap);
        // console.log("msg.valu: ", msg.value);
        // console.log("balance: ", address(this).balance);
        if (gap > 0) {
            require(transferETH(msg.sender, gap), "failed to refund");
        }

        adjustStock(prodIds, prodAmts);

        IDProtocol(core).updateUserEntry(address(this), saddress(msg.sender), suint(msg.value));
    }

    /// @notice token transaction function
    function purchaseERC20(address token, uint256[] memory prodIds, uint256[] memory prodAmts, uint256 coupId)
        external
        payable
    {
        _validatePurchase(prodIds, prodAmts, coupId);
        require(allowedTokens[token], "Token is not approved");

        uint256 totalPriceTk = _calculateTotalPrice(prodIds, prodAmts);
        Coupon storage _coupon = coupons[coupId];

        uint256 finalPriceTk = _calculateDiscountedPrice(_coupon, totalPriceTk);

        // update coupon state
        uint256 newCnt = uint(_coupon.customerCount[address(msg.sender)]) +1;
        _coupon.customerCount[address(msg.sender)] = suint(newCnt);

        IERC20(token).transferFrom(msg.sender, address(this), finalPriceTk);

        adjustStock(prodIds, prodAmts);

        suint purchaseAmount = suint(finalPriceTk * MockOracle(oracle).calcRatio(token));
        IDProtocol(core).updateUserEntry(business, saddress(msg.sender), purchaseAmount);
    }

    function _calculateDiscountedPrice(Coupon storage _coupon, uint256 totalPriceTk) internal view returns (uint256) {
        // check if the coupon is valid
        bool isSuccess = IDProtocol(core).checkValidCouponApply(
            msg.sender, _coupon.minTxnAmt, _coupon.minEthAmt, _coupon.firstTimeOnly
        );
        if (!isSuccess) {
            revert InvalidCouponUsage();
        }

        // cal discounted price
        uint256 finalPriceTk;
        if (_coupon.discountAmt > 0) {
            if (totalPriceTk < _coupon.discountAmt) {
                return totalPriceTk;
            }
            finalPriceTk = totalPriceTk - _coupon.discountAmt;
        } else {
            finalPriceTk = totalPriceTk - totalPriceTk * _coupon.discountBp / 10_000;
        }
        return finalPriceTk;
    }

    function _validatePurchase(uint256[] memory prodIds, uint256[] memory prodAmts, uint256 coupId) internal view {
        require(prodIds.length == prodAmts.length, "Incorrect transaction details");
        for (uint256 i = 0; i < prodIds.length; i++) {
            uint256 id = prodIds[i];
            uint256 amt = prodAmts[i];
            require(products[id].stock >= amt, "Insufficient stock");
        }

        if (coupId == 0) {
            return;
        }
        require(coupons[coupId].isActive, "Coupon is not active");
        require(
            coupons[coupId].usage > uint(coupons[coupId].customerCount[address(msg.sender)]), "Coupon usage limit reached"
        );
    }

    /// @notice helper function to adjust the stock of a prod
    function adjustStock(uint256[] memory prodIds, uint256[] memory prodAmts) internal {
        for (uint256 i = 0; i < prodIds.length; i++) {
            uint256 id = prodIds[i];
            uint256 amt = prodAmts[i];
            products[id].stock -= amt;
        }
    }

    function _calculateTotalPrice(uint256[] memory prodIds, uint256[] memory prodAmts)
        internal
        view
        returns (uint256)
    {
        uint256 totalPrice;
        for (uint256 i = 0; i < prodIds.length; i++) {
            totalPrice += (products[prodIds[i]].price * prodAmts[i]);
        }
        return totalPrice;
    }

    /// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~merchant functions~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    /// @notice function for businesses to create products
    function createProduct(uint256 _prc, uint256 _stck, string calldata _name) public businessOnly {
        Product storage newProduct = products[newProdId];
        newProduct.price = _prc;
        newProduct.stock = _stck;
        newProduct.name = _name;
        newProdId++;
    }

    /// @notice function to adjust a products' stock
    function addStock(uint256 prodId, uint256 amt) public businessOnly {
        products[prodId].stock += amt;
    }

    /// @notice function for businesses to create coupons
    function createCoupon(
        uint256 _txnAmt,
        uint256 _ethAmt,
        bool _firstTime,
        uint256 _usageNum,
        uint256 _discountBp,
        uint256 _discountAmt
    ) public businessOnly {
        if (_discountAmt == 0 && _discountBp == 0) {
            revert InvalidCouponCreation();
        }
        Coupon storage newCoupon = coupons[newCoupId];
        newCoupon.minTxnAmt = _txnAmt;
        newCoupon.minEthAmt = _ethAmt;
        newCoupon.firstTimeOnly = _firstTime;
        newCoupon.usage = _usageNum;
        newCoupon.isActive = true;
        newCoupon.discountBp = _discountBp;
        newCoupon.discountAmt = _discountAmt;
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

            (bool success,) = business.call{value: remainder}("");
            require(success, "Transfer failed.");
            (bool feeSuccess,) = core.call{value: fee}("");
            require(feeSuccess, "Fee transfer failed.");
        } else {
            uint256 fee = IERC20(token).balanceOf(address(this)) / 100;
            uint256 remainder = IERC20(token).balanceOf(address(this)) - fee;

            IERC20(token).transferFrom(address(this), business, remainder);
            IERC20(token).transferFrom(address(this), core, fee);
        }
    }
}
