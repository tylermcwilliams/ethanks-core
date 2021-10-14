// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {LibAppStorage, AppStorage, HalfLifeEmissionParams} from "./LibAppStorage.sol";

library LibHLCampaign {
    using SafeMath for uint256;

    function getTnksRewardRate(uint256 _campaignId) public view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        HalfLifeEmissionParams memory params = s.halfLifeEmissionParams[
            s.campaigns[_campaignId].campaignTypeParams
        ];
        uint256 delta = block.number - s.campaigns[_campaignId].startBlock;

        uint256 hlStage = params.baseReward >> (delta.div(params.hl));
        uint256 d = hlStage.mul(delta.mod(params.hl)).div(params.hl).div(2);

        return hlStage.sub(d);
    }
}
