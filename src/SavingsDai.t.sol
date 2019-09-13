pragma solidity ^0.5.10;

import "ds-test/test.sol";

import {SavingsDaiJoin} from "./join.sol";
import {SavingsDai} from "./SavingsDai.sol";
import {Vat} from "../lib/dss/src/vat.sol";
import {Pot} from "../lib/dss/src/pot.sol";

contract Hevm {
    function warp(uint256) public;
}

contract Usr {
    Pot public pot;
    Vat public vat;
    // SavingsDai public sDai;
    constructor(Pot pot_, Vat vat_) public {
        pot = pot_;
        vat = vat_;
        // sDai = sDai_;
        // join = join_;
    }

    function hope(address usr) public {
        vat.hope(usr);
    }
    function nope(address usr) public {
        vat.nope(usr);
    }
    function join(address join_, address usr, uint wad) public {
        SavingsDaiJoin(join_).join(usr, wad);
    }
    function exit(address join_, address usr, uint wad) public {
        SavingsDaiJoin(join_).exit(usr, wad);
    }
    function approve(address token, address usr, uint wad) public {
        SavingsDai(token).approve(usr, wad);
    }
    function transfer(address token, address dst, uint wad) public {
        SavingsDai(token).transfer(dst, wad);
    }
    function dsrJoin(uint wad) public {
        pot.join(wad);
    }
    function dsrExit(uint wad) public {
        pot.exit(wad);
    }
}

