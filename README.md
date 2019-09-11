# savings-dai
Proof Of Concept for how a Savings DAI token could be implemented to work with the Multicollateral DAI's DAI Savings Rate.

**Note: the code in this repo has not been audited or formally verified.  It should not be considered production-ready!  Use at your own risk!**

## How to Use

A user with a balance of `dai` in the `Vat` can `exit` into Savings Dai token. This will move their `Vat.dai` balance to the adapter's `pot.pie` balance and `mint` them sDai.

Savings Dai is an ERC-20 token. It can be `transfer`ed, `approve`d, etc. The Join Adapter is an authorized contract for the Savings Dai contract so that it has authority to `mint` new tokens.

No other special permissions are required.  Users much `approve` and `hope` on the adapter to allow it to move their tokens/balances in and out.

### How to get Savings Dai:

(As a user with `dai` in the `vat`)

1. call `Vat.hope` on the join contract
2. call `join` on the join contract with the address (`usr`) you wish to receive the sDai and the amount (`wad`) you wish to receive (not to exceed your `dai` balance).

Note: for calculating `wad` this should be the amount of dai you wish to move from your `vat` account. For instance, if you have 100 Dai in the vat (denominated in the vat as 100 ether * 10 ** 27 = rad(100)), you should use `100 ether` as your `wad` value.  The adapter will convert it to `rad` and move the appropriate amount of `dai` in the `vat` and then will calculate the appropriate amount to be `join`ed into the `pot` (i.e. `rad / pot.chi()`) and mint that amount of `pie` as Savings Dai. This means that you will receive fewer sDai than `vat.dai` but when you later redeem them (`join` back into the `vat`), you will receive the original amount of `dai` + the interest earned through the DSR.

### How to redeem Savings Dai:

(As a user with sDai in your wallet)

1. call `approve` on the Savings Dai contract with the join address and the amount you wish to redeem
2. call `exit` on the join contract with the address (`usr`) you wish to receive the `dai` and the amount (`wad`) you wish to redeem (not to exceed your sDai balance).

### How to setup:

(Assuming the DSS system is launched)

1. Deploy the SavingsDai token with the network id as the only parameter.
2. Deploy the SavingsDai Join adapter contract with the `vat` address, the `pot` address and the Savings Dai token address as the three parameters.
3. From the address with which you created the SavingsDai contract, call `SavingsDai.rely(address(joinAdapter))` to authorize the Adapter to `mint` tokens.
4. From the address with which you created SavingsDai contract, call `SavingsDai.deny(address(<your-address>))` to deauthorize your deploying address from the token contract.

**Note: Users should ensure that only the adapter is `rely`ed upon by the SavingsDai Token before interacting with it as any address that is `auth`ed in that manner will be able to `mint` new SavingsDai.** Interacting with a token contract that has not been secured could lead to a loss of funds.
