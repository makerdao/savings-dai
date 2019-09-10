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
    uint public chi;
    function join(uint) external;
    function exit(uint) external;
}

contract sDaiJoin is DSNote{
    VatLike public vat;
    PotLike public pot;
    DSTokenLike public sDai;

    uint256 constant ONE = 10 ** 27;

    event log(bytes32, uint);

    constructor(address vat_, address pot_, address sDai_) public {
        vat = VatLike(vat_);
        pot = PotLike(pot_);
        sDai = DSTokenLike(sDai_);
        vat.hope(address(pot));
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function join(address usr, uint wad) external note {
        sDai.burn(msg.sender, wad);
        pot.exit(wad);
        vat.move(address(this), usr, mul(wad, pot.chi()));
    }

    function exit(address usr, uint wad) external note {
        vat.move(msg.sender, address(this), mul(wad, ONE));
        pot.join(mul(wad, ONE) / pot.chi());
        sDai.mint(usr, wad);
    }
}
