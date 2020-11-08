var SimpleStorage = artifacts.require("./SimpleStorage.sol");
var Blackjack = artifacts.require("./Blackjack.sol");

module.exports = function(deployer) {
  deployer.deploy(SimpleStorage);
  deployer.deploy(Blackjack);
};
