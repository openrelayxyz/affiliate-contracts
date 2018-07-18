var HDWalletProvider = require("truffle-hdwallet-provider");
var infura_apikey = "atjfYkLXBNdLI0zSm9eE ";
var mnemonic = "note stuff tobacco scheme blade forest sell green glide wild cereal mask chair dance motor tape atom viable mistake autumn night distance matrix high";


module.exports = {
  networks: {
    development: {
      host: "localhost",
      port: 7545,
      network_id: "*" // Match any network id
    },
    kovan: {
      provider: new HDWalletProvider(mnemonic, "https://kovan.infura.io/"+infura_apikey),
      network_id: 3,
      gas: 4000000,
      gasPrice: 1000000000
    },

    testrpc: {
      host: "localhost",
      port: 18545,
      network_id: "50"
    }
  }
};
