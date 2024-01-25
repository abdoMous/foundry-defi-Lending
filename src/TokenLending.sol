// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Basic Token Lending Contract
/// @author abdomo
/// @notice ERC20 token lending, borrowing, and repayment contract
contract TokenLending {
    /////////////////////
    // State Variables //
    /////////////////////
    mapping(address => uint256) public s_balances;
    mapping(address => uint256) public s_borrowed;
    IERC20 public s_token;

    ///////////////
    // Functions //
    ///////////////

    constructor(address _tokenAddress) {
        s_token = IERC20(_tokenAddress);
    }

    function depositToken(uint256 amount) external {
        s_token.transferFrom(msg.sender, address(this), amount);
        s_balances[msg.sender] += amount;
    }

    function withdrawToken(uint256 amount) external {
        require(amount <= s_balances[msg.sender], "Insufficient balance");
        s_balances[msg.sender] -= amount;
        s_token.transfer(msg.sender, amount);
    }

    function borrowToken(uint256 amount) external {
        require(amount <= s_token.balanceOf(address(this)), "Insufficient funds");
        s_borrowed[msg.sender] += amount;
        s_token.transfer(msg.sender, amount);
    }

    function repayToken(uint256 amount) external {
        require(amount <= s_borrowed[msg.sender], "Repaying too much");
        s_borrowed[msg.sender] -= amount;
        s_token.transferFrom(msg.sender, address(this), amount);
    }
}
