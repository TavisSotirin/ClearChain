//var User = artifacts.require("User");
//var Company = artifacts.require("Company");
var Transfer = artifacts.require("Transfer");

module.exports = function(deployer) {
  //deployer.deploy(User);
  //deployer.deploy(Company);
  deployer.deploy(Transfer);
};