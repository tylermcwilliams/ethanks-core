const { BigNumber } = require("ethers")

async function deployMocks() {
  // deploy Busd mock token
  const accounts = await ethers.getSigners()
  const BusdERC20 = await ethers.getContractFactory('ERC20Token')
  const busdERC20 = await BusdERC20.deploy()
  await busdERC20.deployed()
  console.log('BUSD Mock deployed:', busdERC20.address)
  return {
    busdERC20
  }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
if (require.main === module) {
  deployDiamond()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error)
      process.exit(1)
    })
}

exports.deployMocks = deployMocks
