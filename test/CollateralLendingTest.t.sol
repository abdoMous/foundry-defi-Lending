// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {DeployCollateralLending} from "../script/DeployCollateralLending.s.sol";
import {MyToken} from "../src/MyToken.sol";
import {CollateralLending} from "../src/CollateralLending.sol";

contract CollateralLendingTest is Test {
    DeployCollateralLending _deployCollateralLendingContract;
    MyToken _myToken;
    CollateralLending _collateralLending;

    uint256 public constant AMOUNT_COLLATERAL = 10;

    address public userAddress = makeAddr("user");
    address public borrower = makeAddr("borrower");
    address public liquidator = makeAddr("liquidator");

    function setUp() public {
        _deployCollateralLendingContract = new DeployCollateralLending();
        (_myToken, _collateralLending) = _deployCollateralLendingContract.run();
    }

    modifier depositedCollateral() {
        vm.startPrank(userAddress);
        _myToken.mint(address(userAddress), AMOUNT_COLLATERAL);
        _myToken.approve(address(_collateralLending), AMOUNT_COLLATERAL);
        _collateralLending.depositToken(AMOUNT_COLLATERAL);
        vm.stopPrank();
        _;
    }

    function testDepositToken() public depositedCollateral {
        assertEq(_myToken.balanceOf(address(_collateralLending)), AMOUNT_COLLATERAL);
    }

    //////////////////////////////////////
    // borrowTokenWithCollateral Tests //
    ////////////////////////////////////

    function testRevertsIfUserDoesNetHaveEnoghCollateral() public depositedCollateral {
        vm.startPrank(userAddress);
        vm.expectRevert("Insufficient collateral");
        _collateralLending.borrowTokenWithCollateral(AMOUNT_COLLATERAL);
        vm.stopPrank();
    }

    function testRevertsIfContractsDoesNotHaveEnoughFunds() public {
        vm.startPrank(borrower);
        vm.deal(borrower, AMOUNT_COLLATERAL * 2);

        vm.expectRevert("Insufficient funds");
        _collateralLending.borrowTokenWithCollateral{value: AMOUNT_COLLATERAL * 2}(AMOUNT_COLLATERAL);

        vm.stopPrank();
    }

    function testBorrowingGetRecorded() public depositedCollateral {
        vm.startPrank(borrower);
        vm.deal(borrower, AMOUNT_COLLATERAL * 2);

        _collateralLending.borrowTokenWithCollateral{value: AMOUNT_COLLATERAL * 2}(AMOUNT_COLLATERAL);

        assertEq(_collateralLending.s_borrowed(borrower), AMOUNT_COLLATERAL);
        vm.stopPrank();
    }

    function testBorrowingTransfersTokens() public depositedCollateral {
        vm.startPrank(borrower);
        vm.deal(borrower, AMOUNT_COLLATERAL * 2);

        _collateralLending.borrowTokenWithCollateral{value: AMOUNT_COLLATERAL * 2}(AMOUNT_COLLATERAL);

        assertEq(_myToken.balanceOf(borrower), AMOUNT_COLLATERAL);
        vm.stopPrank();
    }

    //////////////////////
    // repayToken Tests //
    //////////////////////

    function testRepayingTooMuchReverts() public depositedCollateral {
        vm.startPrank(userAddress);
        vm.expectRevert("Repaying too much");
        _collateralLending.repayToken(AMOUNT_COLLATERAL * 2);
        vm.stopPrank();
    }

    function testRepayingUpdatesBorrowed() public depositedCollateral {
        vm.startPrank(borrower);
        vm.deal(borrower, AMOUNT_COLLATERAL * 150 / 100);

        _collateralLending.borrowTokenWithCollateral{value: AMOUNT_COLLATERAL * 150 / 100}(AMOUNT_COLLATERAL);
        _myToken.approve(address(_collateralLending), AMOUNT_COLLATERAL);
        _collateralLending.repayToken(AMOUNT_COLLATERAL);

        assertEq(_collateralLending.s_borrowed(borrower), 0);
        assertEq(_myToken.balanceOf(borrower), 0);

        assertEq(borrower.balance, AMOUNT_COLLATERAL * 150 / 100);

        vm.stopPrank();
    }
}
