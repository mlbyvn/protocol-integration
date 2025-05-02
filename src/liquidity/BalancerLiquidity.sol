// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IERC20} from "../interfaces/IERC20.sol";
import {IRETH} from "../interfaces/rocket-pool/IRETH.sol";
import {IVault} from "../interfaces/balancer/IVault.sol";

/**
 * @title BalancerLiquidity
 * @notice Provides functionality to deposit and withdraw liquidity from Balancer pools
 */
contract BalancerLiquidity {

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/    
    IRETH private immutable i_rEth;
    IERC20 private immutable i_wEth;
    IVault private immutable i_vault;
    IERC20 private immutable i_balancerPoolToken;

    bytes32 private constant BALANCER_POOL_ID_RETH_WETH = 0x1e19cf2d73a72ef1332c882f20534b6519be0276000200000000000000000112;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _reth, address _weth, address _vault, address _bpt) {
        i_rEth = IRETH(_reth);
        i_wEth = IERC20(_weth);
        i_vault = IVault(_vault);
        i_balancerPoolToken = IERC20(_bpt);
    }

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * Deposit rETH or/and wETH into Balancer pool
     * @param rethAmount Amount of rETH to deposit
     * @param wethAmount Amount of wETH to deposit
     */
    function join(uint256 rethAmount, uint256 wethAmount) external {
        if (rethAmount > 0) {
            i_rEth.transferFrom(msg.sender, address(this), rethAmount);
            i_rEth.approve(address(i_vault), rethAmount);
        }
        if (wethAmount > 0) {
            i_wEth.transferFrom(msg.sender, address(this), wethAmount);
            i_wEth.approve(address(i_vault), wethAmount);
        }

        // Tokens must be ordered numerically by token address
        address[] memory assets = new address[](2);
        assets[0] = address(i_rEth);
        assets[1] = address(i_wEth);

        // Single sided or both liquidity is possible
        uint256[] memory maxAmountsIn = new uint256[](2);
        maxAmountsIn[0] = rethAmount;
        maxAmountsIn[1] = wethAmount;

        _join(msg.sender, assets, maxAmountsIn);

        uint256 rethBal = i_rEth.balanceOf(address(this));
        if (rethBal > 0) {
            i_rEth.transfer(msg.sender, rethBal);
        }

        uint256 wethBal = i_wEth.balanceOf(address(this));
        if (wethBal > 0) {
            i_wEth.transfer(msg.sender, wethBal);
        }
    }

    /**
     * Withdraw rETH and/or wETH from Balancer pool
     * @param bptAmount AMount of balancer pool token to burn
     * @param minRethAmountOut Minimum output amount in rETH
     */
    function exit(uint256 bptAmount, uint256 minRethAmountOut) external {
        i_balancerPoolToken.transferFrom(msg.sender, address(this), bptAmount);

        // Tokens must be ordered numerically by token address
        address[] memory assets = new address[](2);
        assets[0] = address(i_rEth);
        assets[1] = address(i_wEth);

        // Both single and all tokens are possible
        uint256[] memory minAmountsOut = new uint256[](2);
        minAmountsOut[0] = minRethAmountOut;
        minAmountsOut[1] = 0;

        _exit(bptAmount, msg.sender, assets, minAmountsOut);
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/    

    /**
     * Join function logic
     * @param recipient Receiver address
     * @param assets Array of token addresses
     * @param maxAmountsIn Maximum deposit amount of each token
     */
    function _join(
        address recipient,
        address[] memory assets,
        uint256[] memory maxAmountsIn
    ) internal {
        i_vault.joinPool({
            poolId: BALANCER_POOL_ID_RETH_WETH,
            sender: address(this),
            recipient: recipient,
            request: IVault.JoinPoolRequest({
                assets: assets,
                maxAmountsIn: maxAmountsIn,
                // EXACT_TOKENS_IN_FOR_BPT_OUT, amounts, min BPT
                userData: abi.encode(
                    IVault.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT,
                    maxAmountsIn,
                    uint256(1)
                ),
                fromInternalBalance: false
            })
        });
    }

    /**
     * Exit function logic
     * @param bptAmount Amount of balancer pool token to burn
     * @param recipient Receiver address
     * @param assets Token addresses
     * @param minAmountsOut Minimal withdrawal amount for each token
     */
    function _exit(
        uint256 bptAmount,
        address recipient,
        address[] memory assets,
        uint256[] memory minAmountsOut
    ) internal {
        i_vault.exitPool({
            poolId: BALANCER_POOL_ID_RETH_WETH,
            sender: address(this),
            recipient: recipient,
            request: IVault.ExitPoolRequest({
                assets: assets,
                minAmountsOut: minAmountsOut,
                // EXACT_BPT_IN_FOR_ONE_TOKEN_OUT, BPT amount, index of token to withdraw
                userData: abi.encode(
                    IVault.ExitKind.EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
                    bptAmount,
                    // RETH
                    uint256(0)
                ),
                toInternalBalance: false
            })
        });
    }
}