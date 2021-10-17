/* global describe it before ethers */

const {
    getSelectors,
    FacetCutAction,
    removeSelectors,
    findAddressPositionInFacets
} = require('../scripts/libraries/diamond.js')

const { deployDiamond } = require('../scripts/deploy.js')

const { assert } = require('chai')
const { BigNumber } = require('ethers')

const DAILY_BLOCKS = 5;
const HALF_LIFE = DAILY_BLOCKS * 30;
const MAX_REWARD = BigNumber.from(10).pow(18).mul(50000);
const BASE_REWARD = BigNumber.from(33);

describe('DiamondTest', async function () {
    let accounts
    let ethanksERC20Address
    let busdERC20Address
    let diamondAddress
    let diamondCutFacet
    let diamondLoupeFacet
    let ownershipFacet
    let tx
    let receipt
    let result
    const addresses = []

    before(async function () {
        accounts = await ethers.getSigners();
        ({ diamondAddress, ethanksERC20Address, busdERC20Address } = await deployDiamond())
        // = await ethers.getContractAt('EThanksERC20', ethanksERC20Address)
        diamondCutFacet = await ethers.getContractAt('DiamondCutFacet', diamondAddress)
        diamondLoupeFacet = await ethers.getContractAt('DiamondLoupeFacet', diamondAddress)
        ownershipFacet = await ethers.getContractAt('OwnershipFacet', diamondAddress)
    })

    it('should have three facets -- call to facetAddresses function', async () => {
        for (const address of await diamondLoupeFacet.facetAddresses()) {
            addresses.push(address)
        }

        assert.equal(addresses.length, 3)
    })

    it('facets should have the right function selectors -- call to facetFunctionSelectors function', async () => {
        let selectors = getSelectors(diamondCutFacet)
        result = await diamondLoupeFacet.facetFunctionSelectors(addresses[0])
        assert.sameMembers(result, selectors)
        selectors = getSelectors(diamondLoupeFacet)
        result = await diamondLoupeFacet.facetFunctionSelectors(addresses[1])
        assert.sameMembers(result, selectors)
        selectors = getSelectors(ownershipFacet)
        result = await diamondLoupeFacet.facetFunctionSelectors(addresses[2])
        assert.sameMembers(result, selectors)
    })

    it('selectors should be associated to facets correctly -- multiple calls to facetAddress function', async () => {
        assert.equal(
            addresses[0],
            await diamondLoupeFacet.facetAddress('0x1f931c1c')
        )
        assert.equal(
            addresses[1],
            await diamondLoupeFacet.facetAddress('0xcdffacc6')
        )
        assert.equal(
            addresses[1],
            await diamondLoupeFacet.facetAddress('0x01ffc9a7')
        )
        assert.equal(
            addresses[2],
            await diamondLoupeFacet.facetAddress('0xf2fde38b')
        )
    })

    it('should add campaign functions', async () => {
        const CampaignFacet = await ethers.getContractFactory('CampaignFacet')
        const campaignFacet = await CampaignFacet.deploy()
        await campaignFacet.deployed()
        addresses.push(campaignFacet.address)
        const selectors = getSelectors(campaignFacet)
        tx = await diamondCutFacet.diamondCut(
            [{
                facetAddress: campaignFacet.address,
                action: FacetCutAction.Add,
                functionSelectors: selectors
            }],
            ethers.constants.AddressZero, '0x', { gasLimit: 800000 })
        receipt = await tx.wait()
        if (!receipt.status) {
            throw Error(`Diamond upgrade failed: ${tx.hash}`)
        }
        result = await diamondLoupeFacet.facetFunctionSelectors(campaignFacet.address)
        assert.sameMembers(result, selectors)
    })

    it('should add half life paramaters', async () => {
        const campaignFacet = await ethers.getContractAt('CampaignFacet', diamondAddress)
        const _hl = HALF_LIFE;
        tx = await campaignFacet.addTnksEmissionParams(MAX_REWARD, BASE_REWARD, _hl);
        const totalParams = await campaignFacet.getTotalTnksEmissionParams();
        const { baseReward, hl } = await campaignFacet.getTnksEmissionParams(totalParams - 1);
        assert.equal(baseReward.toString(), BASE_REWARD.toString())
        assert.equal(hl.toString(), _hl.toString())
    })

    it('should add campaign', async () => {
        const campaignFacet = await ethers.getContractAt('CampaignFacet', diamondAddress)
        const paramsId = 0
        const duration = DAILY_BLOCKS * 365
        const receiver = accounts[1].address
        await campaignFacet.addHLCampaign(
            paramsId,
            busdERC20Address,
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
        const campaignFacet = await ethers.getContractAt('CampaignFacet', diamondAddress)
        const ethanks = await ethers.getContractAt('ERC20Token', ethanksERC20Address)
        const busd = await ethers.getContractAt('ERC20Token', busdERC20Address)
        let donation = BigNumber.from(10).pow(18).mul(1000)

        await busd.increaseAllowance(diamondAddress, donation)
        await campaignFacet.donateToHalfLifeCampaign(0, donation)

        let tnksBal = await ethanks.balanceOf(accounts[0].address)
        let expectedReward = await campaignFacet.getExpectedTnksReward(0, donation)
        assert.equal(tnksBal.toString(), expectedReward.toString())

        // FF campaign's hl worth of blocks
        const campaign = await campaignFacet.getCampaign(0)
        const ff = campaign.startBlock.add(HALF_LIFE);
        let blockNumber = await ethers.provider.getBlockNumber()
        while(ff.gt(blockNumber)) {
            await ethers.provider.send("evm_mine")
            blockNumber = await ethers.provider.getBlockNumber()
        }

        await busd.increaseAllowance(diamondAddress, donation)
        await campaignFacet.donateToHalfLifeCampaign(0, donation)

        tnksBal = (await ethanks.balanceOf(accounts[0].address))
        expectedReward = await campaignFacet.getExpectedTnksReward(0, donation)
    })

    it("reverts if over max",async ()=>{
        const campaignFacet = await ethers.getContractAt('CampaignFacet', diamondAddress)
        try {
            await campaignFacet.donateToHalfLifeCampaign(0, MAX_REWARD);
        } catch(e) {
            reverted = true;
        }
        assert(reverted)
    })
})
