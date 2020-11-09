# Avoiding common attacks

See [avoiding_common_attacks.md](avoiding_common_attacks.md "Contract security") for details on the following risk mitigations:

Some common attacks against this contract are:
- Integer overflow/underflow
- Reentrancy
- Card deck randomness 
- Card reveal scheme
- Payment strategy

These are addressed below.

## Integer overflow/underflow

**OpenZeppelin**'s `SafeMath` library to prevent overflow / underflow

## Reentrancy

**OpenZeppelin**'s `ReentrancyGuard` utility and checks-effects-interactions patterns
## Commit reveal schemes for dealer hole card and remaining deck?
## Source of randomness?
## `PullPayment` strategy

