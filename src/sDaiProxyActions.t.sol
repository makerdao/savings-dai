pragma solidity >=0.5.0;

import "ds-test/test.sol";

import {sDaiProxyActions} from "./sDaiProxyActions.sol";

import {sDaiJoin} from "./join.sol";
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
    address sDaiProxyActions;


    function dsrJoin(address, address, uint) public {
        proxy.execute(sDaiProxyActions, msg.data);
    }

    function dsrExit(address, address, uint) public {
        proxy.execute(sDaiProxyActions, msg.data);
    }

    function dsrExitAll(address, address) public {
        proxy.execute(sDaiProxyActions, msg.data);
    }
}

contract FakeUser {

}

contract sDaiProxyActionsTest is DSTest, ProxyCalls {
    Hevm hevm;

    sDaiJoin join;

    ProxyRegistry registry;

    Vat vat;
    Pot pot;

    Dai dai;
    DaiJoin daiJoin;

    SavingsDai sDai;
    sDaiJoin savingsJoin;

    address sDaiActions;

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
        dai.mint(self, 100 ether);
    }

    function setupSavingsDai() internal {
        sDai = new SavingsDai(99);
        savingsJoin = new sDaiJoin(address(vat), address(pot), address(sDai));
        sDai.rely(address(join));
    }

    function test_basic_deploy() public {
        assertEq(address(pot.vat()), address(vat));
        assertEq(address(savingsJoin.pot()), address(pot));
        assertEq(address(savingsJoin.sDai()), address(sDai));
        assertEq(address(daiJoin.vat()), address(vat));
        assertEq(address(daiJoin.dai()), address(dai));
        assertEq(dai.balanceOf(self), 100 ether);
    }

    function testDSRSimpleCase() public {
        // this.file(address(pot), "dsr", uint(1.05 * 10 ** 27)); // 5% per second
        // uint initialTime = 0; // Initial time set to 0 to avoid any intial rounding
        // hevm.warp(initialTime);
        // dai.mint(address(this), 50 ether);
        // dai.approve(address(proxy), 50 ether);
        // assertEq(dai.balanceOf(address(this)), 50 ether);
        // assertEq(pot.pie(address(this)), 0 ether);
        // this.nope(address(vat), address(daiJoin)); // Remove vat permission for daiJoin to test it is correctly re-activate in dsrExit
        // this.dsrJoin(address(daiJoin), address(pot), 50 ether);
        // assertEq(dai.balanceOf(address(this)), 0 ether);
        // assertEq(pot.pie(address(proxy)) * pot.chi(), 50 ether * ONE);
        // hevm.warp(initialTime + 1); // Moved 1 second
        // pot.drip();
        // assertEq(pot.pie(address(proxy)) * pot.chi(), 52.5 ether * ONE); // Now the equivalent DAI amount is 2.5 DAI extra
        // this.dsrExit(address(daiJoin), address(pot), 52.5 ether);
        // assertEq(dai.balanceOf(address(this)), 52.5 ether);
        // assertEq(pot.pie(address(proxy)), 0);
    }

    // function testDSRRounding() public {
    //     this.file(address(pot), "dsr", uint(1.05 * 10 ** 27));
    //     uint initialTime = 1; // Initial time set to 1 this way some the pie will not be the same than the initial DAI wad amount
    //     hevm.warp(initialTime);
    //     uint cdp = this.open(address(manager), "ETH");
    //     this.lockETHAndDraw.value(1 ether)(address(manager), address(jug), address(ethJoin), address(daiJoin), cdp, 50 ether);
    //     dai.approve(address(proxy), 50 ether);
    //     assertEq(dai.balanceOf(address(this)), 50 ether);
    //     assertEq(pot.pie(address(this)), 0 ether);
    //     this.nope(address(vat), address(daiJoin)); // Remove vat permission for daiJoin to test it is correctly re-activate in dsrExit
    //     this.dsrJoin(address(daiJoin), address(pot), 50 ether);
    //     assertEq(dai.balanceOf(address(this)), 0 ether);
    //     // Due rounding the DAI equivalent is not the same than initial wad amount
    //     assertEq(pot.pie(address(proxy)) * pot.chi(), 49999999999999999999350000000000000000000000000);
    //     hevm.warp(initialTime + 1);
    //     pot.drip(); // Just necessary to check in this test the updated value of chi
    //     assertEq(pot.pie(address(proxy)) * pot.chi(), 52499999999999999999317500000000000000000000000);
    //     this.dsrExit(address(daiJoin), address(pot), 52.5 ether);
    //     assertEq(dai.balanceOf(address(this)), 52499999999999999999);
    //     assertEq(pot.pie(address(proxy)), 0);
    // }

    // function testDSRRounding2() public {
    //     this.file(address(pot), "dsr", uint(1.03434234324 * 10 ** 27));
    //     uint initialTime = 1;
    //     hevm.warp(initialTime);
    //     uint cdp = this.open(address(manager), "ETH");
    //     this.lockETHAndDraw.value(1 ether)(address(manager), address(jug), address(ethJoin), address(daiJoin), cdp, 50 ether);
    //     dai.approve(address(proxy), 50 ether);
    //     assertEq(dai.balanceOf(address(this)), 50 ether);
    //     assertEq(pot.pie(address(this)), 0 ether);
    //     this.nope(address(vat), address(daiJoin)); // Remove vat permission for daiJoin to test it is correctly re-activate in dsrExit
    //     this.dsrJoin(address(daiJoin), address(pot), 50 ether);
    //     assertEq(pot.pie(address(proxy)) * pot.chi(), 49999999999999999999993075745400000000000000000);
    //     assertEq(vat.dai(address(proxy)), mul(50 ether, ONE) - 49999999999999999999993075745400000000000000000);
    //     this.dsrExit(address(daiJoin), address(pot), 50 ether);
    //     // In this case we get the full 50 DAI back as we also use (for the exit) the dust that remained in the proxy DAI balance in the vat
    //     // The proxy function tries to return the wad amount if there is enough balance to do it
    //     assertEq(dai.balanceOf(address(this)), 50 ether);
    // }

    // function testDSRExitAll() public {
    //     this.file(address(pot), "dsr", uint(1.03434234324 * 10 ** 27));
    //     uint initialTime = 1;
    //     hevm.warp(initialTime);
    //     uint cdp = this.open(address(manager), "ETH");
    //     this.lockETHAndDraw.value(1 ether)(address(manager), address(jug), address(ethJoin), address(daiJoin), cdp, 50 ether);
    //     this.nope(address(vat), address(daiJoin)); // Remove vat permission for daiJoin to test it is correctly re-activate in dsrExitAll
    //     dai.approve(address(proxy), 50 ether);
    //     this.dsrJoin(address(daiJoin), address(pot), 50 ether);
    //     this.dsrExitAll(address(daiJoin), address(pot));
    //     // In this case we get 49.999 DAI back as the returned amount is based purely in the pie amount
    //     assertEq(dai.balanceOf(address(this)), 49999999999999999999);
    // }
}
