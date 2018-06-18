var Affiliate = artifacts.require("./Affiliate.sol");
var AffiliateFactory = artifacts.require("./AffiliateFactory.sol");
var WETH9 = artifacts.require("./WETH9.sol");

module.exports = async function(deployer, network, accounts) {
  deployer.then(async () => {
    await deployer.deploy(Affiliate);
    if(network == "mainnet") {
      wethAddress = "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2";
    } else {
      await deployer.deploy(WETH9);
      wethAddress = WETH9.address;
    }
    await deployer.deploy(AffiliateFactory, Affiliate.address, wethAddress, 20, 80);
  })
}
