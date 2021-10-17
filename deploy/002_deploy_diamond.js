const func = async (hre) => {
    const { deployments, getNamedAccounts } = hre;
    const { log, diamond } = deployments;
    const { deployer } = await getNamedAccounts();

    const FacetNames = [
        "DiamondInit",
        "CampaignFacet"
    ]

    const ethanksDiamond = await diamond.deploy('Diamond', {
        from: deployer,
        owner: deployer,
        facets: FacetNames
    });

    if (ethanksDiamond.newlyDeployed) {
        log(
            `EThanksDiamond deployed at ${ethanksDiamond.address} using ${ethanksDiamond.receipt?.gasUsed} gas`
        );
    }

    const ethanksERC20Deployement = await deployments.get("EThanksERC20");
    const ethanksERC20 = await ethers.getContractAt("EThanksERC20", ethanksERC20Deployement.address);
    const diamondInit = await ethers.getContractAt("DiamondInit", ethanksDiamond.address);

    await ethanksERC20.transferOwnership(ethanksDiamond.address, {
        from: deployer
    });
    await diamondInit.init([ethanksERC20.address]);
}
module.exports = func;
func.tags = ['Diamond']