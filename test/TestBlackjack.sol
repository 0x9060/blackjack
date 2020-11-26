// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/Blackjack.sol";

/// @title Testing for Blackjack contract
/// @author Clark Henry
/// @notice This Blackjack contract has known security risks. Some tests in here are known to be failing to successfully isolate such security risks.
contract TestBlackjack {

    uint public initialBalance = 2 ether;
    Blackjack casino;
    UserAgent ploppy;
    UserAgent squatter;

    constructor() public payable {}

    // Run before each test
    function beforeAll() public {
        casino = new Blackjack();
        ploppy = new UserAgent(casino);
        squatter = new UserAgent(casino);

        address(ploppy).transfer(10000 wei);
    }

    //// payout Tests
    //function testHere() public {}
}




/// @notice Contract to create user to interact with Blackjack contract (i.e., a Casino visitor)
contract UserAgent {

    Blackjack thisCasino;

    constructor(Blackjack _casino) public payable {
        thisCasino = _casino;
    }

    fallback() external {}
    receive() external payable {}

    function kill() public returns(bool) {
        (bool success, ) = address(thisCasino).call(abi.encodeWithSignature("kill()"));
        return success;
    }

    function newRound(uint bet) public returns(bool) {
        (bool success, ) = address(thisCasino).call(abi.encodeWithSignature("newRound({value: uint256})", bet));
        return success;
    }

    function split(uint bet) public returns(bool) {
        (bool success, ) = address(thisCasino).call(abi.encodeWithSignature("split({value: uint256)", bet));
        return success;
    }

    function doubleDown(uint bet) public returns(bool) {
        (bool success, ) = address(thisCasino).call(abi.encodeWithSignature("doubleDown({value: uint256})", bet));
        return success;
    }

    function hit() public returns(bool) {
        (bool success, ) = address(thisCasino).call(abi.encodeWithSignature("hit()"));
        return success;
    }

    function stand() public returns(bool) {
        (bool success, ) = address(thisCasino).call(abi.encodeWithSignature("stand()"));
        return success;
    }

    /// @dev need to fix this return
    //function getDealerHand() public returns(bool) {}

    /// @dev need to fix this return
    //function getPlayerHand() public returns(bool) {}

    /// @dev need to fix this return
    //function getGameState() public returns(bool) {}
}
