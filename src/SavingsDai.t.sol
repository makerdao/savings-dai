pragma solidity ^0.5.10;

import "ds-test/test.sol";

import "./SavingsDai.sol";

contract SavingsDaiTest is DSTest {
    SavingsDai dai;

    function setUp() public {
        dai = new SavingsDai();
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}
