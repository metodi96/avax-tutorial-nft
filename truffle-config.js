const HDWalletProvider = require('@truffle/hdwallet-provider')
require('dotenv').config()
module.exports = {
  networks: {
    fuji: {
      provider: () => {
        return new HDWalletProvider({
          mnemonic: process.env.MNEMONIC,
          providerOrUrl: `https://avalanche--fuji--rpc.datahub.figment.io/apikey/${process.env.APIKEY}/ext/bc/C/rpc`,
          chainId: "0xa869"
        })
      },
      network_id: "*",
      gas: 6000000,
      gasPrice: 225000000000
    }
  },
  compilers: {
    solc: {
      version: "0.8.6"
    }
  },
};