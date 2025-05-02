// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IRETH} from "../interfaces/rocket-pool/IRETH.sol";
import {IRocketDepositPool} from "../interfaces/rocket-pool/IRocketDepositPool.sol";
import {IRocketDAOProtocolSettingsDeposit} from "../interfaces/rocket-pool/IRocketDAOProtocolSettingsDeposit.sol";
import {IRocketStorage} from "../interfaces/rocket-pool/IRocketStorage.sol";

/**
 * @title RocketPoolSwap
 * @notice Facilitates swapping between ETH and rETH using RocketPool
 */
contract RocketPoolSwap {

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    IRETH private immutable i_rEth;
    IRocketStorage private immutable i_rStorage;
    IRocketDepositPool private immutable i_depositPool;
    IRocketDAOProtocolSettingsDeposit private immutable i_protocolSettings;

    uint256 constant WAD = 1e18;

    /*//////////////////////////////////////////////////////////////
                         CONSTRUCTOR & RECEIVE
    //////////////////////////////////////////////////////////////*/
    constructor(address _rEth, address _rStorage, address _depositPool, address _protocolSettings) {
        i_rEth = IRETH(_rEth);
        i_rStorage = IRocketStorage(_rStorage);
        i_depositPool = IRocketDepositPool(_depositPool);
        i_protocolSettings = IRocketDAOProtocolSettingsDeposit(_protocolSettings);
    }


    receive() external payable {}

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Calculates the amount of rETH that user will receive after 
     * swap and deposit fee
     * @param ethAmount Input ETH amount
     * @return rEthAmount Output rETH amount
     * @return fee Deposit fee amount
     */
    function calcEthToReth(uint256 ethAmount)
        external
        view
        returns (uint256 rEthAmount, uint256 fee)
    {
        uint256 depositFee = i_protocolSettings.getDepositFee();
        fee = ethAmount * depositFee / WAD;
        ethAmount -= fee;
        rEthAmount = i_rEth.getRethValue(ethAmount);
    }

    /**
     * Calculates the amount of ETH a user will receive after swap
     * @param rEthAmount Input rETH amount
     * @return ethAmount Output ETH amount
     */
    function calcRethToEth(uint256 rEthAmount)
        external
        view
        returns (uint256 ethAmount)
    {
        ethAmount = i_rEth.getEthValue(rEthAmount);
    }

    /**
     * @dev Swaps ETH to rETH by depositing into RocketPool protocol
     */
    function swapEthToReth() external payable {
        i_depositPool.deposit{value: msg.value}();
    }

    /**
     * @dev Burns a certain amount of rETH for exchange of ETH
     * @param rEthAmount Amount of rETH to burn
     */
    function swapRethToEth(uint256 rEthAmount) external {
        i_rEth.transferFrom(msg.sender, address(this), rEthAmount);
        i_rEth.burn(rEthAmount);
    }

    /*//////////////////////////////////////////////////////////////
                            GETTER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Gets the maximal amount of ETH a user can deposit if the 
     * deposit functionality is enabled
     * @return depositEnabled Tells if deposit function is enabled
     * @return maxDepositAmount Maximal deposit amount
     */
    function getAvailability()
        external
        view
        returns (bool depositEnabled, uint256 maxDepositAmount)
    {
        return (
            i_protocolSettings.getDepositEnabled(),
            i_depositPool.getMaximumDepositAmount()
        );
    }

    /**
     * Gets the current deposit delay before deposits are processed
     * @return depositDelay Deposit delay iun blocks
     */
    function getDepositDelay() external view returns (uint256 depositDelay) {
        return i_rStorage.getUint(
            keccak256(
                abi.encodePacked(
                    keccak256("dao.protocol.setting.network"),
                    "network.reth.deposit.delay"
                )
            )
        );
    }

    /**
     * Get the block number of last user's deposit
     * @param user User address
     * @return lastDepositBlock Block number
     */
    function getLastDepositBlock(address user)
        external
        view
        returns (uint256 lastDepositBlock)
    {
        return i_rStorage.getUint(
            keccak256(abi.encodePacked("user.deposit.block", user))
        );
    }
}