contract SavingsDaiTest is DSTest {
    Hevm hevm;

    SavingsDai sDai;
    Vat vat;
    Pot pot;
    SavingsDaiJoin join;

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

        sDai = createToken();
        join = new SavingsDaiJoin(address(vat), address(pot), address(sDai));
        sDai.rely(address(join));
    }

    function setupDss() internal {
        vat = new Vat();
        pot = new Pot(address(vat));
        vat.rely(address(pot));

        vow = address(bytes20("vow"));
        pot.file("vow", vow);

        vat.suck(self, self, rad(100 ether));
        vat.hope(address(pot));
    }

    function createToken() internal returns (SavingsDai) {
        return new SavingsDai(99);
    }

    function test_basic_deploy() public {
        assertEq(address(pot.vat()), address(vat));
        assertEq(address(join.pot()), address(pot));
        assertEq(address(join.sDai()), address(sDai));
    }

    function test_join_sDai_0d() public {
        uint initialTime = 0; // Initial time set to 0 to avoid any intial rounding
        hevm.warp(initialTime);

        Usr ali = new Usr(pot, vat);
        ali.hope(address(join));
        vat.move(self, address(ali), rad(100 ether));

        ali.exit(address(join), address(ali), 100 ether);

        assertEq(pot.pie(address(join)), 100 ether);
        assertEq(sDai.balanceOf(address(ali)), 100 ether);
        assertEq(sDai.totalSupply(), 100 ether);
    }

    function test_join_sDai_1d() public {
        pot.file("dsr", uint(1.05 * 10 ** 27)); // 5% per second
        uint initialTime = 0; // Initial time set to 0 to avoid any intial rounding
        hevm.warp(initialTime);
        Usr ali = new Usr(pot, vat);
        ali.hope(address(join));
        vat.move(self, address(ali), rad(100 ether));

        ali.exit(address(join), address(ali), 100 ether);

        hevm.warp(initialTime + 1);
        pot.drip();

        assertEq(pot.pie(address(join)), 100 ether);
        assertEq(vat.dai(self), 0);
        assertEq(vat.dai(address(ali)), 0);
        assertEq(vat.dai(address(pot)), rad(105 ether));
        assertEq(sDai.balanceOf(address(ali)), 100 ether);
    }

    function test_exit_sDai_0d() public {
        assertEq(sDai.totalSupply(), 0);
        Usr ali = new Usr(pot, vat);
        ali.hope(address(join));
        vat.move(self, address(ali), rad(100 ether));

        ali.exit(address(join), address(ali), 100 ether);
        assertEq(pot.pie(address(ali)), 0);
        assertEq(pot.pie(address(join)), 100 ether);
        assertEq(sDai.balanceOf(address(ali)), 100 ether);
        assertEq(sDai.totalSupply(), 100 ether);

        ali.approve(address(sDai), address(join), 100 ether);
        ali.join(address(join), address(ali), 100 ether);
        assertEq(sDai.totalSupply(), 0);
        assertEq(sDai.balanceOf(address(ali)), 0);
        assertEq(pot.pie(address(join)), 0);
        assertEq(vat.dai(address(ali)), rad(100 ether));
    }

    function test_exit_sDai_1d() public {
        pot.file("dsr", uint(1.05 * 10 ** 27)); // 5% per second
        uint initialTime = 0; // Initial time set to 0 to avoid any intial rounding
        hevm.warp(initialTime);
        assertEq(sDai.totalSupply(), 0);
        Usr ali = new Usr(pot, vat);
        ali.hope(address(join));
        vat.move(self, address(ali), rad(100 ether));
        ali.exit(address(join), address(ali), 100 ether);
        assertEq(vat.dai(address(pot)), rad(100 ether));

        hevm.warp(initialTime + 1);
        pot.drip();

        assertEq(vat.dai(address(pot)), rad(105 ether));
        assertEq(pot.pie(address(ali)), 0);
        assertEq(pot.pie(address(join)), 100 ether);
        assertEq(sDai.balanceOf(address(ali)), 100 ether);
        assertEq(sDai.totalSupply(), 100 ether);

        ali.approve(address(sDai), address(join), 100 ether);
        ali.join(address(join), address(ali), 100 ether);

        assertEq(sDai.totalSupply(), 0);
        assertEq(sDai.balanceOf(address(ali)), 0);
        assertEq(pot.pie(address(join)), 0);

        assertEq(vat.dai(address(pot)), 0);
        assertEq(vat.dai(address(ali)), rad(105 ether));
    }

    function test_multiple_users_sDai_equal_returns_as_dai_1d() public {
        /**
         * The goal of this test is to show that users who decide to
         * use sDai do not earn more DSR than a user who just joins the DSR/pie
         * i.e. the "pooling" that occurs with `pie` when users exit to sDai
         * does not enable them greater gain than holding `pie`.
         */

        pot.file("dsr", uint(1.05 * 10 ** 27)); // 5% per second
        uint initialTime = 0; // Initial time set to 0 to avoid any intial rounding
        hevm.warp(initialTime);
        assertEq(sDai.totalSupply(), 0);

        Usr ali = new Usr(pot, vat);
        ali.hope(address(join));
        vat.move(self, address(ali), rad(100 ether));

        Usr bob = new Usr(pot, vat);
        bob.hope(address(join));
        vat.suck(self, self, rad(100 ether));
        vat.move(self, address(bob), rad(100 ether));

        Usr cam = new Usr(pot, vat);
        vat.suck(self, self, rad(100 ether));
        vat.move(self, address(cam), rad(100 ether));
        cam.hope(address(pot));

        assertEq(vat.dai(address(ali)), rad(100 ether));
        assertEq(vat.dai(address(bob)), rad(100 ether));
        assertEq(vat.dai(address(cam)), rad(100 ether));

        ali.exit(address(join), address(ali), 100 ether);
        bob.exit(address(join), address(bob), 100 ether);
        cam.dsrJoin(100 ether); // cam needs to join directly

        assertEq(pot.pie(address(cam)), 100 ether);
        assertEq(pot.pie(address(join)), 200 ether);
        assertEq(sDai.balanceOf(address(ali)), 100 ether);
        assertEq(sDai.balanceOf(address(bob)), 100 ether);
        assertEq(sDai.totalSupply(), 200 ether);

        hevm.warp(initialTime + 1);
        pot.drip();

        ali.approve(address(sDai), address(join), 100 ether);
        bob.approve(address(sDai), address(join), 100 ether);
        ali.join(address(join), address(ali), 100 ether);
        bob.join(address(join), address(bob), 100 ether);
        cam.dsrExit(100 ether);

        assertEq(sDai.totalSupply(), 0);
        assertEq(sDai.balanceOf(address(ali)), 0);
        assertEq(sDai.balanceOf(address(bob)), 0);

        assertEq(pot.pie(address(join)), 0);
        assertEq(vat.dai(address(pot)), 0);

        assertEq(vat.dai(address(ali)), rad(105 ether));
        assertEq(vat.dai(address(bob)), rad(105 ether));
        assertEq(vat.dai(address(cam)), rad(105 ether));
    }

    function test_different_users_exit_1d() public {
        /**
         * sDai is fungible. Adapter will return `dai` to whoever joins with
         * sDai.
         */
        pot.file("dsr", uint(1.05 * 10 ** 27)); // 5% per second
        uint initialTime = 0; // Initial time set to 0 to avoid any intial rounding
        hevm.warp(initialTime);
        assertEq(sDai.totalSupply(), 0);

        Usr ali = new Usr(pot, vat);
        ali.hope(address(join));
        vat.move(self, address(ali), rad(100 ether));

        Usr bob = new Usr(pot, vat);

        assertEq(vat.dai(address(ali)), rad(100 ether));
        assertEq(vat.dai(address(bob)), 0);

        ali.exit(address(join), address(ali), 100 ether);

        assertEq(sDai.balanceOf(address(ali)), 100 ether);
        assertEq(sDai.balanceOf(address(bob)), 0);

        ali.transfer(address(sDai), address(bob), 100 ether);

        assertEq(sDai.balanceOf(address(ali)), 0);
        assertEq(sDai.balanceOf(address(bob)), 100 ether);

        hevm.warp(initialTime + 1);
        pot.drip();

        bob.approve(address(sDai), address(join), 100 ether);
        bob.join(address(join), address(bob), 100 ether);

        assertEq(vat.dai(address(ali)), 0);
        assertEq(vat.dai(address(bob)), rad(105 ether));
    }

    function test_multiple_users_join_different_times_1d() public {
        /**
         * The goal of this test is to show the impact of users joining
         * at different times (i.e. different drip rates)
         * Essentially 1 sDai = 1 pie, but how much pie you get is determined by
         * both how much Dai you join as well as when you do it
         * join after a drip will mean you get fewer pie/sDai than an earlier user
         * but this will still result in the same value
         * (i.e. earnings are determined by the length of time you hold
         * not when you start)
         */

        pot.file("dsr", uint(1.05 * 10 ** 27)); // 5% per second
        uint initialTime = 0; // Initial time set to 0 to avoid any intial rounding
        hevm.warp(initialTime);
        assertEq(sDai.totalSupply(), 0);

        // Ali joins into sDai with 100 dai
        Usr ali = new Usr(pot, vat);
        vat.move(self, address(ali), rad(100 ether));
        ali.hope(address(join));
        ali.exit(address(join), address(ali), 100 ether);
        assertEq(sDai.balanceOf(address(ali)), 100 ether);
        assertEq(sDai.totalSupply(), 100 ether);
        assertEq(pot.pie(address(join)), 100 ether);

        // Drip
        hevm.warp(initialTime + 1);
        pot.drip();

        // // Bob joins into sDai with 100 dai
        Usr bob = new Usr(pot, vat);
        bob.hope(address(join));
        vat.suck(self, self, rad(100 ether));
        vat.move(self, address(bob), rad(100 ether));
        uint bobPie = mul(100 ether, ONE) / pot.chi();
        bob.exit(address(join), address(bob), bobPie);

        assertEq(pot.pie(address(join)), (100 ether + bobPie));
        assertEq(sDai.balanceOf(address(bob)), bobPie);
        assertEq(sDai.totalSupply(), (100 ether + bobPie));

        hevm.warp(initialTime + 2);
        pot.drip();

        ali.approve(address(sDai), address(join), 100 ether);
        ali.join(address(join), address(ali), 100 ether);

        bob.approve(address(sDai), address(join), bobPie);
        bob.join(address(join), address(bob), bobPie);

        assertEq(sDai.totalSupply(), 0);
        assertEq(sDai.balanceOf(address(ali)), 0);
        assertEq(sDai.balanceOf(address(bob)), 0);

        assertEq(vat.dai(address(pot)), 0);
        assertEq(vat.dai(address(ali)), rad(110.25 ether));
        assertEq(vat.dai(address(bob)), 104999999999999999999987500000000000000000000000); // 105 with rounding imprecision
    }
}
