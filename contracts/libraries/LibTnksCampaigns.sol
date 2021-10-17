// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import {LibDiamond} from "./LibDiamond.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {LibAppStorage, AppStorage, TokenEmissionParams, Campaign} from "./LibAppStorage.sol";

library LibTnksCampaigns {
    using SafeMath for uint256;

    function addCampaign(Campaign memory _campaign) internal {
        LibDiamond.enforceIsContractOwner();
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(
            _campaign.receiver != address(0),
            "CAMPAIGN: receiver can't be 0 address"
        );
        s.campaigns[s.totalCampaigns] = _campaign;
        s.totalCampaigns++;
    }

    function getExpectedTnksReward(uint256 _campaignId, uint256 _amount) internal view returns(uint256){
        AppStorage storage s = LibAppStorage.diamondStorage();

        TokenEmissionParams memory params = getCampaignTokenEmissionParams(_campaignId);
        uint256 delta = block.number - s.campaigns[_campaignId].startBlock;
        return getRewardRateBP(params.baseReward, params.hl, delta) * _amount / (100*10000);
    }

    function getCampaignTokenEmissionParams(uint256 _campaignId) internal view returns(TokenEmissionParams memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        uint8 campaignParamsId = s.campaigns[_campaignId].campaignTypeParams;
        return s.tokenEmissionParams[campaignParamsId];
    }

    function getRewardRateBP(uint256 _baseReward, uint256 _hl, uint256 _delta) internal pure returns(uint256){
        _baseReward *= 100*10000;

        uint256 hlStage = _baseReward >> (_delta.div(_hl));
        uint256 d = hlStage.mul(_delta.mod(_hl)).div(_hl).div(2);

        return hlStage.sub(d);
    }
}
