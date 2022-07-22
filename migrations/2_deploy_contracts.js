const StarNotary = artifacts.require("StarNotary");

module.exports = function(deployer,network, accounts) {
  console.log(network, accounts)
  deployer.deploy(StarNotary, "Star Notary", "NTR",{from: accounts[0]});
};
