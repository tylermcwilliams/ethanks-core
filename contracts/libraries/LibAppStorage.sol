// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

enum CampaignType {
    HALF_LIFE
}

struct HalfLifeEmissionParams {
    uint256 baseReward;
    uint256 hl;
}

struct Campaign {
    CampaignType campaignType;
    uint8 campaignTypeParams;
    address receiver;
    address acceptedToken;
    uint256 startBlock;
    uint256 blocksDuration;
}

struct AppStorage {
    address tnksContract;
    uint256 totalCampaigns;
    mapping(uint256=>Campaign) campaigns;
    // halflife emission fields
    uint8 totalHalfLifeParams;
    mapping(uint8=>HalfLifeEmissionParams) halfLifeEmissionParams;
}

library LibAppStorage {
    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }

    // function abs(int256 x) internal pure returns (uint256) {
    //     return uint256(x >= 0 ? x : -x);
    // }
}