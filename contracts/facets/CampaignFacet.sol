// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import {AppStorage, Campaign, CampaignType,HalfLifeEmissionParams} from "../libraries/LibAppStorage.sol";
import {LibHLCampaign} from "../libraries/LibHLCampaigns.sol";
import {LibERC20} from "../libraries/LibERC20.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";

import {EThanks} from "../EThanksERC20.sol";

contract CampaignFacet {
    AppStorage internal s;

    event Donation(address donator, uint256 campaignId, address token, uint256 donated, uint256 reward);
    event NewCampaign(uint256 campaignId, Campaign campaign);
    event ChangedCampaignDuration(uint256 campaignId, uint256 previousBlockDuration);
    event NewTypeParams(CampaignType campaignType, uint8 paramsId);

    //event EditTypeParams(CampaignType campaignType, uint8 paramsId);

    function addHLParams(uint256 _baseReward, uint256 _hl) external {
        LibDiamond.enforceIsContractOwner();
        s.halfLifeEmissionParams[s.totalHalfLifeParams] = HalfLifeEmissionParams(
            _baseReward,
            _hl
        );
        s.totalHalfLifeParams++;

        emit NewTypeParams(CampaignType.HALF_LIFE, s.totalHalfLifeParams-1);
    }

    function addHLCampaign(
        uint8 _halfLifeParams,
        address _acceptedToken,
        uint256 _blocksDuration,
        address _receiver
    ) external {
        LibDiamond.enforceIsContractOwner();
        _addCampaign(Campaign(CampaignType.HALF_LIFE, _halfLifeParams, _receiver, _acceptedToken, block.number, _blocksDuration));
    }

    // function _editCampaign(uint256 _campaignId, Campaign memory _newData) internal {
    //     Campaign memory oldData = s.campaigns[_campaignId];
    //     s.campaigns[_campaignId] = _newData;

    //     emit EditedCampaign(oldData, _newData);
    // }

    function _addCampaign(Campaign memory _campaign) internal {
        LibDiamond.enforceIsContractOwner();
        require(_campaign.receiver != address(0), "CAMPAIGN: receiver can't be 0 address");
        s.campaigns[s.totalCampaigns] = _campaign;
        s.totalCampaigns++;

        emit NewCampaign(s.totalCampaigns-1, _campaign);
    }

    function changeCampaignDuration(uint256 _campaignId, uint256 _newBlocksDuration) public {
        LibDiamond.enforceIsContractOwner();
        s.campaigns[_campaignId].blocksDuration = _newBlocksDuration;
        emit ChangedCampaignDuration(_campaignId, _newBlocksDuration);
    }

    function donateToHalfLifeCampaign(uint256 _campaignId, uint256 _amount) public {
        require(_amount > 0, "ETHANKS: Donation can't be 0");
        require(s.totalCampaigns > _campaignId, "ETHANKS: Invalid campaign id");
        require(s.campaigns[_campaignId].campaignType == CampaignType.HALF_LIFE, "ETHANKS: Wrong donation method");

        address token = s.campaigns[_campaignId].acceptedToken;
        uint256 reward = LibHLCampaign.getTnksRewardRate(_campaignId) * _amount;

        LibERC20.transferFrom(token, msg.sender, s.campaigns[_campaignId].receiver, _amount);
        EThanks(s.tnksContract).mint(msg.sender, reward);

        emit Donation(msg.sender, _campaignId, token, _amount, reward);
    }
}
