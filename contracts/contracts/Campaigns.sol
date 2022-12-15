// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Campaigns {
    // Events
    event CampaignCreated(uint256 campaignID, address operator, address treasury, string campaignName, string description, uint256 targetGoal, uint256 timestamp);
    event Donated(uint256 campaignID, address donor, uint256 amount, uint256 timestamp);
    event PromotionSubmitted(uint256 campaignID, address promoter, uint256 amountPaid, string link, uint256 timestamp);

    // Campaign information
    struct Campaign {
        address operator;
        address payable treasury;
        string campaignName;
        string description;
        uint256 targetGoal;
        uint256 totalDonated;
        bool isActive;
        uint256 timestampCreated;
    }

    // Mapping to keep track of all the campaigns
    mapping (uint256 => Campaign) public campaigns;

    // Campaign index
    uint256 public campaignsIndex = 0;

    // 3 ETH - 3e18
    uint256 public PROMOTION_PRICE = 3000000000000000000;

    // 1 ETH - 1e18
    uint256 public MINIMUM_DONATION = 1000000000000000000;

    // The platform treasury address
    address private platformTreasury;

    constructor(address _platformTreasury) {
        platformTreasury = _platformTreasury;
    }

    // @notice create a new campaign
    function createCampaign(address _treasury, string memory _campaignName, string memory _description, uint256 _targetGoal) external {
        require(_treasury != address(this), "The treasury address cannot be the contract address.");
        require(_targetGoal > 0, "The target goal must be greater than 0.");
        require(_treasury != address(0), "The treasury address cannot be the zero address.");
        require(bytes(_campaignName).length > 0, "The campaign name cannot be empty.");
        require(bytes(_description).length > 0, "The description cannot be empty.");

        // Increment the campaign index
        uint256 index = campaignsIndex + 1;
        
        // Create a new campaign using the provided information
        campaigns[index] = Campaign(msg.sender, payable(_treasury), _campaignName, _description, _targetGoal, 0, false, block.timestamp);

        // Set the new campaign index
        campaignsIndex = index;

        // Emit the CampaignCreated event
        emit CampaignCreated(index, msg.sender, _treasury, _campaignName, _description, _targetGoal, block.timestamp);
    }


    // @notice donate to a campaign
    function donate(uint256 _campaignID) public payable {
        require(campaigns[_campaignID].operator != address(0), "The campaign does not exist.");
        require(msg.value >= MINIMUM_DONATION, "The donation value sent must be greater than or equal to the minimum donation amount.");

        // Store the amount sent in a temporary variable
        uint256 _amount = msg.value;

        // Get the campaign information
        Campaign storage campaign = campaigns[_campaignID];

        // Only allow donations if the campaign is active
        require(campaign.isActive, "This campaign is not active.");

        // Transfer the amount to the treasury
        payable(campaign.treasury).transfer(_amount);

        // Add the donated amount to the total amount donated
        campaign.totalDonated = campaign.totalDonated + _amount;

        // If the total amount donated is greater than or equal to the target goal, deactivate the campaign
        if (campaign.totalDonated >= campaign.targetGoal) {
            campaign.isActive = false;
        }

        // Emit the Donated event
        emit Donated(_campaignID, msg.sender, _amount, block.timestamp);
    }

    // @notice allows promoters to submit a promotion social media link for a campaign.
    // The promoter must pay the PROMOTION_PRICE to submit a promotion link.
    // The promoter must submit a link to a social media post that promotes the campaign.
    // The payment is refunded if the campaign is not active.
    // The payment is split between the campaign treasury and the platform.
    function submitPromotion(uint256 _campaignID, string memory _link) public payable {
        require(campaigns[_campaignID].operator != address(0), "The campaign does not exist.");
        require(msg.value == PROMOTION_PRICE, "The promotion price must be equal to the value sent.");
        require(bytes(_link).length > 0, "The link cannot be empty.");

        // Get the campaign information
        Campaign storage campaign = campaigns[_campaignID];

        // Only allow promotions if the campaign is active
        require(campaign.isActive, "This campaign is not active.");

        // Calculate the platform fee - 20%
        uint256 platformFee = PROMOTION_PRICE / 100 * 20;

        // Calculate the campaign fee - 80%
        uint256 campaignFee = PROMOTION_PRICE / 100 * 80;

        // Transfer the platform and campaign fees to their respective treasuries
        payable(platformTreasury).transfer(platformFee);
        payable(campaign.treasury).transfer(campaignFee);

        // Add the donated amount to the total amount donated
        campaign.totalDonated = campaign.totalDonated + campaignFee;

        // If the total amount donated is greater than or equal to the target goal, deactivate the campaign
        if (campaign.totalDonated >= campaign.targetGoal) {
            campaign.isActive = false;
        }

        // Emit the PromotionSubmitted event
        emit PromotionSubmitted(_campaignID, msg.sender, PROMOTION_PRICE, _link, block.timestamp);
    }

    // @notice allows the campaign operator to update the campaign information
    function updateCampaign(uint256 _campaignID, address _treasury, string memory _campaignName, string memory _description, uint256 _targetGoal) external {
        require(campaigns[_campaignID].operator != address(0), "The campaign does not exist.");
        require(campaigns[_campaignID].operator == msg.sender, "You are not the operator of this campaign.");
        require(_treasury != address(this), "The treasury address cannot be the contract address.");
        require(_targetGoal > 0, "The target goal must be greater than 0.");
        require(_treasury != address(0), "The treasury address cannot be the zero address.");
        require(bytes(_campaignName).length > 0, "The campaign name cannot be empty.");
        require(bytes(_description).length > 0, "The description cannot be empty.");

        // Get the campaign information
        Campaign storage campaign = campaigns[_campaignID];

        // Update the campaign information
        campaign.treasury = payable(_treasury);
        campaign.campaignName = _campaignName;
        campaign.description = _description;
        campaign.targetGoal = _targetGoal;
    }


    // @notice flips the status of a campaign
    function toggleCampaignStatus(uint256 _campaignID) public {
        require(campaigns[_campaignID].operator != address(0), "The campaign does not exist.");
        require(campaigns[_campaignID].operator == msg.sender, "You are not the operator of this campaign.");

        // Get the campaign information
        Campaign storage campaign = campaigns[_campaignID];

        // Flip the active status
        campaign.isActive = !campaign.isActive;
    }

    // @notice gets the campaign information
    function getCampaign(uint256 _campaignID) public view returns (Campaign memory) {
        return campaigns[_campaignID];
    }

    // @notice gets the campaign operator
    function getCampaignOperator(uint256 _campaignID) public view returns (address) {
        return campaigns[_campaignID].operator;
    }

    // @notice gets the campaign current index
    function getLatestCampaignsIndex() public view returns (uint256) {
        return campaignsIndex;
    }
}
