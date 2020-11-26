# Design pattern decisions

Some design patterns implemented in this contract are:
- Access control and mortality
- Circuit breakers

These are discussed below.

## Access control and mortality

The **OpenZeppelin** `Ownable` library is used to control access to the mortality function `kill`, which calls `selfdestruct(address(uint160(owner())))`.

For the time being, `kill` is the only way to withdraw profits from the casino - there are plans to add other automated or manual withdrawal methods in the future which will also require the `onlyOwner` modifier.

## Circuit breakers

Circuit breakers are added around the *public payable* `newRound` function *private* `concludeGame` function which contains the `msg.sender.transfer(payout)` call. The circuit breaker is implemented using the `stopInEmergency` modifier, which is triggered if the contract loses many hands in a row (controlled by the `lossLimit` state variable).

There are also other mitigations to control the ability of users to potentially take advantage of the contract, like the `maxBet` setting which ensures the contract will be liquid, and various `require` statements on bet sizing.
