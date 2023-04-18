// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Counter.sol";

contract CounterTest is Test {
    Counter public counter;

    // Invoked before each test
    function setUp() public {
        counter = new Counter();
    }

    // Test must be external or public
    function testInc() public {
        counter.inc();
        assertEq(counter.count(), 1);
    }

    function testFailDec() public {
        // This will fail with underflow
        // count = 0 --> count -= 1
        counter.dec();
    }

    // Same as testFailDec
    function testDecUnderflow() public {
        vm.expectRevert(stdError.arithmeticError);
        counter.dec();
    }

    function testDec() public {
        counter.inc();
        counter.inc();
        counter.dec();
        assertEq(counter.count(), 1);
    }
}
// forge build for compiling  
// forge test for testing   
// forge test -vvvv for detailed testing 
// forge test --help 
// forge test --match-path test/counter.t.sol for specific test file
 // forge test --match path test/counter.t.sol --gas-report for gas report