// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import "../../zkp/verifier/verifier.sol";
import "./MerchantContract.sol";

// contract Merchant {
//     address public owner;
//     string public name;
//     address public core;
//     constructor(address companyAddress, string memory companyName, address coreAddress) {
//         owner = companyAddress;
//         name = companyName;
//         core = coreAddress;
//     }
// }

interface IIDPRotocol {

    //*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*//
    //*                           USERS                            *//
    //*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*//

    struct UserData {
        suint256 totalPurchase;
        suint256 numPurchase;
        sbool isFirstTime; // false if first time, true if not
    }

    struct UserEntry {
        saddress[] users;
        mapping(saddress => UserData) data;
    }

    struct CustomerDataUpdateReq {
        saddress user;
        suint256 purchaseAmount;
    }

    //*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*//
    //*                          MERCHANTs                         *//
    //*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*//

    /// @dev Merchant data
    /// @param merchant address of the merchant's smart contract
    /// @param owner address of the merchant's owner
    /// @param name name of the merchant
    struct MerchantData {
        address merchant;
        address owner;
        string  name;
    }

    struct MerchantRegistReq {
        address owner;
        string  name;
    }

    //*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*//
    //*                          IDENTITY                          *//
    //*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*//

    struct Identity {
        OffchainIdentity offchain;
        OnchainIdentity onchain;
    }
    struct OffchainIdentity {
        sbool isGithub;
        suint githubStar;
        sbool isTwitter;
        suint twitterFollower;
    }

    struct OnchainIdentity {
        suint totalStaked;
        suint txnFrequency;
        // Identity identity;
    }

    struct QueryReq {
        suint minGithubStar;
        suint minTwitterFollower;
        suint minTotalStaked;
        suint minBalance;
        suint minTxnFrequency;
    }


    event MerchantRegistered(address merchant, address owner, string name);
}

contract IDProtocol is IIDPRotocol{
    address owner;

    Verifier public verif;

    saddress[] private users;
    mapping(saddress => bool) private isUser;

    address[] public merchants;
    mapping(address => MerchantData) public merchantData;

    mapping(address => UserEntry) customerData;

    mapping(saddress => Identity) onchainId; 
    saddress[] onchainIdAddresses;

    constructor() {
        owner = msg.sender;
    }

    function updateScore(uint256[8] calldata _proof, uint256[1] calldata _pubWitness, Identity calldata newVals) public {
        verif.verifyProof(_proof, _pubWitness);
        onchainId[saddress(msg.sender)] = newVals;
    }

    function getIdentity() public view returns (Identity memory){
        return onchainId[saddress(msg.sender)];
    }

    function query(QueryReq memory _query) external view returns (address[] memory) {
        // not sure about this
        // do we want ot iterate through and do all this stuff or is this just a one to one form the business POV
        uint matchedCnt = 0;
        for(uint i=0; i<uint(onchainIdAddresses.length); i++) {
            if(isMatched(_query, address(onchainIdAddresses[suint(i)]))) {
                matchedCnt++;
                matchedUsers.push(address(onchainIdAddresses[suint(i)]));
            }
        }
        address[] memory matchedUsers = new address[](matchedCnt);

        for(uint i=0; i<uint(onchainIdAddresses.length); i++) {
            if(isMatched(_query, address(onchainIdAddresses[suint(i)]))) {
                matchedUsers[i] = address(onchainIdAddresses[suint(i)]);
            }
        }


    }

    function isMatched(QueryReq memory _query, address addr) public view returns (bool) {
        if (onchainId[saddress(addr)].onchain.githubStar < _query.minGithubStar) {
            return false;
        } else if (onchainId[saddress(addr)].onchain.twitterFollower < _query.minTwitterFollower){
            return false;
        } else if (onchainId[saddress(addr)].offchain.totalStaked < _query.minTotalStaked){
            return false;
        } else if (address(addr).balance < _query.minBalance){
            return false;
        } else if (onchainId[saddress(addr)].offchain.txnFrequency < _query.minTxnFrequency){
            return false;
        }
        return true;
    }

    function updateUserEntry(address _merchant, CustomerDataUpdateReq calldata _req) external {
        require(msg.sender == _merchant, "Only the merchant can update their own data");

        UserEntry storage _customerData = customerData[_merchant];

        saddress ssender = saddress(msg.sender);
        if(!_customerData.data[ssender].isFirstTime) {
            _customerData.users.push((ssender));
            _customerData.data[ssender].isFirstTime = sbool(true);
        }
        _customerData.data[ssender].totalPurchase += _req.purchaseAmount;
        _customerData.data[ssender].numPurchase += suint256(1);
    }

    function register(MerchantRegistReq calldata _req) external {
        _validateRegiester(_req);

        Merchant newMerchant = new Merchant(_req.owner, _req.name);
        merchants.push(address(newMerchant));
        merchantData[address(newMerchant)] = MerchantData(address(newMerchant), _req.owner, _req.name);

        emit MerchantRegistered(address(newMerchant), _req.owner, _req.name);
    }

    function _validateRegiester(MerchantRegistReq calldata _req) internal {
        require(_req.owner != address(0), "Zero address");
        require(bytes(_req.name).length > 0, "Empty name");
    }

    // need to compute overall score? dunno
    // need to add extra onchain proof mechanisms
    // main functionality is to prove yo uare a human, not a bot and for a buiness to search for a targeted defografic


}