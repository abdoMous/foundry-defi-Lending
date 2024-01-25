// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {DeployAdvancedLending} from "../script/DeployAdvancedLending.s.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";
import {MyToken} from "../src/MyToken.sol";
import {AdvancedLending} from "../src/AdvancedLending.sol";

contract AdvancedLendingTest is Test {
    DeployAdvancedLending _deployAdvancedLendingContract;
    MockV3Aggregator _priceFeed;
    MyToken _myToken;
    AdvancedLending _advancedLending;

    address public depositor = makeAddr("depositor");
    address public borrower = makeAddr("borrower");
    address public liquidator = makeAddr("liquidator");

    function setUp() public {
        _deployAdvancedLendingContract = new DeployAdvancedLending();
        (_myToken, _priceFeed, _advancedLending) = _deployAdvancedLendingContract.run();
    }

    // == DepositToken Tests ==

    modifier depositToken(uint256 amount) {
        vm.startPrank(depositor);
        _myToken.mint(address(depositor), amount);
        _myToken.approve(address(_advancedLending), amount);
        _advancedLending.depositToken(amount);
        vm.stopPrank();
        _;
    }

    function testDepositToken() public depositToken(100) {
        assertEq(_myToken.balanceOf(address(_advancedLending)), 100);
        assertEq(_advancedLending.s_tokenBalances(address(depositor)), 100);
    }

    // == WithdrawToken Tests ==

    function testRevertsIfUserDoesNotHaveEnoughTokens() public {
        vm.startPrank(depositor);
        vm.expectRevert(AdvancedLending.InsufficientBalance.selector);
        _advancedLending.withdrawToken(100);
        vm.stopPrank();
    }

    function testWithdrawToken() public depositToken(100) {
        vm.startPrank(depositor);
        _advancedLending.withdrawToken(100);
        assertEq(_myToken.balanceOf(address(_advancedLending)), 0);
        assertEq(_advancedLending.s_tokenBalances(address(depositor)), 0);
        vm.stopPrank();
    }

    // == borrowTokenWithCollateral Tests ==

    function testRevertsIfUserDepositIsNotEnough() public depositToken(100) {
        vm.startPrank(borrower);
        vm.deal(borrower, 100);
        vm.expectRevert(AdvancedLending.InsufficientCollateral.selector);
        _advancedLending.borrowTokenWithCollateral{value: 100}(100);
        vm.stopPrank();
    }

    function testRevertsIfNotEnouphTokensInContract() public {
        vm.startPrank(borrower);
        vm.deal(borrower, 150);
        vm.expectRevert(AdvancedLending.InsufficientTokensInContract.selector);
        _advancedLending.borrowTokenWithCollateral{value: 150}(100);
        vm.stopPrank();
    }

    function testBorrowTokenWithCollateral() public depositToken(100) {
        vm.startPrank(borrower);
        vm.deal(borrower, 150);
        _advancedLending.borrowTokenWithCollateral{value: 150}(100);
        assertEq(_myToken.balanceOf(address(_advancedLending)), 0);
        assertEq(_advancedLending.s_tokenBorrowed(address(borrower)), 100);
        assertEq(_advancedLending.s_collateral(address(borrower)), 150);
        assertEq(_myToken.balanceOf(address(borrower)), 100);
        vm.stopPrank();
    }

    // == repayToken Tests ==
    function testRevertIfBorrowerRepayTooMuch() public depositToken(100) {
        vm.startPrank(borrower);
        vm.deal(borrower, 150);
        _advancedLending.borrowTokenWithCollateral{value: 150}(100);

        vm.expectRevert(AdvancedLending.RepayingTooMuch.selector);
        _advancedLending.repayToken(150);
        vm.stopPrank();
    }

    function testRepayToken() public depositToken(100) {
        vm.startPrank(borrower);
        vm.deal(borrower, 150);
        _advancedLending.borrowTokenWithCollateral{value: 150}(100);

        _myToken.approve(address(_advancedLending), 50);
        _advancedLending.repayToken(50);
        assertEq(_advancedLending.s_tokenBorrowed(address(borrower)), 50);
        assertEq(_myToken.balanceOf(address(_advancedLending)), 50);
        vm.stopPrank();
    }

    // == liquidate Tests ==
    function testDontLiquidateIfBorrowerHasEnoughCollateral() public depositToken(100) {
        vm.startPrank(borrower);
        vm.deal(borrower, 300);
        _advancedLending.borrowTokenWithCollateral{value: 300}(100);
        vm.stopPrank();

        vm.startPrank(liquidator);
        vm.deal(liquidator, 300);
        vm.expectRevert(AdvancedLending.CannotLiquidate.selector);
        _advancedLending.liquidate(borrower, 100);

        vm.stopPrank();
    }

    function testDontLiquidateIfLiquidatorSendMoreThenRequired() public depositToken(100) {
        vm.startPrank(borrower);
        vm.deal(borrower, 300);
        _advancedLending.borrowTokenWithCollateral{value: 300}(100);
        vm.stopPrank();

        _priceFeed.updateAnswer(1);

        vm.startPrank(liquidator);
        vm.deal(liquidator, 450);
        _myToken.mint(address(liquidator), 150);
        _myToken.approve(address(_advancedLending), 150);
        vm.expectRevert(AdvancedLending.CannotLiquidate.selector);
        _advancedLending.liquidate(borrower, 150);

        vm.stopPrank();
    }

    function testLiquidate() public depositToken(100) {
        vm.startPrank(borrower);
        vm.deal(borrower, 300);
        _advancedLending.borrowTokenWithCollateral{value: 300}(100);
        vm.stopPrank();

        console.log("required collateral", _advancedLending.getRequiredCollateral(100)); // 300
        _priceFeed.updateAnswer(3);
        console.log("required collateral", _advancedLending.getRequiredCollateral(100)); // 450

        vm.startPrank(liquidator);
        uint256 amountToLiquidate = 100;
        _myToken.mint(address(liquidator), amountToLiquidate);
        _myToken.approve(address(_advancedLending), amountToLiquidate);
        _advancedLending.liquidate(borrower, amountToLiquidate);

        assertEq(_advancedLending.s_tokenBorrowed(address(borrower)), 0);
        assertEq(_advancedLending.s_collateral(address(borrower)), 0);
        assertEq(_myToken.balanceOf(address(_advancedLending)), amountToLiquidate);
        vm.stopPrank();
    }

    // == getRequiredCollateral Tests ==

    function testGetRequiredCollateral() public {
        assertEq(_advancedLending.getRequiredCollateral(100), 300);
        _priceFeed.updateAnswer(1);
        assertEq(_advancedLending.getRequiredCollateral(100), 150);
        _priceFeed.updateAnswer(3);
        assertEq(_advancedLending.getRequiredCollateral(100), 450);
    }
}
