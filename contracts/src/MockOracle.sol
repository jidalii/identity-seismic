// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

/// @title A contract representing a pricing oracle for ERC20
contract MockOracle {
    /// @notice the oracle mapping (token address => value per ETH)
    mapping(address => uint256) oracle;

    /**
     * @dev the constructor that hard codes oracle vals for tokens
     * This is purely for demonstration purposes
     */
    constructor() {
        oracle[address(1)] = 1 ether / 2000; // USDC
        oracle[address(2)] = 0.5 ether; // SEI
        oracle[address(3)] = 1 ether; // WETH
        oracle[address(0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f)] = 1 ether/ 2000; // USDT
    }

    /// @notice the function merchants will call to determine the value in ETH of the token
    function calcRatio(address tokenAddr) external view returns (uint256) {
        return oracle[tokenAddr];
    }
}
