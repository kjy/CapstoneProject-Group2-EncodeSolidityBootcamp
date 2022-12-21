// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Campaigns {
    using SafeMath for uint256;

    // Events
    event CampaignCreated(uint256 campaignID, address operator, address treasury, string campaignName, string description, uint256 targetGoal, uint256 timestamp);
    event Donated(uint256 campaignID, address donor, uint256 amount, uint256 pointsEarned, uint256 timestamp);
    event PromotionSubmitted(uint256 campaignID, address promoter, uint256 amountPaid, string link, uint256 points, uint256 campaignFee, uint256 timestamp);

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

    // Promotion Information
    struct Promotion {
        string link;
        uint256 points;
    }

    // Mapping to keep track of all the campaigns
    mapping (uint256 => Campaign) public campaigns;

    // Mapping of all promotions
    mapping (uint256 => Promotion) public promotions;

    // Mapping of what promotion is associated with what campaign
    mapping(uint256 => uint256) public promotionCampaign;

    // Mapping to keep track of what promotions users have used their campaign points towards
    mapping (address => mapping (uint256 => uint256)) public campaignPointsSpent;

    // Mapping of amount of campaignPoints a user has
    mapping (address => uint256) public campaignPoints;

    // Campaign index
    uint256 public campaignsIndex = 0;

    // Promotino index
    uint256 public promotionsIndex = 0;

    // 0.003 ETH - 3e18
    // 0.003 ETH and 0.001 ETH respectively
    uint256 public PROMOTION_PRICE = 3000000000000000;
    uint256 public MINIMUM_DONATION = 1000000000000000;

    // The platform operator address
    address private platformOperator;
    // The platform treasury address
    address public platformTreasury;

    // The platform and campaign fee percent - initially set to 20% and 80%
    uint256 public platformFeePercent;
    uint256 public campaignFeePercent;

    // @param _platformTreasury the platform treasury address
    constructor(address _platformTreasury) {
        platformOperator = msg.sender;
        platformTreasury = _platformTreasury;
        campaignFeePercent = 80;
        platformFeePercent = 20;
    }

    // @notice create a new campaign
    // @param _treasury the campaign treasury address
    // @param _campaignName the campaign name
    // @param _description the campaign description
    // @param _targetGoal the campaign target goal
    function createCampaign(address _treasury, string memory _campaignName, string memory _description, uint256 _targetGoal) external {
        require(_treasury != address(this), "The treasury address cannot be the contract address.");
        require(_targetGoal > 0, "The target goal must be greater than 0.");
        require(_treasury != address(0), "The treasury address cannot be the zero address.");
        require(bytes(_campaignName).length > 0, "The campaign name cannot be empty.");
        require(bytes(_description).length > 0, "The description cannot be empty.");

        // Increment the campaign index
        uint256 index = campaignsIndex.add(1);
        
        // Create a new campaign using the provided information
        campaigns[index] = Campaign(msg.sender, payable(_treasury), _campaignName, _description, _targetGoal, 0, false, block.timestamp);

        // Set the new campaign index
        campaignsIndex = index;

        // Emit the CampaignCreated event
        emit CampaignCreated(index, msg.sender, _treasury, _campaignName, _description, _targetGoal, block.timestamp);
    }


    // @notice donate to a campaign
    // @param _campaignID the campaign ID
    function donate(uint256 _campaignID) public payable {
        require(campaigns[_campaignID].operator != address(0), "The campaign does not exist.");

        // Get the campaign information
        Campaign storage campaign = campaigns[_campaignID];
        require(campaign.isActive, "This campaign is not active.");
        require(msg.value >= MINIMUM_DONATION, "The donation value sent must be greater than or equal to the minimum donation amount.");

        // Store the amount sent in a temporary variable
        uint256 _amount = msg.value;
        uint256 _pointsEarned = _amount;

        // eth donation
        (bool success, ) = payable(campaign.treasury).call{value: msg.value}("");
        require(success, "Transfer failed.");
        

        // Add the donated amount to the total amount donated
        campaign.totalDonated = campaign.totalDonated + _amount;

        // If the total amount donated is greater than or equal to the target goal, deactivate the campaign
        if (campaign.totalDonated >= campaign.targetGoal) {
            campaign.isActive = false;
        }

        // Update campaign points for user
        campaignPoints[msg.sender] += _amount;

        // Emit the Donated event
        emit Donated(_campaignID, msg.sender, _amount, _pointsEarned, block.timestamp);
    }

    // @notice allows promoters to submit a promotion social media link for a campaign.
    // @param _campaignID the campaign ID
    // @param _link the link to the social media post
    function submitPromotion(uint256 _campaignID, string memory _link, uint256 _points) public payable {
        require(campaigns[_campaignID].operator != address(0), "The campaign does not exist.");
        require(msg.value == PROMOTION_PRICE, "The promotion price must be equal to the value sent.");
        require(bytes(_link).length > 0, "The link cannot be empty.");
        require(_points > 0, "The points required to use any promotion cannot be 0.");

        // Get the campaign information
        Campaign storage campaign = campaigns[_campaignID];

        // Only allow promotions if the campaign is active
        require(campaign.isActive, "This campaign is not active.");

        // Calculate the platform fee - 20%
        uint256 platformFee = PROMOTION_PRICE.div(100).mul(platformFeePercent);

        // Calculate the campaign fee - 80%
        uint256 campaignFee = PROMOTION_PRICE.div(100).mul(campaignFeePercent);

        // Transfer the platform and campaign fees to their respective treasuries
        (bool success2, ) = payable(platformTreasury).call{value: platformFee}("");
        require(success2, "Transfer to platform treasury failed.");
        (bool success, ) = payable(campaign.treasury).call{value: campaignFee}("");
        require(success, "Transfer to campaign treasury failed.");

        // make sure both payments are successful
        require(success && success2, "Payment split between campaign and platform treasuries failed.");

        // Add the donated amount to the total amount donated
        campaign.totalDonated = campaign.totalDonated + campaignFee;

        // If the total amount donated is greater than or equal to the target goal, deactivate the campaign
        if (campaign.totalDonated >= campaign.targetGoal) {
            campaign.isActive = false;
        }

        // Create a new promotion using the provided information
        promotions[promotionsIndex] = Promotion(_link, _points);

        // Update mapping to show promotion is associated with campaign
        promotionCampaign[promotionsIndex] = _campaignID;

        // Set the new promotion index
        promotionsIndex = promotionsIndex.add(1);

        // Emit the PromotionSubmitted event
        emit PromotionSubmitted(_campaignID, msg.sender, PROMOTION_PRICE, _link, _points, campaignFee, block.timestamp);
    }

    // @notice allows the campaign operator to update the campaign information
    // @param _campaignID the campaign ID
    // @param _treasury the campaign treasury address
    // @param _campaignName the campaign name
    // @param _description the campaign description
    // @param _targetGoal the campaign target goal
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
    // @param _campaignID the campaign ID
    function toggleCampaignStatus(uint256 _campaignID) external {
        require(campaigns[_campaignID].operator != address(0), "The campaign does not exist.");
        require(campaigns[_campaignID].operator == msg.sender, "You are not the operator of this campaign.");

        // Get the campaign information
        Campaign storage campaign = campaigns[_campaignID];

        // Flip the active status
        campaign.isActive = !campaign.isActive;
    }


    // @notice allows the platform operator to adjust the campaign and platform percentage fee distribution
    // must add up to 100
    // @param _campaignFeePercentage the campaign fee percentage
    // @param _platformFeePercentage the platform fee percentage
    function adjustFeeDistribution(uint256 _campaignFeePercentage, uint256 _platformFeePercentage) external {
        require(msg.sender == platformOperator, "You are not the platform operator.");
        require(_campaignFeePercentage.add(_platformFeePercentage) == 100, "The campaign and platform fee must add up to 100.");

        // Update the platform and campaign fee
        platformFeePercent = _platformFeePercentage;
        campaignFeePercent = _campaignFeePercentage;
    }

    // @notice allows contrinbutors to spend campaignPoints towards promotions
    function spendCampaignPoints(uint256 _promotionId) external {
        require(_promotionId < promotionsIndex, "Invalid promotion id");
        require(campaignPoints[msg.sender] >= promotions[_promotionId].points, "not enough points to spend on this campaign");
        campaignPointsSpent[msg.sender][_promotionId] = promotions[_promotionId].points;
        campaignPoints[msg.sender] -= promotions[_promotionId].points;
    }

    // @notice gets the campaign information
    // @param _campaignID the campaign ID
    function getCampaign(uint256 _campaignID) public view returns (Campaign memory) {
        return campaigns[_campaignID];
    }
}
