// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {Test, console} from "forge-std/Test.sol";
import {AaveV2} from "../src/AaveV2.sol";

import "aaveV2/contracts/protocol/lendingpool/LendingPool.sol";

import "aaveV2/contracts/dependencies/openzeppelin/contracts/IERC20.sol";
import "aaveV2/contracts/dependencies/openzeppelin/contracts/SafeERC20.sol";

contract AaveV2Test is Test {
    using SafeERC20 for IERC20;

    AaveV2 public aaveV2;

    IERC20 constant DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IERC20 constant CRV = IERC20(0xD533a949740bb3306d119CC777fa900bA034cd52);
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

        (address aToken,,) = aaveV2.getReserveData(address(DAI));
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
        // testDeposit();

        uint256 amount = 10000 * 1e18;
        deal(address(DAI), user, amount, true);

        vm.startPrank(user);
        assertEq(DAI.balanceOf(user), amount);
        DAI.safeApprove(address(aaveV2), amount);
        aaveV2.deposit(address(DAI), amount, user); //deposit

        uint256 amountCRV = 500;

        (address aToken, address stableDebtTokenAddress, address variableDebtTokenAddress) =
            aaveV2.getReserveData(address(DAI));
        
        console.log("stableDebtTokenAddress: ",stableDebtTokenAddress);
        console.log("variableDebtTokenAddress: ",variableDebtTokenAddress);

        uint256 aTokenBalance = IERC20(aToken).balanceOf(user);
        console.log("aToken user: ", aTokenBalance);

        (uint256 totalCollateralETH, uint256 availableBorrowsETH, uint256 totalDebtETH) =
            aaveV2.getUserAccountData(user);
        console.log("totalCollateralETH: ", totalCollateralETH / 1e18);
        console.log("availableBorrowsETH: ", availableBorrowsETH / 1e18);
        console.log("totalDebtETH: ", totalDebtETH / 1e18);

        aaveV2.approveDelegation(stableDebtTokenAddress, variableDebtTokenAddress, amountCRV, user);

        // IERC20(aToken).safeApprove(address(aaveV2), aTokenBalance);
        // IERC20(aToken).safeApprove(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5, aTokenBalance);

        // aaveV2.borrow(
        //     // aToken, aTokenBalance,
        //     address(DAI),
        //     amountCRV,
        //     user
        // );

        vm.stopPrank();
    }
}
