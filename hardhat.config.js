require('dotenv').config()
require('@nomiclabs/hardhat-waffle')
require('hardhat-deploy')

module.exports = {
  solidity: '0.8.6',
  settings: {
    optimizer: {
      enabled: true,
      runs: 200
    }
  },
  networks: {
    hardhat: {
      gas: 12000000,
      blockGasLimit: 0x1fffffffffffff,
      allowUnlimitedContractSize: true,
      chainId: 1337
    }
  },
  namedAccounts: {
    deployer : {
      hardhat : 0
    }
  }
}
