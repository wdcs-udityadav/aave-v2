// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {Test, console} from "forge-std/Test.sol";
import {FlashLoan} from "../src/FlashLoan.sol";

import "aaveV2/contracts/dependencies/openzeppelin/contracts/IERC20.sol";
import "aaveV2/contracts/dependencies/openzeppelin/contracts/SafeERC20.sol";

contract FlashLoanTest is Test {
    using SafeERC20 for IERC20;

    FlashLoan public flashLoan;

    IERC20 constant DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    address user = vm.addr(1);

    function setUp() public {
        flashLoan = new FlashLoan();
    }

    function testGetFlashLoan() public {
        uint256 amount = 10000 * 1e18;
        deal(address(DAI), user, amount, true);
        vm.startPrank(user);
        assertEq(DAI.balanceOf(user), amount);

        DAI.safeTransfer(address(flashLoan), amount);
        assertEq(DAI.balanceOf(address(flashLoan)), amount);

        console.log("initial balance: ", DAI.balanceOf(address(flashLoan)) / 1e18);
        flashLoan.getFlashLoan(address(DAI), 10000 * 1e18);

        vm.stopPrank();
    }
}
