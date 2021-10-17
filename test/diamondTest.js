/* global describe it before ethers */

const {
    getSelectors,
    FacetCutAction,
    removeSelectors,
    findAddressPositionInFacets
} = require('../scripts/libraries/diamond.js')

const { assert } = require('chai')
const { BigNumber } = require('ethers');
const { deployments } = require('hardhat');
const { deployMocks } = require('../scripts/deploy.js');

const DAILY_BLOCKS = 5;
const HALF_LIFE = DAILY_BLOCKS * 30;
const MAX_REWARD = BigNumber.from(10).pow(18).mul(50000);
const BASE_REWARD = BigNumber.from(33);

describe('DiamondTest', async function () {
    let accounts

    let ethanksDiamond;
    let ethanksERC20;
    let campaignFacet;
    let busdERC20Mock;

    let tx;

    before(async function () {
        await deployments.fixture(['Tokens', 'Diamond'])

        accounts = await ethers.getSigners();
        const ethanksDiamondAddress = (await deployments.get("Diamond")).address;
        const ethanksERC20Address = (await deployments.get("EThanksERC20")).address;

        ethanksDiamond = await ethers.getContractAt("Diamond", ethanksDiamondAddress);
        ethanksERC20 = await ethers.getContractAt("EThanksERC20", ethanksERC20Address);
        campaignFacet = await ethers.getContractAt("CampaignFacet", ethanksDiamondAddress);

        ({busdERC20:busdERC20Mock} = await deployMocks());
    })

    it('should add half life paramaters', async () => {
        const _hl = HALF_LIFE;
        tx = await campaignFacet.addTnksEmissionParams(MAX_REWARD, BASE_REWARD, _hl);
        const totalParams = await campaignFacet.getTotalTnksEmissionParams();
        const { baseReward, hl } = await campaignFacet.getTnksEmissionParams(totalParams - 1);
        assert.equal(baseReward.toString(), BASE_REWARD.toString())
        assert.equal(hl.toString(), _hl.toString())
    })

    it('should add campaign', async () => {
        const paramsId = 0
        const duration = DAILY_BLOCKS * 365
        const receiver = accounts[1].address
        await campaignFacet.addHLCampaign(
            paramsId,
            busdERC20Mock.address,
            duration,
            receiver
        );
        const firstCampaign = await campaignFacet.getCampaign(0);
        const currentBlock = await ethers.provider.getBlockNumber();
        assert.equal(firstCampaign.campaignType, 0)
        assert.equal(firstCampaign.campaignTypeParams, paramsId)
        assert.equal(firstCampaign.receiver, receiver)
        assert.equal(firstCampaign.startBlock.toString(), currentBlock.toString())
        assert.equal(firstCampaign.blocksDuration.toString(), duration.toString())

    })

    it('should receive expected tnks', async () => {
        let donation = BigNumber.from(10).pow(18).mul(1000)

        await busdERC20Mock.increaseAllowance(ethanksDiamond.address, donation)
        await campaignFacet.donateToHalfLifeCampaign(0, donation)

        let tnksBal = await ethanksERC20.balanceOf(accounts[0].address)
        let expectedReward = await campaignFacet.getExpectedTnksReward(0, donation)
        assert.equal(tnksBal.toString(), expectedReward.toString())

        // FF campaign's hl worth of blocks
        const campaign = await campaignFacet.getCampaign(0)
        const ff = campaign.startBlock.add(HALF_LIFE);
        let blockNumber = await ethers.provider.getBlockNumber()
        while (ff.gt(blockNumber)) {
            await ethers.provider.send("evm_mine")
            blockNumber = await ethers.provider.getBlockNumber()
        }

        await busdERC20Mock.increaseAllowance(ethanksDiamond.address, donation)
        await campaignFacet.donateToHalfLifeCampaign(0, donation)

        tnksBal = (await ethanksERC20.balanceOf(accounts[0].address))
        expectedReward = await campaignFacet.getExpectedTnksReward(0, donation)
    })

    it("reverts if over max", async () => {
        try {
            await campaignFacet.donateToHalfLifeCampaign(0, MAX_REWARD);
        } catch (e) {
            reverted = true;
        }
        assert(reverted)
    })
})
