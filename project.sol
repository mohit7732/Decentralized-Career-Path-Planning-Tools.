// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ERC20 interface for reward token
interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract CareerPathPlanning {
    address public owner;
    IERC20 public rewardToken;
    uint256 public rewardAmountForGoal;
    uint256 public rewardAmountForMilestone;

    // Struct to hold career path details
    struct CareerPath {
        string name;
        string description;
        uint256 targetGoal;
        uint256 milestonesAchieved;
        bool goalAchieved;
    }

    mapping(address => CareerPath) public careerPaths;
    mapping(address => uint256) public userMilestoneCount;

    // Events to log actions
    event CareerGoalSet(address indexed user, string goalName, uint256 targetGoal);
    event CareerMilestoneAchieved(address indexed user, uint256 milestoneCount);
    event CareerGoalAchieved(address indexed user, uint256 totalReward);

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    modifier hasSufficientTokens() {
        require(rewardToken.balanceOf(address(this)) >= rewardAmountForGoal, "Insufficient contract balance");
        _;
    }

    constructor(address _rewardTokenAddress, uint256 _rewardAmountForGoal, uint256 _rewardAmountForMilestone) {
        owner = msg.sender;
        rewardToken = IERC20(_rewardTokenAddress);
        rewardAmountForGoal = _rewardAmountForGoal;
        rewardAmountForMilestone = _rewardAmountForMilestone;
    }

    // Function to set career goals for a user
    function setCareerGoal(string memory _name, string memory _description, uint256 _targetGoal) public {
        CareerPath storage career = careerPaths[msg.sender];
        career.name = _name;
        career.description = _description;
        career.targetGoal = _targetGoal;
        career.milestonesAchieved = 0;
        career.goalAchieved = false;

        emit CareerGoalSet(msg.sender, _name, _targetGoal);
    }

    // Function to track milestone achievement and award tokens
    function achieveMilestone() public {
        CareerPath storage career = careerPaths[msg.sender];
        require(bytes(career.name).length != 0, "No career goal set");

        career.milestonesAchieved++;
        emit CareerMilestoneAchieved(msg.sender, career.milestonesAchieved);

        // Reward the user for achieving a milestone
        require(rewardToken.transfer(msg.sender, rewardAmountForMilestone), "Milestone reward transfer failed");
    }

    // Function to claim reward for completing the career goal
    function completeCareerGoal() public hasSufficientTokens {
        CareerPath storage career = careerPaths[msg.sender];
        require(bytes(career.name).length != 0, "No career goal set");
        require(career.targetGoal == career.milestonesAchieved, "Milestone target not met yet");

        career.goalAchieved = true;
        uint256 totalReward = rewardAmountForGoal + (career.milestonesAchieved * rewardAmountForMilestone);
        
        require(rewardToken.transfer(msg.sender, totalReward), "Goal reward transfer failed");

        emit CareerGoalAchieved(msg.sender, totalReward);
    }

    // Owner can update reward amounts
    function updateRewardAmountForGoal(uint256 _newRewardAmount) public onlyOwner {
        rewardAmountForGoal = _newRewardAmount;
    }

    function updateRewardAmountForMilestone(uint256 _newRewardAmount) public onlyOwner {
        rewardAmountForMilestone = _newRewardAmount;
    }

    // Owner can change the reward token address
    function setRewardToken(address _newTokenAddress) public onlyOwner {
        rewardToken = IERC20(_newTokenAddress);
    }

    // Function to check the contract's balance of reward tokens
    function contractBalance() public view returns (uint256) {
        return rewardToken.balanceOf(address(this));
    }
}
