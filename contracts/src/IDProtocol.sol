// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;


contract IDProtocal {
    address owner;
    constructor() {
        owner = msg.sender;
    }

    struct Identity {
        sbool isGithub;
        suint githubStar;
        sbool isTwitter;
        suint twitterFollower;
        suint totalStaked;
        suint balance;
        suint txnFrequency;
        int lastUpdated;
    }

    struct UpdateScoreReq {
        saddress owner;
        sbool isGithub;
        suint githubStar;
        sbool isTwitter;
        suint twitterFollower;
        suint totalStaked;
        suint balance;
        suint txnFrequency;
        int lastUpdated;
    }

    struct QueryReq {
        suint minGithubStar;
        suint minTwitterFollower;
        suint minTotalStaked;
        suint minBalance;
        suint minTxnFrequency;
    }
    
    mapping(saddress => Identity) onchainId; 
    address[] onchainIdAddress;

    function updateScore(uint proof, Identity memory newVals) public {
        onchainId[saddress(msg.sender)] = newVals;
    }

    function getScore(saddress idAddr) public view returns (Identity memory){
        return onchainId[idAddr];
    }

    function query(QueryReq memory query) public view returns (address[] memory) {
        // not sure about this
    }

    function isMatched(QueryReq memory query, address addr) public view returns (bool) {
        if (onchainId[saddress(addr)].githubStar < query.minGithubStar) {
            return false;
        } else if (onchainId[saddress(addr)].twitterFollower < query.minTwitterFollower){
            return false;
        } else if (onchainId[saddress(addr)].totalStaked < query.minTotalStaked){
            return false;
        } else if (onchainId[saddress(addr)].balance < query.minBalance){
            return false;
        } else if (onchainId[saddress(addr)].txnFrequency < query.minTxnFrequency){
            return false;
        }
        return true;
    }
}