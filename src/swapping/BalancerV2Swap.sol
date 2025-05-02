// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IRETH} from "../interfaces/rocket-pool/IRETH.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {IVault} from "../interfaces/balancer/IVault.sol";

/**
 * @title BalancerV2Swap
 * @notice Facilitates swapping between ETH and rETH using Balancer
 */
contract BalancerV2Swap {

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    IRETH private immutable i_rEth;
    IERC20 private immutable i_wEth;
    IVault private immutable i_vault;

    bytes32 constant BALANCER_POOL_ID_RETH_WETH = 0x1e19cf2d73a72ef1332c882f20534b6519be0276000200000000000000000112;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(address _reth, address _weth, address _vault) {
        i_rEth = IRETH(_reth);
        i_wEth = IERC20(_weth);
        i_vault = IVault(_vault);
    }

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/   

    /**
     * @dev Swaps wETH to rETH
     * @param wethAmountIn wETH input amount 
     * @param rEthAmountOutMin Minimal rETH amount a user wants to acquire
     */ 
    function swapWethToReth(uint256 wethAmountIn, uint256 rEthAmountOutMin)
        external
    {
        i_wEth.transferFrom(msg.sender, address(this), wethAmountIn);
        i_wEth.approve(address(i_vault), wethAmountIn);
        swap(
            address(i_wEth),
            address(i_rEth),
            wethAmountIn,
            rEthAmountOutMin,
            BALANCER_POOL_ID_RETH_WETH
        );
    }

    /**
     * @dev Swaps rETH for wETH 
     * @param rEthAmountIn rETH input amount 
     * @param wethAmountOutMin Minimal wETH amount a user wants to acquire
     */
    function swapRethToWeth(uint256 rEthAmountIn, uint256 wethAmountOutMin)
        external
    {
        i_rEth.transferFrom(msg.sender, address(this), rEthAmountIn);
        i_rEth.approve(address(i_vault), rEthAmountIn);
        swap(
            address(i_rEth),
            address(i_wEth),
            rEthAmountIn,
            wethAmountOutMin,
            BALANCER_POOL_ID_RETH_WETH
        );
    }

    /*//////////////////////////////////////////////////////////////
                           PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Implements swapping logic
     * @param tokenIn Input token address
     * @param tokenOut Output token address
     * @param amountIn Input amount
     * @param amountOutMin Minimal output amount
     * @param poolId ID of the pool
     */
    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        bytes32 poolId
    ) private returns (uint256 amountOut) {
        return i_vault.swap({
            singleSwap: IVault.SingleSwap({
                poolId: poolId,
                kind: IVault.SwapKind.GIVEN_IN,
                assetIn: tokenIn,
                assetOut: tokenOut,
                amount: amountIn,
                userData: ""
            }),
            funds: IVault.FundManagement({
                sender: address(this),
                fromInternalBalance: false,
                recipient: address(this),
                toInternalBalance: false
            }),
            limit: amountOutMin,
            deadline: block.timestamp
        });
    }
}