// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IRETH} from "../interfaces/rocket-pool/IRETH.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {ISwapRouter} from "../interfaces/uniswap/ISwapRouter.sol";

/**
 * @title UniswapV3Swap
 * @notice Facilitates swapping between wETH and rETH using Uniswap V3
 */
contract UniswapV3Swap {

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    IRETH private immutable i_rEth;
    IERC20 private immutable i_wEth;
    ISwapRouter private immutable i_router;

    uint24 private constant UNISWAP_V3_POOL_FEE_RETH_WETH = 100;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(address _reth, address _weth, address _router) {
        i_rEth = IRETH(_reth);
        i_wEth = IERC20(_weth);
        i_router = ISwapRouter(_router);
    }

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * Swaps wETH for rETH
     * @param wethAmountIn Input wETH amount
     * @param rEthAmountOutMin Minimal output rETH Amount
     */
    function swapWethToReth(uint256 wethAmountIn, uint256 rEthAmountOutMin)
        external
    {
        i_wEth.transferFrom(msg.sender, address(this), wethAmountIn);
        i_wEth.approve(address(i_router), wethAmountIn);
        _swap(
            address(i_wEth),
            address(i_rEth),
            UNISWAP_V3_POOL_FEE_RETH_WETH,
            wethAmountIn,
            rEthAmountOutMin,
            address(this)
        );
    }

    /**
     * Swaps rETH for wETH
     * @param rEthAmountIn Input rETH amount
     * @param wethAmountOutMin Output wETH amount
     */
    function swapRethToWeth(uint256 rEthAmountIn, uint256 wethAmountOutMin)
        external
    {
        i_rEth.transferFrom(msg.sender, address(this), rEthAmountIn);
        i_rEth.approve(address(i_router), rEthAmountIn);
        _swap(
            address(i_rEth),
            address(i_wEth),
            UNISWAP_V3_POOL_FEE_RETH_WETH,
            rEthAmountIn,
            wethAmountOutMin,
            address(this)
        );
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * Swappping logic is implemented here
     * @param tokenIn Input token address
     * @param tokenOut Output token address
     * @param fee Exchange fee
     * @param amountIn Input token amount
     * @param amountOutMin Minimal output token amount
     * @param receiver Receiver address
     */
    function _swap(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint256 amountOutMin,
        address receiver
    ) private returns (uint256 amountOut) {
        return i_router.exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: fee,
                recipient: receiver,
                amountIn: amountIn,
                amountOutMinimum: amountOutMin,
                sqrtPriceLimitX96: 0
            })
        );
    }
}