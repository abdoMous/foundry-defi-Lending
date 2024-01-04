// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

/// @title Basic Lending Contract
/// @author Abdomo
/// @notice Basic Lending Contract is designed to facilitate four core functionalities: depositing, withdrawing, borrowing, and repaying Ethereum (ETH).
contract BasicLending {
    /////////////////////
    // State Variables //
    /////////////////////
    mapping(address => uint256) public s_balances;
    mapping(address => uint256) public s_borrowed;

    ///////////////
    // Functions //
    ///////////////

    function deposit() external payable {
        s_balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) external {
        require(s_balances[msg.sender] >= amount, "Insufficient balance");
        s_balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    function borrow(uint256 amount) external {
        s_borrowed[msg.sender] += amount;
        payable(msg.sender).transfer(amount);
    }

    function repay() external payable {
        require(s_borrowed[msg.sender] >= msg.value, "Repaying too much");
        s_borrowed[msg.sender] -= msg.value;
    }
}
