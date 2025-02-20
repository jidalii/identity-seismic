// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

/// @title A contract representing a pricing oracle for ERC20
contract MockOracle {
    /// @notice the oracle mapping (token address => value per ETH)
    mapping(address => uint) oracle;
    
    /**
     * @dev the constructor that hard codes oracle vals for tokens
     * This is purely for demonstration purposes
     */
    constructor(){
        oracle[address(1)] = 5;
        oracle[address(2)] = 1/2;
        oracle[address(3)] = 2;
    }

    /**
     * @notice the function merchants will call to determine the value in ETH of the token
     * @param address tokenAddr: address of the token being queried
     * @return uint the value in ETH of a single unit of the token
     */
    function calcRatio(address tokenAddr) external returns(uint){
        return oracle[tokenAddr];
    }
    
}