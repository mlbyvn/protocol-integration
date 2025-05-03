// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IERC20} from "../interfaces/IERC20.sol";
import {Pay} from "../../aave/Pay.sol";
import {Token} from "../../aave/Token.sol";
import {AaveHelper} from "../../aave/AaveHelper.sol";
import {SwapHelper} from "../../aave/SwapHelper.sol";

/**
 * @title AaveLeverage
 * @notice The contract interacts with Aave's flash loan, swap, and collateral management mechanisms. 
 * Allows for leveraged positions in Aave, enabling users to open and close positions with flash loans.
 * @dev Important:
 * 1. Need to delegatecall into this contract from Proxy
 * 2. One Proxy contract per open position
 */
contract AaveLeverage is Pay, Token, AaveHelper, SwapHelper {
    /*

    Steps to close a position
    -------------------------
    1. Flash loan stable coin
    2. Repay stable coin debt (open step 3)
    3. Withdraw collateral (open step 2)
    4. Swap collateral to stable coin
    5. Repay flash loan
    */

    /*//////////////////////////////////////////////////////////////
                            TYPE DEFINITIONS
    //////////////////////////////////////////////////////////////*/
    
    struct SwapParams {
        uint256 amountOutMin;
        bytes data;
    }

    struct FlashLoanData {
        address coin;
        address collateral;
        bool open;
        address caller;
        uint256 colAmount;
        SwapParams swap;
    }

    struct OpenParams {
        address coin;
        address collateral;
        uint256 colAmount;
        uint256 coinAmount;
        SwapParams swap;
        uint256 minHealthFactor;
    }

    struct CloseParams {
        address coin;
        address collateral;
        uint256 colAmount;
        SwapParams swap;
    }

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Open a leveraged position using a flash loan
     * Steps:
     * 1. Take a stablecoin flash loan
     * 2. Swap the coins for collateral
     * 3. Supply swapped collateral + base collateral
     * 4. Borrow stable coin and repay the loan
     * @param params Parameters for opening the position
     */
    function open(OpenParams calldata params) external {
        IERC20(params.collateral).transferFrom(
            msg.sender, address(this), params.colAmount
        );

        flashLoan({
            token: params.coin,
            amount: params.coinAmount,
            data: abi.encode(
                FlashLoanData({
                    coin: params.coin,
                    collateral: params.collateral,
                    open: true,
                    caller: msg.sender,
                    colAmount: params.colAmount,
                    swap: params.swap
                })
            )
        });

        require(
            getHealthFactor(address(this)) >= params.minHealthFactor, "hf < min"
        );
    }

    /**
     * @dev Close the leveraged position
     * Steps:
     * 1. Flash loan stable coin
     * 2. Repay stable coin debt (open step 3)
     * 3. Withdraw collateral (open step 2)
     * 4. Swap collateral to stable coin
     * 5. Repay flash loan
     * @param params 
     */
    function close(CloseParams calldata params) external {
        uint256 coinAmount = getDebt(address(this), params.coin);
        flashLoan({
            token: params.coin,
            amount: coinAmount,
            data: abi.encode(
                FlashLoanData({
                    coin: params.coin,
                    collateral: params.collateral,
                    open: false,
                    caller: msg.sender,
                    colAmount: params.colAmount,
                    swap: params.swap
                })
            )
        });
    }

    /**
     * @dev Get the maximum flash loan amount a user can borrow for
     * his collateral
     * @param collateral Collateral token address
     * @param baseColAmount Amount of collateral to use for the loan
     * @return max maximum flash loan amount in WAD
     * @return price Price of collateral token with 8 decimals
     * @return ltv  loan-to-value ratio
     * @return maxLev Maximum leverage factor
     */
    function getMaxFlashLoanAmountUsd(address collateral, uint256 baseColAmount)
        external
        view
        returns (uint256 max, uint256 price, uint256 ltv, uint256 maxLev)
    {
        uint256 decimals;
        (decimals, ltv,,,,,,,,) =
            dataProvider.getReserveConfigurationData(collateral);

        // 1e8 = 1 USD
        price = oracle.getAssetPrice(collateral);

        // Normalize baseColAmount to 18 decimals
        // LTV 100% = 1e4
        max = baseColAmount * 10 ** (18 - decimals) * price * ltv / (1e4 - ltv)
            / 1e8;

        maxLev = ltv * 1e4 / (1e4 - ltv);

        return (max, price, ltv, maxLev);
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Callback function for handling flash loans
     * @param token Address of borrowed token
     * @param amount Amount of borrowed token
     * @param fee Flash loan fee
     * @param params Flash loan parameters
     */
    function _flashLoanCallback(
        address token,
        uint256 amount,
        uint256 fee,
        bytes memory params
    ) internal override {
        uint256 repayAmount = amount + fee;

        FlashLoanData memory data = abi.decode(params, (FlashLoanData));
        IERC20 coin = IERC20(data.coin);
        IERC20 collateral = IERC20(data.collateral);

        if (data.open) {
            uint256 colAmountOut = swap({
                tokenIn: address(coin),
                tokenOut: address(collateral),
                amountIn: amount,
                amountOutMin: data.swap.amountOutMin,
                data: data.swap.data
            });

            uint256 colAmount = colAmountOut + data.colAmount;

            collateral.approve(address(pool), colAmount);
            supply(address(collateral), colAmount);

            borrow(address(coin), repayAmount);
        } else {
            coin.approve(address(pool), amount);
            repay(address(coin), amount);

            uint256 colWithdrawn =
                withdraw(address(collateral), type(uint256).max);
            uint256 colAmountIn = colWithdrawn - data.colAmount;

            collateral.transfer(data.caller, data.colAmount);

            uint256 coinAmountOut = swap({
                tokenIn: address(collateral),
                tokenOut: address(coin),
                amountIn: colAmountIn,
                amountOutMin: data.swap.amountOutMin,
                data: data.swap.data
            });

            if (coinAmountOut < repayAmount) {
                coin.transferFrom(
                    data.caller, address(this), repayAmount - coinAmountOut
                );
            } else {
                coin.transfer(data.caller, coinAmountOut - repayAmount);
            }
        }

        coin.approve(address(pool), repayAmount);
    }
}