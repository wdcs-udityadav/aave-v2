//SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "aaveV2/contracts/protocol/configuration/LendingPoolAddressesProviderRegistry.sol";
import "aaveV2/contracts/protocol/configuration/LendingPoolAddressesProvider.sol";
import "aaveV2/contracts/protocol/lendingpool/LendingPool.sol";
import "aaveV2/contracts/dependencies/openzeppelin/contracts/IERC20.sol";
import "aaveV2/contracts/dependencies/openzeppelin/contracts/SafeERC20.sol";
import {DataTypes} from "aaveV2/contracts/protocol/libraries/types/DataTypes.sol";
import "aaveV2/contracts/interfaces/ICreditDelegationToken.sol";

import "forge-std/console.sol";

contract AaveV2 {
    using SafeERC20 for IERC20;

    LendingPoolAddressesProviderRegistry constant providerRegistry =
        LendingPoolAddressesProviderRegistry(0x52D306e36E3B6B02c153d0266ff0f85d18BCD413);

    LendingPoolAddressesProvider public provider;
    LendingPool public immutable pool;

    constructor() public {
        address[] memory addressProvider = providerRegistry.getAddressesProvidersList();
        provider = LendingPoolAddressesProvider(addressProvider[0]);
        pool = LendingPool(provider.getLendingPool());
    }

    function deposit(address _asset, uint256 _amount, address _behalfOf) external {
        uint16 refCode = 0;
        IERC20(_asset).safeTransferFrom(_behalfOf, address(this), _amount);
        IERC20(_asset).safeApprove(address(pool), _amount);
        pool.deposit(_asset, _amount, _behalfOf, refCode);
    }

    function getUserAccountData(address _user) external view returns (uint256, uint256, uint256, uint256) {
        (uint256 totalCollateralETH, uint256 totalDebtETH, uint256 availableBorrowsETH,,, uint256 healthFactor) =
            pool.getUserAccountData(_user);
        return (totalCollateralETH, availableBorrowsETH, totalDebtETH, healthFactor);
    }

    function getReserveData(address _asset) public view returns (address, address) {
        DataTypes.ReserveData memory reserveData = pool.getReserveData(_asset);
        return (reserveData.aTokenAddress, reserveData.variableDebtTokenAddress);
    }

    function withdraw(address _asset, address _aToken, uint256 _aTokenBalance, uint256 _amount, address _to) external {
        IERC20(_aToken).safeTransferFrom(_to, address(this), _aTokenBalance);
        IERC20(_aToken).safeApprove(address(pool), _aTokenBalance);

        pool.withdraw(_asset, _amount, _to);
    }

    function approveDelegation(address variableDebtTokenAddress, uint256 amount, address user) external {
        ICreditDelegationToken(variableDebtTokenAddress).approveDelegation(address(this), amount);

        uint256 allowance = ICreditDelegationToken(variableDebtTokenAddress).borrowAllowance(user, address(this));
        console.log("allowance:", allowance);
    }

    function borrow(address _asset, uint256 _amount, address _behalfOf) external {
        uint256 interestRateMode = 2;
        uint16 refCode = 0;

        pool.borrow(_asset, _amount, interestRateMode, refCode, _behalfOf);
    }

    function repay(address _asset, uint256 _amount, address _behalfOf) external {
        uint256 rateMode = 2;
        IERC20(_asset).safeApprove(address(pool), _amount);
        pool.repay(_asset, _amount, rateMode, _behalfOf);
    }

    function liquidationCall(address _collateralAsset, address _debtAsset, address _user) external {
        uint256 _debtToCover = uint256(-1);
        bool _receiveAToken = false;
        pool.liquidationCall(_collateralAsset, _debtAsset, _user, _debtToCover, _receiveAToken);
    }
}
