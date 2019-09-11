pragma solidity ^0.5.10;

contract JoinLike {}
contract TokenLike {}
contract VatLike{}

contract sDaiProxyActions {
    uint256 constant ONE = 10 ** 27;

    // Internal functions

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "mul-overflow");
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "sub-overflow");
    }

    function toInt(uint x) internal pure returns (int y) {
        y = int(x);
        require(y >= 0, "int-overflow");
    }

    function toRad(uint wad) internal pure returns (uint rad) {
        rad = mul(wad, 10 ** 27);
    }

    function sDaiJoin(
        address sDaiJoin,
        address vat,
        uint wad
    ) public;

    function sDaiExit(
        address sDaiJoin,
        address vat,
        uint wad
    ) public;

    function sDaiExitAll(
        address sDaiJoin,
        address vat
    ) public;
}
