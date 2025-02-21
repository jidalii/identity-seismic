// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "./IERC20.sol";

import "./Verifier.sol";
import "./MerchantContract.sol";
import "./MockOracle.sol";

import "forge-std/console.sol";


contract IDProtocol {
    //*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*//
    //*                           USERS                            *//
    //*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*//

    struct UserData {
        suint256 totalPurchase;
        suint256 numPurchase;
        sbool isFirstTime; // false if first time, true if not
    }

    struct UserDataPub {
        uint256 totalPurchase;
        uint256 numPurchase;
        bool isFirstTime; // false if first time, true if not
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
        string name;
    }

    struct MerchantRegistReq {
        address owner;
        string name;
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
    }
    // Identity identity;

    struct QueryReq {
        suint minGithubStar;
        suint minTwitterFollower;
        suint minTotalStaked;
        suint minBalance;
        suint minTxnFrequency;
    }

    event ProtocolDeployed(address owner, address verif, address oracle);
    event MerchantRegistered(address merchant, address owner, string name);
    event VaultWithdrawn(address token, address to, uint256 amount);

    address public constant ETH_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    address public owner;

    Verifier public verif;
    MockOracle public oracle;

    saddress[] private users;
    mapping(saddress => bool) private isUser;

    address[] public merchants;
    mapping(address => MerchantData) public merchantData;

    mapping(address => UserEntry) customerData;

    mapping(address => Identity) onchainId;
    saddress[] onchainIdAddresses;

    constructor() {
        owner = msg.sender;
        verif = new Verifier();
        oracle = new MockOracle();
        emit ProtocolDeployed(owner, address(verif), address(oracle));
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this.");
        _;
    }

    receive() external payable {}

    //*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*//
    //*                         ADMIN-ONLY                         *//
    //*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*//

    function withdraw(address _token, address _to) external onlyOwner {
        if (_token == ETH_ADDRESS) {
            require(transferETH(_to, address(this).balance), "failed to withdraw ETH");
        } else {
            IERC20(_token).transfer(_to, IERC20(_token).balanceOf(address(this)));
        }
        emit VaultWithdrawn(_token, _to, address(this).balance);
    }

    function transferETH(address _address, uint256 amount) private returns (bool) {
        require(_address != address(0), "Zero addresses are not allowed.");

        (bool os,) = payable(_address).call{value: amount}("");

        return os;
    }

    //*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*//
    //*                      IDENTITY-RELATED                      *//
    //*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*//

    function updateScore(uint256[8] calldata _proof, uint256[1] calldata _pubWitness, OffchainIdentity calldata newVals)
        public
        view
    {
        verif.verifyProof(_proof, _pubWitness);
        Identity memory _userIdentity = onchainId[msg.sender];
        // _userIdentity.offchain = newVals;
    }

    function getIdentity() public view returns (Identity memory) {
        return onchainId[msg.sender];
    }

    function query(QueryReq memory _query) external view returns (address[] memory) {
        // not sure about this
        // do we want ot iterate through and do all this stuff or is this just a one to one form the business POV
        uint256 matchedCnt = 0;
        for (uint256 i = 0; i < uint256(onchainIdAddresses.length); i++) {
            if (isMatched(_query, address(onchainIdAddresses[suint(i)]))) {
                matchedCnt++;
            }
        }
        address[] memory matchedUsers = new address[](matchedCnt);

        for (uint256 i = 0; i < uint256(onchainIdAddresses.length); i++) {
            if (isMatched(_query, address(onchainIdAddresses[suint(i)]))) {
                matchedUsers[i] = address(onchainIdAddresses[suint(i)]);
            }
        }
        return matchedUsers;
    }

    function isMatched(QueryReq memory _query, address addr) public view returns (bool) {
        if (onchainId[addr].offchain.githubStar < _query.minGithubStar) {
            return false;
        } else if (onchainId[addr].offchain.twitterFollower < _query.minTwitterFollower) {
            return false;
        } else if (onchainId[addr].onchain.totalStaked < _query.minTotalStaked) {
            return false;
        } else if (suint(address(addr).balance) < _query.minBalance) {
            return false;
        } else if (onchainId[addr].onchain.txnFrequency < _query.minTxnFrequency) {
            return false;
        }
        return true;
    }

    //*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*//
    //*                      MERCHANT-RELATED                      *//
    //*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*//

    function register(MerchantRegistReq calldata _req) external returns (address) {
        _validateRegiester(_req);

        MerchantContract newMerchant = new MerchantContract(_req.owner, _req.name, address(oracle));
        merchants.push(address(newMerchant));
        merchantData[address(newMerchant)] = MerchantData(address(newMerchant), _req.owner, _req.name);

        emit MerchantRegistered(address(newMerchant), _req.owner, _req.name);
        return address(newMerchant);
    }

    function updateUserEntry(address _merchant, saddress user, suint256 purchaseAmount) external {

        UserEntry storage _customerData = customerData[_merchant];

        UserData storage _userData = _customerData.data[user];
        if (!bool(_userData.isFirstTime)) {
            _customerData.users.push(saddress(user));
            _userData.isFirstTime = sbool(true);
        }
        _userData.totalPurchase += purchaseAmount;
        _userData.numPurchase += suint256(1);
        console.log("updateUserEntry", uint(_userData.totalPurchase));
        console.log("updateUserEntry", uint(_userData.numPurchase));
    }

    function getUserEntry(address _merchant, saddress user) external view returns (UserDataPub memory) {
        UserData memory _data = customerData[_merchant].data[user];
        return UserDataPub(uint256(_data.totalPurchase), uint256(_data.numPurchase), bool(_data.isFirstTime));
    }

    function checkValidCouponApply(address user, uint256 _minTxnNum, uint256 _minEThAmt, bool _firstTimeOnly)
        external
        view
        returns (bool)
    {
        UserEntry storage _entry = customerData[msg.sender];
        UserData memory _data = _entry.data[saddress(user)];
        if (_minTxnNum != 0 && _minTxnNum > uint256(_data.numPurchase)) {
            // console.log("1");
            return false;
        }
        if (_minEThAmt != 0 && _minEThAmt > uint256(_data.totalPurchase)) {
            // console.log("2");
            // console.log("minEThAmt: ", _minEThAmt);
            // console.log("totalPurchase: ", uint256(_data.totalPurchase));
            return false;
        }
        if (_firstTimeOnly && bool(_data.isFirstTime)) {
            // console.log("3");
            // console.log(_firstTimeOnly);
            // console.log(bool(_data.isFirstTime));
            return false;
        }
        return true;
    }

    function _validateRegiester(MerchantRegistReq calldata _req) internal pure {
        require(_req.owner != address(0), "Zero address");
        require(bytes(_req.name).length > 0, "Empty name");
    }

    // need to compute overall score? dunno
    // need to add extra onchain proof mechanisms
    // main functionality is to prove yo uare a human, not a bot and for a buiness to search for a targeted defografic
}
