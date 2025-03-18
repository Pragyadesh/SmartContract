// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract GymMembership {
    address public owner; //Stores the Ethereum address of the contract owner.
    IERC20 public gymToken; // A reference to an ERC-20 token contract used for payments.
    uint256 public membershipFeeToken = 100 * 10 ** 18; // Membership fee in ERC-20 tokens (100 tokens, assuming 18 decimal places).
    uint256 public membershipDuration = 365 days; // Membership valid for a year

    // Stores membership status and expiry date for each user.
    struct Member {
        bool isActive; // Flag to check if the membership is active
        uint256 expiryDate; // Timestamp when the membership expires
        uint256 totalTokens; // Total tokens earned by the user (from workouts)
        uint256 workoutCountThisWeek; // Number of workouts logged this week
        uint256 lastWorkoutTimestamp; // Timestamp of the last workout
    }

    // A mapping to store the membership details of each user.
    mapping(address => Member) public members;

    // Logs when a user buys a membership; indexed allows searching by user address.
    event MembershipPurchased(
        address indexed user,
        uint256 expiryDate,
        string paymentMethod
    );
    // Event to log workout entries
    event WorkoutLogged(
        address indexed user,
        uint256 workoutsession,
        uint256 rewardTokens
    );

    // Event to log reward redemptions
    event RewardRedeemed(
        address indexed user,
        uint256 tokenAmount,
        string rewardType
    );

    // Ensures that only the contract owner can call certain functions.
    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    //Sets the owner to the deployer's address; Links the ERC-20 token contract.
    constructor(address _gymToken) {
        owner = msg.sender;
        gymToken = IERC20(_gymToken);
    }

    /**
     * @dev Buy membership using ERC-20 Tokens
     */
    function buyMembershipWithToken() external {
        require(
            gymToken.balanceOf(msg.sender) >= membershipFeeToken,
            "Insufficient token balance"
        );
        require(
            gymToken.allowance(msg.sender, address(this)) >= membershipFeeToken,
            "Token allowance too low"
        );

        // Transfer tokens to the contract
        bool success = gymToken.transferFrom(
            msg.sender,
            address(this),
            membershipFeeToken
        );
        require(success, "Token transfer failed");

        // Extend membership or create a new one
        if (members[msg.sender].expiryDate < block.timestamp) {
            members[msg.sender].expiryDate =
                block.timestamp +
                membershipDuration;
        } else {
            members[msg.sender].expiryDate += membershipDuration;
        }
        members[msg.sender].isActive = true;

        emit MembershipPurchased(
            msg.sender,
            members[msg.sender].expiryDate,
            "ERC-20 Token"
        );
    }

    /**
     * @dev Check if a user has an active membership
     */
    function isMemberActive(address user) public view returns (bool) {
        return
            members[user].isActive &&
            block.timestamp <= members[user].expiryDate;
    }

    //Allows the owner to withdraw all ERC-20 tokens from the contract.
    function withdrawTokens() external onlyOwner {
        uint256 balance = gymToken.balanceOf(address(this));
        require(balance > 0, "No tokens in contract");
        gymToken.transfer(owner, balance);
    }
    /**
     * @dev Log a user's workout and reward them with tokens.
     * For 1 workout session = 0.00015
     */
    function logWorkout(uint256 workoutsession) external {
        require(isMemberActive(msg.sender), "Membership is not active");

        // uint256 currentWeek = getCurrentWeekNumber();
        // uint256 lastWorkoutWeek = getCurrentWeekNumberFromTimestamp(
        //     members[msg.sender].lastWorkoutTimestamp
        // );

        // If a new workout after 4 session, reset the workout count
        if (workoutsession == 4) {
            members[msg.sender].workoutCountThisWeek = 0;
        }
        // // If a new workout after 4 session, reset the workout count
        // if (currentWeek > lastWorkoutWeek) {
        //     members[msg.sender].workoutCountThisWeek = 0;
        // }

        // Calculate the reward tokens based on the workout time
        uint256 rewardTokens = (workoutsession * 15) / 100000; // Divide workout time by 0.00015 to calculate the tokens

        // If the workout session is less than 4, no tokens will be rewarded
        if (workoutsession < 4) {
            rewardTokens = 0;
        }

        // Add the calculated reward tokens to the user's total
        members[msg.sender].totalTokens += rewardTokens;
        members[msg.sender].workoutCountThisWeek += 1;
        members[msg.sender].lastWorkoutTimestamp = block.timestamp;

        // Transfer the tokens to the user as a reward
        bool success = gymToken.transfer(msg.sender, rewardTokens);
        require(success, "Token transfer failed");

        emit WorkoutLogged(msg.sender, workoutsession, rewardTokens);
    }

    /**
     * @dev Redeem tokens for rewards once the user meets certain conditions.
     * Healthy lunch is available after 4 workouts per week.
     * Merchandise or NFT is available once 1000 tokens are accumulated.
     */
    function redeemReward() external {
        uint256 totalTokens = members[msg.sender].totalTokens;
        uint256 lunchTokens = (totalTokens * 6) / 10000; // 6% of total tokens
        uint256 workoutsThisWeek = members[msg.sender].workoutCountThisWeek;

        // Reward for 4 workouts in a week: Healthy lunch
        if (workoutsThisWeek >= 4) {
            require(
                totalTokens >= lunchTokens,
                "Insufficient tokens for lunch reward"
            ); // Example: Healthy lunch costs 10 tokens
            members[msg.sender].totalTokens -= lunchTokens;
            emit RewardRedeemed(msg.sender, lunchTokens, "Healthy lunch");
        }
    }
    // Helper function to get the current week number based on timestamp
    function getCurrentWeekNumber() public view returns (uint256) {
        uint256 dayOfYear = (block.timestamp / 1 days) % 365; // Get the day of the year
        return (dayOfYear / 7) + 1; // Week number is based on the day of the year
    }

    // Helper function to get the week number of a timestamp
    function getCurrentWeekNumberFromTimestamp(
        uint256 timestamp
    ) public pure returns (uint256) {
        uint256 dayOfYear = (timestamp / 1 days) % 365;
        return (dayOfYear / 7) + 1;
    }
}
