// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {Test, console} from "forge-std/Test.sol";
import {AaveV2} from "../src/AaveV2.sol";

import "aaveV2/contracts/protocol/lendingpool/LendingPool.sol";

import "aaveV2/contracts/dependencies/openzeppelin/contracts/IERC20.sol";
import "aaveV2/contracts/dependencies/openzeppelin/contracts/SafeERC20.sol";
import "aaveV2/contracts/interfaces/ICreditDelegationToken.sol";

contract AaveV2Test is Test {
    using SafeERC20 for IERC20;

    AaveV2 public aaveV2;

    IERC20 constant DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    // IERC20 constant DAI = IERC20(0x0D8775F648430679A709E98d2b0Cb6250d2887EF);
    address user = vm.addr(1);

    function setUp() public {
        aaveV2 = new AaveV2();
    }

    function testGetProviderAddresses() public view {
        console.log("provider: ", address(aaveV2.provider()));
    }

    function testGetLendingPool() public view {
        console.log("pool: ", address(aaveV2.pool()));
    }

    function testDeposit() public {
        uint256 amount = 10000 * 1e18;
        deal(address(DAI), user, amount, true);
        vm.startPrank(user);
        assertEq(DAI.balanceOf(user), amount);

        DAI.safeApprove(address(aaveV2), amount);
        aaveV2.deposit(address(DAI), amount, user);
        vm.stopPrank();
    }

    function testGetUserAccountData() public {
        vm.startPrank(user);
        testDeposit();
        aaveV2.getUserAccountData(user);
        vm.stopPrank();
    }

    function testGetReserveData() public {
        vm.startPrank(user);
        testDeposit();
        aaveV2.getReserveData(address(DAI));
        vm.stopPrank();
    }

    function testWithdraw() public {
        testDeposit();
        vm.startPrank(user);

        (address aToken,) = aaveV2.getReserveData(address(DAI));
        uint256 aTokenBalance = IERC20(aToken).balanceOf(user);
        console.log("aToken user: ", aTokenBalance);
        console.log("DAI user: ", DAI.balanceOf(user));

        IERC20(aToken).safeApprove(address(aaveV2), aTokenBalance);
        aaveV2.withdraw(address(DAI), aToken, aTokenBalance, type(uint256).max, user);

        console.log("aToken user: ", IERC20(aToken).balanceOf(user));
        console.log("DAI user: ", DAI.balanceOf(user));
        vm.stopPrank();
    }

    function testBorrow() public {
        uint256 amountDeposited = 10000 * 1e18;
        testDeposit();
        console.log("******borrow*******");

        uint256 debtToken = 50 * 1e18;

        vm.startPrank(user);
        (address aToken, address variableDebtTokenAddress) = aaveV2.getReserveData(address(DAI));
        assertEq(IERC20(aToken).balanceOf(user), amountDeposited);
        assertEq(IERC20(variableDebtTokenAddress).balanceOf(user), 0);

        (,, uint256 totalDebtETH) = aaveV2.getUserAccountData(user);
        console.log("initital totalDebtETH: ", totalDebtETH);

        ICreditDelegationToken(variableDebtTokenAddress).approveDelegation(address(aaveV2), debtToken);
        assertEq(ICreditDelegationToken(variableDebtTokenAddress).borrowAllowance(user, address(aaveV2)), debtToken);

        aaveV2.borrow(address(DAI), debtToken, user);

        assertEq(IERC20(aToken).balanceOf(user), amountDeposited);

        (,, uint256 totalDebtETH_) = aaveV2.getUserAccountData(user);
        console.log("final totalDebtETH: ", totalDebtETH_);

        assertEq(IERC20(variableDebtTokenAddress).balanceOf(user), debtToken);
        assertEq(DAI.balanceOf(address(aaveV2)), debtToken);

        vm.stopPrank();
    }

    function testRepay() public {
        testBorrow();

        console.log("******repayment*******");
        uint256 debtAmount = 50 * 1e18;
        uint256 repayAmount = 51 * 1e18;
        vm.startPrank(user);
        (, address variableDebtTokenAddress) = aaveV2.getReserveData(address(DAI));

        (,, uint256 totalDebtETH) = aaveV2.getUserAccountData(user);
        console.log("inital totalDebtETH: ", totalDebtETH);

        assertEq(IERC20(variableDebtTokenAddress).balanceOf(user), debtAmount);
        aaveV2.repay(address(DAI), repayAmount, user);

        (,, uint256 totalDebtETH_) = aaveV2.getUserAccountData(user);
        console.log("final totalDebtETH: ", totalDebtETH_);
        assertEq(IERC20(variableDebtTokenAddress).balanceOf(user), 0);

        vm.stopPrank();
    }
}
