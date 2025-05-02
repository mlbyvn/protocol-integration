// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IERC20} from "../interfaces/IERC20.sol";
import {IRETH} from "../interfaces/rocket-pool/IRETH.sol";
import {IVault} from "../interfaces/balancer/IVault.sol";
import {IRewardPoolDepositWrapper} from "../interfaces/aura/IRewardPoolDepositWrapper.sol";
import {IBaseRewardPool4626} from "../interfaces/aura/IBaseRewardPool4626.sol";

/**
 * @title AuraLiquidity
 * @notice Facilitates depositing liquidity to Balancer through Aura protocol
 * How Aura automates the process:
 * 1. Balancer pool token is staked in Aura
 * 2. Aura claims the BAL rewards 
 * 3. Aura locks BAL in the voting escrow contract of Balancer protocol
 * 4. User receives boost in rewards on Balancer
 */
contract AuraLiquidity {

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error AuraLiquidity__OnlyOwner();

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    bytes32 private constant BALANCER_POOL_ID_RETH_WETH = 0x1e19cf2d73a72ef1332c882f20534b6519be0276000200000000000000000112;

    IRETH private immutable i_rEth;
    IERC20 private immutable i_wEth;
    IERC20 private immutable i_bal;
    IERC20 private immutable i_aura;
    IVault private immutable i_vault;
    IERC20 private immutable i_bpt;
    IRewardPoolDepositWrapper private immutable i_depositWrapper;
    IBaseRewardPool4626 private immutable i_rewardPool;

    address public owner;

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/
    modifier onlyOwner() {
        if (msg.sender != owner){
            revert AuraLiquidity__OnlyOwner();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(
        address _reth,
        address _weth,
        address _bal,
        address _aura,
        address _vault,
        address _bpt,
        address _depositWrapper,
        address _rewardPool
    ) {
        owner = msg.sender;
        i_rEth = IRETH(_reth);
        i_wEth = IERC20(_weth);
        i_bal = IERC20(_bal);
        i_aura = IERC20(_aura);
        i_vault = IVault(_vault);
        i_bpt = IERC20(_bpt);
        i_depositWrapper = IRewardPoolDepositWrapper(_depositWrapper);
        i_rewardPool = IBaseRewardPool4626(_rewardPool);
    }

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Deposit RETH into the Balancer liquidity pool through Aura
     * @param rethAmount Amount of rETH to deposit
     * @return shares Number of shares
     */
    function deposit(uint256 rethAmount) external returns (uint256 shares) {
        i_rEth.transferFrom(msg.sender, address(this), rethAmount);
        i_rEth.approve(address(i_depositWrapper), rethAmount);

        // Tokens must be ordered numerically by token address
        address[] memory assets = new address[](2);
        assets[0] = address(i_rEth);
        assets[1] = address(i_wEth);

        uint256[] memory maxAmountsIn = new uint256[](2);
        maxAmountsIn[0] = rethAmount;
        maxAmountsIn[1] = 0;

        i_depositWrapper.depositSingle({
            rewardPool: address(i_rewardPool),
            inputToken: address(i_rEth),
            inputAmount: rethAmount,
            balancerPoolId: BALANCER_POOL_ID_RETH_WETH,
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

        uint256 rethBal = i_rEth.balanceOf(address(this));
        if (rethBal > 0) {
            i_rEth.transfer(msg.sender, rethBal);
        }

        shares = i_rewardPool.balanceOf(address(this));
    }

    /**
     * Withdraw liquidity and claim rewards from the Aura protocol
     * @param shares Amount of shares to burn
     * @param minRethAmountOut Minimal rETH output amount
     */
    function exit(uint256 shares, uint256 minRethAmountOut) external onlyOwner {
        // Withdraw, unwrap and claim rewards
        require(i_rewardPool.withdrawAndUnwrap(shares, true), "withdraw failed");

        uint256 bptBal = i_bpt.balanceOf(address(this));

        // Tokens must be ordered numerically by token address
        address[] memory assets = new address[](2);
        assets[0] = address(i_rEth);
        assets[1] = address(i_wEth);

        uint256[] memory minAmountsOut = new uint256[](2);
        minAmountsOut[0] = minRethAmountOut;
        minAmountsOut[1] = 0;

        i_vault.exitPool({
            poolId: BALANCER_POOL_ID_RETH_WETH,
            sender: address(this),
            recipient: msg.sender,
            request: IVault.ExitPoolRequest({
                assets: assets,
                minAmountsOut: minAmountsOut,
                // EXACT_BPT_IN_FOR_ONE_TOKEN_OUT, BPT amount, index of token to withdraw
                userData: abi.encode(
                    IVault.ExitKind.EXACT_BPT_IN_FOR_ONE_TOKEN_OUT, bptBal, uint256(0)
                ),
                toInternalBalance: false
            })
        });
    }

    /**
     * @dev Transfer a specific token 
     * @param token Token address
     * @param dst Receiver address
     */
    function transfer(address token, address dst) external onlyOwner {
        IERC20(token).transfer(dst, IERC20(token).balanceOf(address(this)));
    }
    
    /**
     * @dev Claims reward from Aura  
     */
    function claimReward() external onlyOwner {
        i_rewardPool.getReward();
    }
}
