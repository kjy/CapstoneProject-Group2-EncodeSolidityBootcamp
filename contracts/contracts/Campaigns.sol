// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Campaigns {
    using SafeMath for uint256;

    // Events
    event CampaignCreated(uint256 campaignID, address operator, address treasury, string campaignName, string description, uint256 targetGoal, uint256 timestamp);
    event Donated(uint256 campaignID, address donor, uint256 amount, uint256 timestamp);
    event PromotionSubmitted(uint256 campaignID, address promoter, uint256 amountPaid, string link, uint256 platformFee, uint256 campaignFee, uint256 timestamp);

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
    mapping (address => mapping (uint256 => uint256)) private campaignPointsSpent;

    // Mapping of amount of campaignPoints a user has
    mapping (address => uint256) private campaignPoints;

    // Campaign index
    uint256 public campaignsIndex = 0;

    // Promotino index
    uint256 public promotionsIndex = 0;

    // 0.003 ETH - 3e18
    uint256 public PROMOTION_PRICE = 3000000000000000;

    // 0.001 ETH - 1e18
    uint256 public MINIMUM_DONATION = 1000000000000000;

    // The platform operator address
    address public platformOperator;
    // The platform treasury address
    address private platformTreasury;

    // The platform and campaign fee percent - initially set to 20% and 80%
    uint256 public platformFeePercent;
    uint256 public campaignFeePercent;

    constructor(address _platformTreasury) {
        platformOperator = msg.sender;
        platformTreasury = _platformTreasury;
        campaignFeePercent = 80;
        platformFeePercent = 20;
    }

    // @notice create a new campaign
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
    function donate(uint256 _campaignID) public payable {
        require(campaigns[_campaignID].operator != address(0), "The campaign does not exist.");

        // Get the campaign information
        Campaign storage campaign = campaigns[_campaignID];
        require(campaign.isActive, "This campaign is not active.");
        require(msg.value >= MINIMUM_DONATION, "The donation value sent must be greater than or equal to the minimum donation amount.");

        // Store the amount sent in a temporary variable
        uint256 _amount = msg.value;


        // Transfer the amount to the treasury
        payable(campaign.treasury).transfer(_amount);

        // Add the donated amount to the total amount donated
        campaign.totalDonated = campaign.totalDonated + _amount;

        // If the total amount donated is greater than or equal to the target goal, deactivate the campaign
        if (campaign.totalDonated >= campaign.targetGoal) {
            campaign.isActive = false;
        }

        // Update campaign points for user
        campaignPoints[msg.sender] += _amount;

        // Emit the Donated event
        emit Donated(_campaignID, msg.sender, _amount, block.timestamp);
    }

    // @notice allows promoters to submit a promotion social media link for a campaign.
    // The promoter must pay the PROMOTION_PRICE to submit a promotion link.
    // The promoter must submit a link to a social media post that promotes the campaign.
    // The payment is refunded if the campaign is not active.
    // The payment is split between the campaign treasury and the platform.
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
        payable(platformTreasury).transfer(platformFee);
        payable(campaign.treasury).transfer(campaignFee);

        // Add the donated amount to the total amount donated
        campaign.totalDonated = campaign.totalDonated + campaignFee;

        // If the total amount donated is greater than or equal to the target goal, deactivate the campaign
        if (campaign.totalDonated >= campaign.targetGoal) {
            campaign.isActive = false;
        }

        // Create a new campaign using the provided information
        promotions[promotionsIndex] = Promotion(_link, _points);

        // Update mapping to show promotion is associated with campaign
        promotionCampaign[promotionsIndex] = _campaignID;

        // Set the new campaign index
        campaignsIndex = promotionsIndex.add(1);

        // Emit the PromotionSubmitted event
        emit PromotionSubmitted(_campaignID, msg.sender, PROMOTION_PRICE, _link, platformFee, campaignFee, block.timestamp);
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


    // @notice allows the platform operator to adjust the campaign and platform percentage fee distribution
    function adjustFeeDistribution(uint256 _campaignFeePercentage, uint256 _platformFeePercentage) public {
        require(msg.sender == platformOperator, "You are not the platform operator.");
        require(_campaignFeePercentage.add(_platformFeePercentage) == 100, "The campaign and platform fee must add up to 100.");

        // Update the platform and campaign fee
        platformFeePercent = _platformFeePercentage;
        campaignFeePercent = _campaignFeePercentage;
    }

    // @notice allows contrinbutors to spend campaignPoints towards promotions
    function spendCampaignPoints(uint256 _promotionId) public {
        require(_promotionId < promotionsIndex, "Invalid promotion id");
        require(campaignPoints[msg.sender] >= promotions[_promotionId].points, "not enough points to spend on this campaign");
        campaignPointsSpent[msg.sender][_promotionId] = promotions[_promotionId].points;
        campaignPoints[msg.sender] -= promotions[_promotionId].points;
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
