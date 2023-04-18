// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

contract Counter {
    uint256 public count;

    function inc() external {
        count += 1;
    }

    function dec() external {
        count -= 1;
    }
}
