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
        bool isActive;
        uint256 expiryDate;
    }

    // A mapping to store the membership details of each user.
    mapping(address => Member) public members;
    // Logs when a user buys a membership; indexed allows searching by user address.
    event MembershipPurchased(
        address indexed user,
        uint256 expiryDate,
        string paymentMethod
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
}
