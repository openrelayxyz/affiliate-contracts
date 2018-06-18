var AffiliateFactory = artifacts.require("./AffiliateFactory.sol");
var Affiliate = artifacts.require("./Affiliate.sol");
var WETH9 = artifacts.require("./WETH9.sol");

contract('AffiliateFactory', function(accounts) {
  it("Allow an affiliate to sign up at an established stake", function() {
    var affiliateAddress;
    return WETH9.deployed().then(() => {
      return Affiliate.deployed();
    }).then(() => {
      return AffiliateFactory.new(Affiliate.address, WETH9.address, 20, 80);
    }).then((af) => {
      return af.signUp([accounts[2], accounts[3]], [1, 1], {from: accounts[0]})
    }).then((result) => {
      affiliateAddress = "0x" + result.receipt.logs[0].data.slice(26, 66);
      return web3.eth.sendTransaction({
        'from': accounts[0],
        'to': affiliateAddress,
        'value': web3.toWei(1, "ether"),
      });
    }).then((tx) => {
      return WETH9.at(WETH9.address).balanceOf(affiliateAddress)
    }).then((balance) => {
      assert.equal(balance.toString(), web3.toWei(1, "ether").toString());
      return Affiliate.at(affiliateAddress).payout([WETH9.address]);
    }).then(() => {
      return Promise.all([
        WETH9.at(WETH9.address).balanceOf(accounts[0]),
        WETH9.at(WETH9.address).balanceOf(accounts[2]),
        WETH9.at(WETH9.address).balanceOf(accounts[3]),
      ]);
    }).then((res) => {
      assert.equal(res[0].toString(), web3.toWei(.2, "ether").toString());
      assert.equal(res[1].toString(), web3.toWei(.4, "ether").toString());
      assert.equal(res[2].toString(), web3.toWei(.4, "ether").toString());
    });
  });
  it("Check whether an address is an affiliate.", function() {
    var affiliateAddress;
    return WETH9.deployed().then(() => {
      return Affiliate.deployed();
    }).then(() => {
      return AffiliateFactory.new(Affiliate.address, WETH9.address, 20, 80);
    }).then((af) => {
      return Promise.all([
        af.signUp([accounts[2], accounts[3]], [1, 1], {from: accounts[0]}),
        af.signUp([accounts[2], accounts[3]], [1, 1], {from: accounts[0]}),
        af.signUp([accounts[2], accounts[3]], [1, 1], {from: accounts[0]}),
      ])
    }).then((result) => {
      var affiliateAddress = "0x" + result[0].receipt.logs[0].data.slice(26, 66);
      var affiliate = Affiliate.at(affiliateAddress);
      return Promise.all([
        affiliate.isAffiliated.call("0x" + result[1].receipt.logs[0].data.slice(26, 66)),
        affiliate.isAffiliated.call("0x" + result[2].receipt.logs[0].data.slice(26, 66)),
        affiliate.isAffiliated.call(WETH9.address),
      ]);
    }).then((result) => {
      assert(result[0]);
      assert(result[1]);
      assert(!result[2]);
    });
  });
});
