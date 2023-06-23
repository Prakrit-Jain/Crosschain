// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.18;

/**
 * @notice Counter Contract Interface To Call the Increment Function
 */
interface Counter {
    /**
     * @notice This function increments the value of storage variable by value `value`
     * @param value The `value` to increase the variable by.
     */
    function increment(uint256 value) external;
}
