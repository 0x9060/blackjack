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

        address(ploppy).transfer(1 ether);
    }

    /// newRound Tests
    
    // test for hand length
    function testNewRoundDealerHasOneCard() public {
	bool r = ploppy.newRound(100 wei);
        Assert.equal(uint(1), uint(0), "Dealer must be showing only one card");
    }

    function testNewRoundPlayerHasTwoCards() public {}


    /// doubleDown Tests

    // test for required bet
    function testCannotDoubleForMoreThanTwiceBet() public {}
    /// @dev this is a known bug
    function testCanDoubleForExactlyTwiceBet() public {}
    // test for double after hit
    function testCannotDoubleAfterHit() public {
	ploppy.newRound(100 wei);
	bool r = ploppy.doubleDown(100 wei);
	Assert.isTrue(r, "Can only double down before hitting");
    }


    /// hit Tests

    // test for hand length
    function testOneHitPlayerHasThreeCards() public {}

    // test for busting
    function testTwentyHitsWillBust() public {}

    /// stand Tests

    // test for hand length
    function testStandingDoesNotChangeHand() public {}

    // payout Tests
    function testCasinoPaysOutIfItShould() public {} // should make this draw ~10 games or so and test results

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
        (bool success, ) = address(thisCasino).call.value(bet)(abi.encodeWithSignature("newRound()"));
        return success;
    }

    function split(uint bet) public returns(bool) {
        (bool success, ) = address(thisCasino).call.value(bet)(abi.encodeWithSignature("split()"));
        return success;
    }

    function doubleDown(uint bet) public returns(bool) {
        (bool success, ) = address(thisCasino).call.value(bet)(abi.encodeWithSignature("doubleDown()"));
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
