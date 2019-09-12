pragma solidity >=0.5.0;

import "ds-test/test.sol";

import {sDaiProxyActions} from "./sDaiProxyActions.sol";

import {SavingsDaiJoin} from "./join.sol";
import {SavingsDai} from "./SavingsDai.sol";
import {Vat} from "dss/vat.sol";
import {Pot} from "dss/pot.sol";
import {Dai} from "dss/dai.sol";
import {DaiJoin} from "dss/join.sol";
import {ProxyRegistry, DSProxyFactory, DSProxy} from "proxy-registry/ProxyRegistry.sol";

contract Hevm {
    function warp(uint256) public;
}

contract ProxyCalls {
    DSProxy proxy;
    address sDaiActions;

    function sDaiJoin(address, address, uint) public {
        proxy.execute(sDaiActions, msg.data);
    }

    function sDaiExit(address, address, uint) public {
        proxy.execute(sDaiActions, msg.data);
    }

    function sDaiExitAll(address, address) public {
        proxy.execute(sDaiActions, msg.data);
    }
}

contract FakeUser {

}

contract sDaiProxyActionsTest is DSTest, ProxyCalls {
    Hevm hevm;

    ProxyRegistry registry;

    Vat vat;
    Pot pot;

    Dai dai;
    DaiJoin daiJoin;

    SavingsDai sDai;
    SavingsDaiJoin savingsJoin;

    address vow;
    address self;

    uint256 constant ONE = 10 ** 27;

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "mul-overflow");
    }

    function rad(uint wad_) internal pure returns (uint) {
        return mul(wad_, ONE);
    }
    function wad(uint rad_) internal pure returns (uint) {
        return rad_ / 10 ** 27;
    }

    function setUp() public {
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        hevm.warp(0);

        self = address(this);

        setupDss();
        setupSavingsDai();

        DSProxyFactory factory = new DSProxyFactory();
        registry = new ProxyRegistry(address(factory));
        sDaiActions = address(new sDaiProxyActions());
        proxy = DSProxy(registry.build());
    }

    function setupDss() internal {
        vat = new Vat();
        pot = new Pot(address(vat));
        vat.rely(address(pot));

        vow = address(bytes20("vow"));
        pot.file("vow", vow);

        vat.hope(address(pot));

        dai = new Dai(99);
        daiJoin = new DaiJoin(address(vat), address(dai));
        dai.rely(address(daiJoin));
        vat.suck(self, address(daiJoin), rad(100 ether));
        dai.mint(self, 100 ether);
    }

    function setupSavingsDai() internal {
        sDai = new SavingsDai(99);
        savingsJoin = new SavingsDaiJoin(address(vat), address(pot), address(sDai));
        sDai.rely(address(savingsJoin));
    }

    function test_basic_deploy() public {
        assertEq(address(pot.vat()), address(vat));
        assertEq(address(savingsJoin.pot()), address(pot));
        assertEq(address(savingsJoin.sDai()), address(sDai));
        assertEq(address(daiJoin.vat()), address(vat));
        assertEq(address(daiJoin.dai()), address(dai));
        assertEq(dai.balanceOf(self), 100 ether);
        assertEq(address(registry.proxies(self)), address(proxy));
    }

    function testDSRSimpleCase_0s() public {
        pot.file("dsr", uint(1.05 * 10 ** 27)); // 5% per second
        uint initialTime = 0; // Initial time set to 0 to avoid any intial rounding
        hevm.warp(initialTime);

        dai.approve(address(proxy), 100 ether);
        assertEq(dai.balanceOf(self), 100 ether);

        this.sDaiJoin(address(daiJoin), address(savingsJoin), 100 ether);
        assertEq(dai.balanceOf(self), 0 ether);
        assertEq(sDai.balanceOf(address(proxy)), 100 ether);

        assertEq(pot.pie(address(savingsJoin)) * pot.chi(), rad(100 ether)); // Now the equivalent DAI amount is 5 DAI extra
        this.sDaiExit(address(daiJoin), address(savingsJoin), 100 ether);
        assertEq(dai.balanceOf(self), 100 ether);
        assertEq(sDai.balanceOf(address(proxy)), 0 ether);
        assertEq(pot.pie(address(proxy)), 0);
        assertEq(vat.dai(address(proxy)), 0);
        assertEq(vat.dai(address(savingsJoin)), 0);
        assertEq(vat.dai(address(daiJoin)), rad(100 ether));
        assertEq(dai.balanceOf(address(proxy)), 0 ether);
    }

    function testDSRSimpleCase_1s() public {
        pot.file("dsr", uint(1.05 * 10 ** 27)); // 5% per second
        uint initialTime = 0; // Initial time set to 0 to avoid any intial rounding
        hevm.warp(initialTime);

        dai.approve(address(proxy), 100 ether);
        assertEq(dai.balanceOf(self), 100 ether);

        this.sDaiJoin(address(daiJoin), address(savingsJoin), 100 ether);
        assertEq(dai.balanceOf(self), 0 ether);
        assertEq(sDai.balanceOf(address(proxy)), 100 ether);

        hevm.warp(initialTime + 1); // Moved 1 second
        pot.drip();
        assertEq(pot.pie(address(savingsJoin)) * pot.chi(), 105 ether * ONE); // Now the equivalent DAI amount is 5 DAI extra
        this.sDaiExit(address(daiJoin), address(savingsJoin), 100 ether);
        assertEq(dai.balanceOf(self), 105 ether);
        assertEq(sDai.balanceOf(address(proxy)), 0 ether);
        assertEq(pot.pie(address(proxy)), 0);
        assertEq(vat.dai(address(proxy)), 0);
        assertEq(vat.dai(address(savingsJoin)), 0);
        assertEq(vat.dai(address(daiJoin)), rad(105 ether));
        assertEq(dai.balanceOf(address(proxy)), 0 ether);
    }

    function testDSRRounding() public {
        pot.file("dsr", uint(1.05 * 10 ** 27)); // 5% per second
        uint initialTime = 1; // Initial time set to 1 this way some the pie will not be the same than the initial DAI wad amount
        hevm.warp(initialTime);

        dai.approve(address(proxy), 100 ether);
        assertEq(dai.balanceOf(self), 100 ether);

        this.sDaiJoin(address(daiJoin), address(savingsJoin), 100 ether);
        assertEq(dai.balanceOf(self), 0 ether);
        // Due to Chi the sDAI equivalent is not the same than initial wad amount
        assertEq(sDai.balanceOf(address(proxy)), 95238095238095238095);
        hevm.warp(initialTime + 1);
        pot.drip(); // Just necessary to check in this test the updated value of chi
        assertEq(pot.pie(address(savingsJoin)) * pot.chi(), 104999999999999999999737500000000000000000000000);
        this.sDaiExit(address(daiJoin), address(savingsJoin), 95238095238095238095);
        assertEq(dai.balanceOf(self), 104999999999999999999);
        assertEq(pot.pie(address(proxy)), 0);
        assertEq(vat.dai(address(daiJoin)), 104999999999999999999000000000000000000000000000);
    }

    function testDSRRounding2() public {
        pot.file("dsr", uint(1.05 * 10 ** 27)); // 5% per second
        uint initialTime = 1;
        hevm.warp(initialTime);

        dai.approve(address(proxy), 100 ether);
        assertEq(dai.balanceOf(self), 100 ether);

        this.sDaiJoin(address(daiJoin), address(savingsJoin), 100 ether);
        assertEq(dai.balanceOf(self), 0 ether);
        // Due to Chi the sDAI equivalent is not the same than initial wad amount
        assertEq(sDai.balanceOf(address(proxy)), 95238095238095238095);
        assertEq(sDai.totalSupply(), 95238095238095238095);

        assertEq(pot.pie(address(savingsJoin)) * pot.chi(), 99999999999999999999750000000000000000000000000);
        assertEq(vat.dai(address(savingsJoin)), mul(100 ether, ONE) - 99999999999999999999750000000000000000000000000);
        this.sDaiExit(address(daiJoin), address(savingsJoin), 95238095238095238095);

        // In this case we get the full 100 DAI back as we also use (for the exit) the dust that remained in the proxy DAI balance in the vat
        // The proxy function tries to return the wad amount if there is enough balance to do it
        assertEq(dai.balanceOf(self), 100 ether);
        // assertEq(dai.balanceOf(self), 99999999999999999999);
        assertEq(pot.pie(address(savingsJoin)), 0);
        assertEq(vat.dai(address(savingsJoin)), 0);
        // assertEq(vat.dai(address(savingsJoin)), 250000000000000000000000000);
        assertEq(vat.dai(address(daiJoin)), rad(100 ether));
        // assertEq(vat.dai(address(daiJoin)), 99999999999999999999000000000000000000000000000);
    }

    function testDSRExitAll() public {
        pot.file("dsr", uint(1.05 * 10 ** 27)); // 5% per second
        uint initialTime = 1;
        hevm.warp(initialTime);

        dai.approve(address(proxy), 100 ether);
        assertEq(dai.balanceOf(self), 100 ether);

        this.sDaiJoin(address(daiJoin), address(savingsJoin), 100 ether);
        this.sDaiExitAll(address(daiJoin), address(savingsJoin));
        assertEq(dai.balanceOf(self), 100 ether);
    }
}
