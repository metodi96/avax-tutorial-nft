const HDWalletProvider = require('@truffle/hdwallet-provider')
require('dotenv').config()
module.exports = {
  networks: {
    fuji: {
      provider: () => {
        return new HDWalletProvider(process.env.MNEMONIC, 'https://api.avax-test.network/ext/bc/C/rpc')
      },
      network_id: "*",
      gas: 3000000,
      gasPrice: 225000000000
    }
  },
  compilers: {
    solc: {
      version: "0.8.6"
    }
  },
};