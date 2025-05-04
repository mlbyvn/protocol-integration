// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {GelatoVRFConsumerBase} from "../../lib/vrf-contracts/contracts/GelatoVRFConsumerBase.sol";

/**
 * @title GelatoVRF
 * @notice Requests randomness from Gelato VRF
 * @notice Returns only one random seed per request
 * forge install gelatodigital/vrf-contracts --no-commit
 */
contract GelatoVRF is GelatoVRFConsumerBase {


    error GelatoVRF__NotAlowedToRequest();

    /**
     * @dev Make a request to Gelato VRF
     * @param data The data parameter allows for additional data to be passed to
     * the VRF, which is then forwarded to the callback. This is useful for
     * request tracking purposes if requestId is not enough.
     * @notice If implementing this external function, address check is needed
     * as the function spends funds. Alternative: just call internal version
     */
    function requestRandomness(bytes memory data) external {
        if (msg.sender != address(0xdeadbeef)) {
            revert GelatoVRF__NotAlowedToRequest();
        }
        uint256 requestId = _requestRandomness(data);
    }

    /**
     * @dev Callback function that recieves random seed from the VRF
     * @param randomness Random seed
     * @param requestId Request ID
     * @param extraData Additional data from the randomness request
     */
    function _fulfillRandomness(
        uint256 randomness,
        uint256 requestId,
        bytes memory extraData
    ) internal override {}

    /**
     * @dev Returns the address of the dedicated msg.sender
     * @dev The operator can be found on the Gelato dashboard after a VRF is deployed
     * @return Address of the operator
     */
    function _operator() internal view override returns (address) {}
}