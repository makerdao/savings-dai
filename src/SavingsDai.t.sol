pragma solidity ^0.5.10;

import "ds-test/test.sol";

import "./join.sol";
import "./SavingsDai.sol";
import "../lib/dss/src/vat.sol";
import "../lib/dss/src/pot.sol";

contract Hevm {
    function warp(uint256) public;
}

contract SavingsDaiTest is DSTest {
    SavingsDai sDai;
    Vat vat;
    Pot pot;
    Hevm hevm;

    function setUp() public {
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        hevm.warp(604411200);
        vat = new Vat();
        pot = new Pot(address(vat));
        sDai = createToken();
    }

    function createToken() internal returns (SavingsDai) {
        return new SavingsDai(99, address(pot));
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}
