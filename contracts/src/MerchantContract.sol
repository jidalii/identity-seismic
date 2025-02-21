// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "./IDProtocol.sol";
import "./IERC20.sol";
import {MockOracle} from "./MockOracle.sol";

contract MerchantContract {
    /// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~merchant data~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    /// @notice vars about the contract details
    address payable public business;
    string public name;
    address payable public core;
    address public oracle;
    address public ETH_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
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
    /// @param price price of the product
    /// @param stock stock of the product
    /// @param name name of the product
    struct Product {
        uint256 price;
        uint256 stock;
        string name;
    }

    /// @notice struct detailing the coupon
    /// @param minTxnAmt minimum transaction number on the platform
    /// @param minEthAmt minimum transaction amount in ETH
    /// @param firstTimeOnly if the coupon is for first time users only
    /// @param usage number of times the coupon can be used
    /// @param customerCount mapping of customer address to the number of times they have used the coupon
    /// @param discountBp discount in basis points
    /// @param discountAmt discount in amount
    /// @param isActive if the coupon is active
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

    /// @notice purchase function for ETH
    /// @param _address address to transfer to
    /// @param amount amount to transfer
    function transferETH(address _address, uint256 amount) private returns (bool) {
        require(_address != address(0), "Zero addresses are not allowed.");

        (bool os,) = payable(_address).call{value: amount}("");

        return os;
    }

    /// @notice function to get the product details
    function getProduct(uint256 id) public view returns (Product memory) {
        return products[id];
    }

    /// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~transaction functions~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    /// @notice ETH/native token specific transaction function
    /// @param prodIds array of product ids
    /// @param prodAmts array of product amounts
    /// @param coupId coupon id
    function purchaseETH(uint256[] memory prodIds, uint256[] memory prodAmts, uint256 coupId) external payable {
        _validatePurchase(prodIds, prodAmts, coupId);

        uint256 totalPrice = _calculateTotalPrice(prodIds, prodAmts);

        Coupon storage _coupon = coupons[coupId];

        uint256 finalPriceTk = _calculateDiscountedPrice(_coupon, totalPrice);

        // update coupon state
        uint256 newCnt = uint(_coupon.customerCount[address(msg.sender)]) +1;
        _coupon.customerCount[address(msg.sender)] = suint(newCnt);

        uint256 gap = msg.value - finalPriceTk;
        if (gap > 0) {
            require(transferETH(msg.sender, gap), "failed to refund");
        }

        _adjustStock(prodIds, prodAmts);

        IDProtocol(core).updateUserEntry(address(this), saddress(msg.sender), suint(msg.value));
    }

    /// @notice purchase for ERC20 tokens
    /// @param token address of the token
    /// @param prodIds array of product ids
    /// @param prodAmts array of product amounts
    function purchaseERC20(address token, uint256[] memory prodIds, uint256[] memory prodAmts, uint256 coupId)
        external
        payable
    {
        _validatePurchase(prodIds, prodAmts, coupId);
        // require(allowedTokens[token], "Token is not approved");

        uint256 totalPriceTk = _calculateTotalPrice(prodIds, prodAmts);
        Coupon storage _coupon = coupons[coupId];

        uint256 finalPriceTk = _calculateDiscountedPrice(_coupon, totalPriceTk);

        // update coupon state
        uint256 newCnt = uint(_coupon.customerCount[address(msg.sender)]) +1;
        _coupon.customerCount[address(msg.sender)] = suint(newCnt);

        uint256 priceRatio = MockOracle(oracle).calcRatio(token);
        finalPriceTk = finalPriceTk * 1 ether / priceRatio;

        IERC20(token).transferFrom(msg.sender, address(this), finalPriceTk);

        _adjustStock(prodIds, prodAmts);

        suint purchaseAmount = suint(finalPriceTk * priceRatio);
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

    /// @notice helper function to adjust the stock of a prod
    /// @param prodIds array of product ids
    /// @param prodAmts array of product amounts
    function _adjustStock(uint256[] memory prodIds, uint256[] memory prodAmts) internal {
        for (uint256 i = 0; i < prodIds.length; i++) {
            uint256 id = prodIds[i];
            uint256 amt = prodAmts[i];
            products[id].stock -= amt;
        }
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

    /// @notice function for business to collect revenue to their wallet
    /// @param _token address of the token
    /// @param _to address to transfer to
    function collectRevenue(address _token, address _to) external payable businessOnly {
        if (_token == ETH_ADDRESS) {
            uint256 fee = address(this).balance / 100;
            uint256 remainder = address(this).balance - fee;

            require(transferETH(payable(_to), remainder), "failed to collect revenue");
            require(transferETH(core, fee), "failed to transfer fee to core");
        } else {
            uint256 fee = IERC20(_token).balanceOf(address(this)) / 100;
            uint256 remainder = IERC20(_token).balanceOf(address(this)) - fee;

            IERC20(_token).transfer(business, remainder);
            IERC20(_token).transfer(core, fee);
        }
    }
}
