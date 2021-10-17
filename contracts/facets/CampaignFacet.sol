// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import {AppStorage, Campaign, CampaignType, TokenEmissionParams} from "../libraries/LibAppStorage.sol";
import {LibTnksCampaigns} from "../libraries/LibTnksCampaigns.sol";
import {LibERC20} from "../libraries/LibERC20.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";

import {EThanksERC20} from "../EThanksERC20.sol";

contract CampaignFacet {
    AppStorage internal s;

    event Donation(
        address donator,
        uint256 campaignId,
        address token,
        uint256 donated,
        uint256 reward
    );
    event NewCampaign(uint256 campaignId, Campaign campaign);
    event ChangedCampaignDuration(
        uint256 campaignId,
        uint256 previousBlockDuration
    );
    event NewTypeParams(CampaignType campaignType, uint8 paramsId);

    //event EditTypeParams(CampaignType campaignType, uint8 paramsId);

    function getExpectedTnksReward(uint256 _campaignId, uint256 _amount)
        external
        view
        returns (uint256)
    {
        return LibTnksCampaigns.getExpectedTnksReward(_campaignId, _amount);
    }

    function getTotalMintedTnks(uint256 _campaignId)
        external
        view
        returns (uint256)
    {
        return s.totalMinted[_campaignId];
    }

    function getTotalTnksEmissionParams() external view returns (uint8) {
        return s.totalTokenEmissionParams;
    }

    function getTnksEmissionParams(uint8 _paramsId)
        external
        view
        returns (TokenEmissionParams memory params_)
    {
        params_.maxReward = s.tokenEmissionParams[_paramsId].maxReward;
        params_.baseReward = s.tokenEmissionParams[_paramsId].baseReward;
        params_.hl = s.tokenEmissionParams[_paramsId].hl;
    }

    function addTnksEmissionParams(
        uint256 _maxReward,
        uint256 _baseReward,
        uint256 _hl
    ) external {
        LibDiamond.enforceIsContractOwner();
        s.tokenEmissionParams[s.totalTokenEmissionParams] = TokenEmissionParams(
            _maxReward,
            _baseReward,
            _hl
        );
        s.totalTokenEmissionParams++;

        emit NewTypeParams(
            CampaignType.HALF_LIFE,
            s.totalTokenEmissionParams - 1
        );
    }

    function addHLCampaign(
        uint8 _halfLifeParams,
        address _acceptedToken,
        uint256 _blocksDuration,
        address _receiver
    ) external {
        LibDiamond.enforceIsContractOwner();
        Campaign memory campaign = Campaign(
            CampaignType.HALF_LIFE,
            _halfLifeParams,
            _receiver,
            _acceptedToken,
            block.number,
            _blocksDuration
        );
        LibTnksCampaigns.addCampaign(campaign);

        emit NewCampaign(s.totalCampaigns - 1, campaign);
    }

    function getTnksAddress() external view returns (address) {
        return s.tnksContract;
    }

    function getCampaign(uint256 _campaign)
        external
        view
        returns (Campaign memory)
    {
        return s.campaigns[_campaign];
    }

    // function _editCampaign(uint256 _campaignId, Campaign memory _newData) internal {
    //     Campaign memory oldData = s.campaigns[_campaignId];
    //     s.campaigns[_campaignId] = _newData;

    //     emit EditedCampaign(oldData, _newData);
    // }

    // function _addCampaign(Campaign memory _campaign) internal {
    //     LibDiamond.enforceIsContractOwner();
    //     require(
    //         _campaign.receiver != address(0),
    //         "CAMPAIGN: receiver can't be 0 address"
    //     );
    //     s.campaigns[s.totalCampaigns] = _campaign;
    //     s.totalCampaigns++;

    //     emit NewCampaign(s.totalCampaigns - 1, _campaign);
    // }

    function changeCampaignDuration(
        uint256 _campaignId,
        uint256 _newBlocksDuration
    ) external {
        LibDiamond.enforceIsContractOwner();
        s.campaigns[_campaignId].blocksDuration = _newBlocksDuration;
        emit ChangedCampaignDuration(_campaignId, _newBlocksDuration);
    }

    function donateToHalfLifeCampaign(uint256 _campaignId, uint256 _amount)
        external
    {
        Campaign memory campaign = s.campaigns[_campaignId];
        require(_amount > 0, "CAMPAIGN: Donation can't be 0");
        require(
            s.totalCampaigns > _campaignId,
            "CAMPAIGN: Invalid campaign id"
        );
        require(
            campaign.campaignType == CampaignType.HALF_LIFE,
            "CAMPAIGN: Wrong donation method"
        );
        uint256 maxReward = s
            .tokenEmissionParams[campaign.campaignTypeParams]
            .maxReward;
        uint256 reward = LibTnksCampaigns.getExpectedTnksReward(_campaignId, _amount);
        require(
            maxReward >= s.totalMinted[_campaignId] + reward,
            "CAMPAIGN: Over the possible reward"
        );
        EThanksERC20(s.tnksContract).mint(msg.sender, reward);
        s.totalMinted[_campaignId] += reward;
        LibERC20.transferFrom(
            campaign.acceptedToken,
            msg.sender,
            address(this),
            _amount
        );

        emit Donation(msg.sender, _campaignId, s.tnksContract, _amount, reward);
    }
}
