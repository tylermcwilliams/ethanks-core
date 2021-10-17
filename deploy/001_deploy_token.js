const func = async (hre) => {
    const { deployments, getNamedAccounts } = hre;
    const { deploy, log } = deployments;
    const { deployer } = await getNamedAccounts();

    const ethanksERC20 = await deploy('EThanksERC20', {
        from: deployer
    })

    if (ethanksERC20.newlyDeployed) {
        log(
            `EThanksERC20 deployed at ${ethanksERC20.address} using ${ethanksERC20.receipt?.gasUsed} gas`
        );
    }
}
module.exports = func;
func.tags = ['Tokens']