// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IERC20} from "../interfaces/IERC20.sol";
import {IStrategyManager} from "../interfaces/eigen-layer/IStrategyManager.sol";
import {IStrategy} from "../interfaces/eigen-layer/IStrategy.sol";
import {IDelegationManager} from "../interfaces/eigen-layer/IDelegationManager.sol";
import {IRewardsCoordinator} from "../interfaces/eigen-layer/IRewardsCoordinator.sol";
import {max} from "../Util.sol";

/**
 * @title EigenLayerRestake
 * @notice Provides functionality to stake and delegate staking on EigenLayer 
 */
contract EigenLayerRestake {

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error EigenLayerRestake__OnlyOwner();

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    IERC20 private immutable i_rEth;
    IStrategyManager private immutable i_strategyManager;
    IStrategy private immutable i_strategy;
    IDelegationManager private immutable i_delegationManager;
    IRewardsCoordinator private immutable i_rewardsCoordinator;

    address public owner;

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/
    modifier onlyOwner() {
        if (msg.sender != owner){
            revert EigenLayerRestake__OnlyOwner();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(
        address _reth, 
        address _strategyManager,
        address _strategy, 
        address _delegationManager, 
        address _rewardsCoordinator
        ) {
        owner = msg.sender;
        i_rEth = IERC20(_reth);
        i_strategyManager = IStrategyManager(_strategyManager);
        i_strategy = IStrategy(_strategy);
        i_delegationManager = IDelegationManager(_delegationManager);
        i_rewardsCoordinator = IRewardsCoordinator(_rewardsCoordinator);

    }

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Transfers RETH from the user to the contract, approves it for the StrategyManager,
     * and then deposits it into the EigenLayer strategy
     * @param rethAmount Amount of rETH to deposit
     * @return shares Number of shares received by the user
     */
    function deposit(uint256 rethAmount) external returns (uint256 shares) {
        i_rEth.transferFrom(msg.sender, address(this), rethAmount);
        i_rEth.approve(address(i_strategyManager), rethAmount);
        shares = i_strategyManager.depositIntoStrategy({
            strategy: address(i_strategy),
            token: address(i_rEth),
            amount: rethAmount
        });
    }

    /**
     * @dev Delegates staking to a specific operator, which will 
     * perform actions on behalf of the staker
     * @param operator Address of the operator contract
     */
    function delegate(address operator) external onlyOwner {
        i_delegationManager.delegateTo({
            operator: operator,
            approverSignatureAndExpiry: IDelegationManager.SignatureWithExpiry({
                signature: "",
                expiry: 0
            }),
            approverSalt: bytes32(uint256(0))
        });
    }

    /**
     * @dev Undelegate an operator and request a withdrawal
     */
    function undelegate() external onlyOwner returns (bytes32[] memory withdrawalRoot) {
        withdrawalRoot = i_delegationManager.undelegate(address(this));
    }

    /**
     * @dev Withdraw staked rETH after undelegation
     * @param operator Address of the operator contract
     * @param shares Amount of shares
     * @param startBlockNum The block number to start the withdrawal
     */
    function withdraw(address operator, uint256 shares, uint32 startBlockNum) external onlyOwner {
        address[] memory strategies = new address[](1);
        strategies[0] = address(i_strategy);

        uint256[] memory _shares = new uint256[](1);
        _shares[0] = shares;

        IDelegationManager.Withdrawal memory withdrawal = IDelegationManager
            .Withdrawal({
            staker: address(this),
            delegatedTo: operator,
            withdrawer: address(this),
            nonce: 0,
            startBlock: startBlockNum,
            strategies: strategies,
            shares: _shares
        });

        address[] memory tokens = new address[](1);
        tokens[0] = address(i_rEth);

        i_delegationManager.completeQueuedWithdrawal({
            withdrawal: withdrawal,
            tokens: tokens,
            middlewareTimesIndex: 0,
            receiveAsTokens: true
        });
    }

    /**
     * @dev Claims rewards from staked rETH
     * @param claim Reward claim data
     */
    function claimRewards(IRewardsCoordinator.RewardsMerkleClaim memory claim) external {
        i_rewardsCoordinator.processClaim(claim, address(this));
    }

    /**
     * Transfer all of a specific token from the contract to the given address
     * @param token Token address
     * @param dst Receiver address
     */
    function transfer(address token, address dst) external onlyOwner {
        IERC20(token).transfer(dst, IERC20(token).balanceOf(address(this)));
    }

    /*//////////////////////////////////////////////////////////////
                            GETTER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Get the number of shares a staker has
     */
    function getShares() external view returns (uint256) {
        return i_strategyManager.stakerStrategyShares(
            address(this), address(i_strategy)
        );
    }

    /**
     * @dev Get the current withdrawal delay
     */
    function getWithdrawalDelay() external view returns (uint256) {
        uint256 protocolDelay = i_delegationManager.minWithdrawalDelayBlocks();

        address[] memory strategies = new address[](1);
        strategies[0] = address(i_strategy);
        uint256 strategyDelay = i_delegationManager.getWithdrawalDelay(strategies);

        return max(protocolDelay, strategyDelay);
    }
}