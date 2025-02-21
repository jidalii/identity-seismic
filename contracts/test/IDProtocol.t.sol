// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import {CheatCodes} from "./ICheatCodes.sol";
import {IDProtocol} from "src/IDProtocol.sol";
import "src/Verifier.sol";

contract IDProtocolTest is Test {
    IDProtocol idProtocol;
    Verifier verifier;

    CheatCodes cheats = CheatCodes(VM_ADDRESS);

    address admin = address(10);
    address user1 = address(11);

    function setUp() public {
        vm.prank(admin);
        idProtocol = new IDProtocol();
        verifier = new Verifier();
    }

    IDProtocol.OffchainIdentity offchain = IDProtocol.OffchainIdentity({
            isGithub: sbool(true),
            githubStar: suint256(100),
            isTwitter: sbool(true),
            twitterFollower: suint256(100)
        });

    function test_buyToLaunchAmount() public {
        
        uint256[8] memory _proof = [7174833846330387795879905970947600072230443019161272173875958569396769374141, 17691209926964014382418187475873999120248666472476633055905313619609239265514, 2559568753358264708172447282783315516644148514162326396943670442346286653709, 17564222130962640796723273497394040076492227481512572694691488260751416880302, 13669109036873555193242407920107540681939514426694872474510968784747284172917, 9237226868027634176430801476494023810339223589714075002837314086847375531346, 2867401502017613396966649214859587244642494978736455531677970046741191669281, 17309473987180656666037763738069565977840130241893522131028592155241405988434];

        uint256[1] memory _input = [10624559006614969701095799278629976333869975720004091204341003304204069647740];

        verifier.verifyProof(_proof, _input);

        // vm.prank(user1);
        // idProtocol.updateScore(_proof, _input, offchain);
    }
}
