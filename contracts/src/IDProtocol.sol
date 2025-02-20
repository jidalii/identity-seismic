// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "../../zkp/verifier/verifier.sol";

contract IDProtocol {
    address owner;
    Verifier public verif;
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
    address[] onchainIdAddresses;

    function updateScore(uint proof, Identity calldata newVals) public {
        verif.verifyProof(proof, newVals);
        onchainId[saddress(msg.sender)] = newVals;
    }

    function getScore() public view returns (Identity storage){
        return onchainId[saddress(msg.sender)];
    }

    function query(QueryReq memory query) public view returns (address[] memory) {
        // not sure about this
        // do we want ot iterate through and do all this stuff or is this just a one to one form the business POV
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

    // need to compute overall score? dunno
    // need to add extra onchain proof mechanisms
    // main functionality is to prove yo uare a human, not a bot and for a buiness to search for a targeted defografic
}