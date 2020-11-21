// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/Blackjack.sol";

/// @title Testing for Blackjack contract
/// @author Clark Henry
/// @notice This Blackjack contract has known security risks. Some tests in here are known to be failing to successfully isolate such security risks.
contract TestBlackjack {

    /// @notice Placeholder
    /// @dev Placeholder
    function testNothing() public {
        Assert.equal(uint(0), uint(0), "It should equal");
    }

}
