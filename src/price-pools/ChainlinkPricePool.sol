// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IRETH} from "../interfaces/rocket-pool/IRETH.sol";
import {IAggregatorV3} from "../interfaces/chainlink/IAggregatorV3.sol";
import {RETH, CHAINLINK_RETH_ETH} from "../Constants.sol";

/**
 * @title ChainlinkPricePool
 * @notice Facilitates acquiring rETH/ETH exchange rate from RocketPool 
 * and Chainlink Price Feed
 */
contract ChainlinkPricePool {

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    IRETH private immutable i_rEth;
    IAggregatorV3 private immutable i_agg;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(address _reth, address _agg) {
        i_rEth = IRETH(_reth);
        i_agg = IAggregatorV3(_agg);
    }

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Get exchange rate rETH/ETH from Rocket Pool
     * @dev Returns 18 decimals
     */
    function getExchangeRate() external view returns (uint256) {
        return i_rEth.getExchangeRate();
    }

    /**
     * @dev Get exchange rate rETH/ETH from Chainlink Price Feed
     * @dev Returns 18 decimals
     */
    function getExchangeRateFromChainlink() external view returns (uint256) {
        (
            , // uint80 roundId,
            int256 rate,
            , // uint256 startedAt,
            uint256 updatedAt,
            // uint80 answeredInRound
        ) = i_agg.latestRoundData();

        require(updatedAt >= block.timestamp - 24 * 3600, "stale price");
        require(rate >= 0, "rate < 0");

        return uint256(rate);
    }
}