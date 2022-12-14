// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Campaigns {
    // Information about the campaigns
    struct Campaign {
        address operator;
        address treasury;
        string campaignName;
        string description;
        uint256 targetGoal;
        uint256 totalDonated;
        bool isActive;
        uint256 timestampCreated;
    }

    // Mapping to keep track of all the campaigns
    mapping (bytes32 => Campaign) public campaigns;

    constructor() {}

    // Function to create a new campaign
    function createCampaign(address _operator, address _treasury, string memory _campaignName, string memory _description, uint256 _targetGoal) public {
        // Generate a unique ID for the campaign
        bytes32 campaignID = keccak256(abi.encodePacked(_campaignName, _description));

        // Create a new campaign using the provided information
        campaigns[campaignID] = Campaign(_operator, _treasury, _campaignName, _description, _targetGoal, 0, true, block.timestamp);
    }

    // Function to donate to a campaign
    function donate(bytes32 _campaignID, uint256 _amount) public payable {
        // Get the campaign information
        Campaign storage campaign = campaigns[_campaignID];

        // Only allow donations if the campaign is active
        require(campaign.isActive, "This campaign is not active.");

        // Add the donated amount to the total amount donated
        campaign.totalDonated += _amount;

    }
}
