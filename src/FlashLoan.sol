//SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "aaveV2/contracts/flashloan/base/FlashLoanReceiverBase.sol";
import "aaveV2/contracts/protocol/configuration/LendingPoolAddressesProviderRegistry.sol";
import "aaveV2/contracts/protocol/configuration/LendingPoolAddressesProvider.sol";
import "aaveV2/contracts/protocol/lendingpool/LendingPool.sol";
import "aaveV2/contracts/dependencies/openzeppelin/contracts/IERC20.sol";
import "aaveV2/contracts/dependencies/openzeppelin/contracts/SafeERC20.sol";
import "aaveV2/contracts/dependencies/openzeppelin/contracts/SafeMath.sol";

import "forge-std/console.sol";

contract FlashLoan is FlashLoanReceiverBase {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    LendingPoolAddressesProviderRegistry constant providerRegistry =
        LendingPoolAddressesProviderRegistry(0x52D306e36E3B6B02c153d0266ff0f85d18BCD413);

    address[] addressProvider = providerRegistry.getAddressesProvidersList();
    LendingPoolAddressesProvider provider = LendingPoolAddressesProvider(addressProvider[0]);
    LendingPool pool = LendingPool(provider.getLendingPool());

    constructor() public FlashLoanReceiverBase(provider) {}

    function getFlashLoan(address _asset, uint256 _amount) external {
        require(IERC20(_asset).balanceOf(address(this)) > 0, "bal should be more than 0");

        address[] memory assets = new address[](1);
        assets[0] = _asset;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = _amount;

        uint256[] memory modes = new uint256[](1);
        modes[0] = 0;

        bytes memory params = "";

        pool.flashLoan(address(this), assets, amounts, modes, address(this), params, 0);
    }

    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {
        for (uint256 i = 0; i < assets.length; i++) {
            console.log("borrowed: ", amounts[i] / 1e18);
            console.log("premium: ", premiums[i] / 1e18);
            console.log("balance: ", IERC20(assets[i]).balanceOf(address(this)) / 1e18);

            uint256 amountToPay = amounts[i].add(premiums[i]);
            IERC20(assets[i]).safeApprove(address(pool), amountToPay);
        }
        return true;
    }
}
