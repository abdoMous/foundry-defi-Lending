// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Collateral Lending Contract
 * @notice This contract allows users to deposit ERC20 tokens, borrow against them as collateral, and repay their loans.
 * @dev This contract does not handle interest rates or loan durations.
 */
contract CollateralLending {
    /////////////////////
    // State Variables //
    /////////////////////
    mapping(address => uint256) public s_balances;
    mapping(address => uint256) public s_borrowed;

    IERC20 public s_token;

    ///////////////
    // Functions //
    ///////////////

    /// @notice The collateral factor, representing the percentage of tokens required as collateral.
    uint256 public constant COLLATERAL_FACTOR = 150;

    /**
     * @notice Sets the token to be used for lending and borrowing.
     * @param tokenAddress The address of the ERC20 token.
     */
    constructor(address tokenAddress) {
        s_token = IERC20(tokenAddress);
    }

    /**
     * @notice Allows users to deposit tokens into the contract.
     * @param amount The amount of tokens to deposit.
     */
    function depositToken(uint256 amount) external {
        s_token.transferFrom(msg.sender, address(this), amount);
        s_balances[msg.sender] += amount;
    }

    /**
     * @notice Allows users to withdraw their tokens from the contract.
     * @param amount The amount of tokens to withdraw.
     * @dev Requires that the user has enough balance to withdraw.
     */
    function withdrawToken(uint256 amount) external {
        require(amount <= s_balances[msg.sender], "Insufficient balance");
        s_balances[msg.sender] -= amount;
        s_token.transfer(msg.sender, amount);
    }

    /**
     * @notice Allows users to borrow tokens by providing ETH as collateral.
     * @param tokenAmount The amount of tokens to borrow.
     * @dev Requires that the user provides enough ETH as collateral and that the contract has enough tokens to lend.
     */
    function borrowTokenWithCollateral(uint256 tokenAmount) external payable {
        require(msg.value == tokenAmount * COLLATERAL_FACTOR / 100, "Insufficient collateral");
        require(tokenAmount <= s_token.balanceOf(address(this)), "Insufficient funds");
        s_borrowed[msg.sender] += tokenAmount;
        s_token.transfer(msg.sender, tokenAmount);
    }

    /**
     * @notice Allows users to repay their borrowed tokens.
     * @param tokenAmount The amount of tokens to repay.
     * @dev Requires that the user has borrowed at least the amount they are trying to repay.
     */
    function repayToken(uint256 tokenAmount) external {
        require(tokenAmount <= s_borrowed[msg.sender], "Repaying too much");
        s_borrowed[msg.sender] -= tokenAmount;
        s_token.transferFrom(msg.sender, address(this), tokenAmount);
        payable(msg.sender).transfer(tokenAmount * COLLATERAL_FACTOR / 100);
    }

    /**
     * @notice Allows for the liquidation of a borrower's collateral if they fail to maintain the required collateral factor.
     * @param borrower The address of the borrower.
     * @param tokenAmount The amount of tokens to be liquidated.
     * @dev Requires that the borrower's collateral is less than the required amount and that they have borrowed the specified token amount.
     */
    function liquidate(address borrower, uint256 tokenAmount) external payable {
        require(s_balances[borrower] < tokenAmount * COLLATERAL_FACTOR / 100, "Collateral is sufficient");
        require(tokenAmount <= s_borrowed[borrower], "Borrowed amount is less than liquidation amount");
        s_borrowed[borrower] -= tokenAmount;
        s_token.transferFrom(borrower, msg.sender, tokenAmount);
        payable(borrower).transfer(msg.value);
    }

    /**
     * @notice Allows users to check their balance.
     * @return The user's balance.
     */
    function balanceOf() external view returns (uint256) {
        return s_balances[msg.sender];
    }

    /**
     * @notice Allows users to check their borrowed amount.
     * @return The user's borrowed amount.
     */
    function borrowedOf() external view returns (uint256) {
        return s_borrowed[msg.sender];
    }
}
