// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import {LibDiamond} from "./LibDiamond.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {LibAppStorage, AppStorage, TokenEmissionParams, Campaign} from "./LibAppStorage.sol";

library LibHLCampaign {
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

    function getTnksRewardRate(uint256 _campaignId) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        TokenEmissionParams memory params = s.tokenEmissionParams[
            s.campaigns[_campaignId].campaignTypeParams
        ];
        uint256 delta = block.number - s.campaigns[_campaignId].startBlock;

        uint256 hlStage = params.baseReward >> (delta.div(params.hl));
        uint256 d = hlStage.mul(delta.mod(params.hl)).div(params.hl).div(2);

        return hlStage.sub(d);
    }
}
