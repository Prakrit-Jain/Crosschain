// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.18;

contract Counter {
    uint256 public count;

    /**
     * @notice This function increments the value of storage variable by value `value`
     * @param value The `value` to increase the variable by.
     */
    function increment(uint256 value) external {
        count += value;
    }
}
