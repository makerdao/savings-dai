pragma solidity ^0.5.10;

import "../lib/dss/src/lib.sol";

contract DSTokenLike {
    function mint(address,uint) external;
    function burn(address,uint) external;
}

contract VatLike {
    mapping (address => uint256)                   public dai;
    mapping(address => mapping (address => uint)) public can;

    function hope(address) external;
    function move(address, address, uint) external;
}

contract PotLike {
    function chi() public returns(uint);
    function pie(address) public returns(uint);
    function join(uint) external;
    function exit(uint) external;
}

contract SavingsDaiJoin is DSNote{
    VatLike public vat;
    PotLike public pot;
    DSTokenLike public sDai;

    uint256 constant ONE = 10 ** 27;

    constructor(address vat_, address pot_, address sDai_) public {
        vat = VatLike(vat_);
        pot = PotLike(pot_);
        sDai = DSTokenLike(sDai_);
        vat.hope(address(pot));
    }

    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function join(address usr, uint wad) external note {
        sDai.burn(msg.sender, wad);
        uint prevBal = vat.dai(address(this));
        pot.exit(wad);
        vat.move(address(this), usr, sub(vat.dai(address(this)), prevBal));
    }

    function exit(address usr, uint wad) external note {
        vat.move(msg.sender, address(this), mul(wad, pot.chi()));
        pot.join(wad);
        sDai.mint(usr, wad);
    }
}
