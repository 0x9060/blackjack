var Blackjack = artifacts.require("./Blackjack.sol");

module.exports = function(deployer) {
  deployer.deploy(Blackjack);
};
