// SPDX-License-Identifier: MIT

// Layout of Contract:
// version
// imports
// interfaces, libraries, contracts
// errors
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

pragma solidity ^0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface AggregatorV3Interface {
    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80);
}

/**
 * @title Advanced Lending Contract
 * @notice This contract allows users to deposit ERC20 tokens, borrow against them as collateral, and repay their loans.
 * @dev This contract does not handle interest rates or loan durations.
 */
contract AdvancedLending {
    ////////////
    // Errors //
    ////////////
    error InsufficientCollateral();
    error InsufficientTokensInContract();
    error CannotLiquidate();
    error InsufficientBalance();
    error RepayingTooMuch();

    ////////////
    // Events //
    ////////////
    event Deposited(address indexed user, uint256 amount);

    /////////////////////
    // State Variables //
    /////////////////////
    IERC20 public i_token;
    AggregatorV3Interface public i_priceFeed;

    mapping(address => uint256) public s_tokenBalances;
    mapping(address => uint256) public s_tokenBorrowed;
    mapping(address => uint256) public s_collateral;

    uint256 public constant COLLATERAL_FACTOR = 150; // 150%

    ///////////////
    // Functions //
    ///////////////

    /////////////////////////
    // External Functions //
    ////////////////////////
    /**
     * @param tokenAddress The address of the ERC20 token will be used for lending and borrowing.
     * @param priceFeedAddress The address of the chainlink price feed contract.
     */
    constructor(address tokenAddress, address priceFeedAddress) {
        i_token = IERC20(tokenAddress);
        i_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    /**
     * @notice Allows users to deposit tokens into the contract.
     * @param amount The amount of tokens to deposit.
     */
    function depositToken(uint256 amount) external {
        i_token.transferFrom(msg.sender, address(this), amount);
        s_tokenBalances[msg.sender] += amount;
    }

    /**
     * @notice Allows users to withdraw their tokens from the contract.
     * @param amount The amount of tokens to withdraw.
     * @dev Requires that the user has enough balance to withdraw.
     */
    function withdrawToken(uint256 amount) external {
        if (amount > s_tokenBalances[msg.sender]) revert InsufficientBalance();
        s_tokenBalances[msg.sender] -= amount;
        i_token.transfer(msg.sender, amount);
    }

    /**
     * @notice Allows users to borrow tokens by providing ETH as collateral.
     * @param tokenAmount The amount of tokens to borrow.
     * @dev Requires that the user provides enough ETH as collateral and that the contract has enough tokens to lend.
     */
    function borrowTokenWithCollateral(uint256 tokenAmount) external payable {
        if (msg.value < tokenAmount * COLLATERAL_FACTOR / 100) revert InsufficientCollateral();
        if (tokenAmount > i_token.balanceOf(address(this))) revert InsufficientTokensInContract();
        s_tokenBorrowed[msg.sender] += tokenAmount;
        s_collateral[msg.sender] += msg.value;
        i_token.transfer(msg.sender, tokenAmount);
    }

    /**
     * @notice Allows users to repay their borrowed tokens.
     * @param tokenAmount The amount of tokens to repay.
     * @dev Requires that the user has borrowed at least the amount they are trying to repay.
     */
    function repayToken(uint256 tokenAmount) external {
        if (tokenAmount > s_tokenBorrowed[msg.sender]) revert RepayingTooMuch();
        i_token.transferFrom(msg.sender, address(this), tokenAmount);
        s_tokenBorrowed[msg.sender] -= tokenAmount;
    }

    /**
     * @notice Allows for the liquidation of a borrower's collateral if they fail to maintain the required collateral factor.
     * @param borrower The address of the borrower.
     * @param tokenAmount The amount of tokens to be liquidated.
     * @dev Requires that the borrower's collateral is less than the required amount and that they have borrowed the specified token amount.
     */
    function liquidate(address borrower, uint256 tokenAmount) external {
        if (s_collateral[borrower] >= getRequiredCollateral(tokenAmount)) revert CannotLiquidate();
        if (tokenAmount > s_tokenBorrowed[borrower]) revert CannotLiquidate();
        s_tokenBorrowed[borrower] -= tokenAmount;
        i_token.transferFrom(msg.sender, address(this), tokenAmount);
        payable(msg.sender).transfer(s_collateral[borrower]);
        s_collateral[borrower] = 0;
    }

    ///////////////////////////////////////
    // Private & Internal veiw Functions //
    ///////////////////////////////////////
    function getChainlinkDataFeedLatestAnswer() private view returns (int256) {
        (, int256 price,,,) = i_priceFeed.latestRoundData();
        return price;
    }

    /////////////////////////////////////
    // Public & External View Functions //
    /////////////////////////////////////
    function getRequiredCollateral(uint256 tokenAmount) public view returns (uint256) {
        int256 price = getChainlinkDataFeedLatestAnswer();
        return tokenAmount * uint256(price) * COLLATERAL_FACTOR / 100;
    }
}
