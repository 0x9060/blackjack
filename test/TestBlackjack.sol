// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/Blackjack.sol";

contract TestBlackjack {

  function testNothing() public {
      Assert.equal(uint(0), uint(0), "It should equal");
  }

}
