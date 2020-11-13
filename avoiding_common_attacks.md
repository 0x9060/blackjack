# Avoiding common attacks

Some common attacks against this contract are:
- Integer overflow/underflow
- Reentrancy
- Deck shuffling randomness 
- Card reveal scheme
- Payment strategy

These are addressed below.

## Integer overflow/underflow

**OpenZeppelin**'s `SafeMath` library to prevent overflow / underflow

## Reentrancy

**OpenZeppelin**'s `ReentrancyGuard` utility and checks-effects-interactions patterns

## Deck shuffling randomness 

Source of randomness? Ensure not using timestamp? Provable API with Wolfram Alpha for random numbers on each request.

## Card reveal scheme

Commit reveal schemes for dealer hole card and remaining deck?

## Payment strategy

`PullPayment` strategy?
