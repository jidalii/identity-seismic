// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

contract MockOracle {
    mapping(address => uint) oracle; // token address -> value:1ETH ratio
    constructor(){
        oracle[address(1)] = 5;
        oracle[address(2)] = 10;
        oracle[address(3)] = 2;
    }

    function calcRatio(address tokenAddr) external returns(uint){
        return oracle[tokenAddr];
    }
    
}