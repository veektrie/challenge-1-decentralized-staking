// SPDX-License-Identifier: MIT
pragma solidity 0.8.20; //Do not change the solidity version as it negatively impacts submission grading

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
    ExampleExternalContract public exampleExternalContract;

    constructor(address exampleExternalContractAddress) {
        exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
    }

    // Mapping to track individual balances
    mapping(address => uint256) public balances;
    uint256 public constant threshold = 1 ether;

    // Set a deadline to 30 seconds after deployment
    uint256 public deadline = block.timestamp + 30 seconds;

    // Flag to indicate if withdrawals are allowed (if threshold is not met)
    bool public openForWithdraw;

    // Event to log staking actions
    event Stake(address indexed staker, uint256 amount);

    // The stake function that accepts Ether and updates balances
    function stake() public payable {
        require(msg.value > 0, "Staking amount must be greater than 0");
        balances[msg.sender] += msg.value;
        emit Stake(msg.sender, msg.value);
    }

    // Execute function that anyone can call after the deadline has passed
    // If the contract balance is at or above the threshold, it sends the balance to the external contract.
    // Otherwise, it sets openForWithdraw to true so users can withdraw their funds.
    function execute() public {
        require(block.timestamp >= deadline, "Deadline not reached yet");

        if (address(this).balance >= threshold) {
            // If threshold is met, complete the external contract by sending all funds.
            exampleExternalContract.complete{ value: address(this).balance }();
        } else {
            // If threshold is not met, enable withdrawals.
            openForWithdraw = true;
        }
    }

    // Withdraw function for users to retrieve their funds if openForWithdraw is true.
    // Protected by notCompleted to avoid withdrawal after external contract completion.
    function withdraw() public notCompleted {
        require(openForWithdraw, "Withdrawals are not allowed");
        uint256 userBalance = balances[msg.sender];
        require(userBalance > 0, "No funds to withdraw");

        // Reset balance before transferring to prevent re-entrancy attacks.
        balances[msg.sender] = 0;
        (bool sent, ) = msg.sender.call{ value: userBalance }("");
        require(sent, "Failed to send Ether");
    }

    // timeLeft returns the time remaining before the deadline.
    // If the deadline has passed, it returns 0.
    function timeLeft() public view returns (uint256) {
        if (block.timestamp >= deadline) {
            return 0;
        }
        return deadline - block.timestamp;
    }
    // After some `deadline` allow anyone to call an `execute()` function
    // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`

    // If the `threshold` was not met, allow everyone to call a `withdraw()` function to withdraw their balance

    // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend

    // Add the `receive()` special function that receives eth and calls stake()
}
