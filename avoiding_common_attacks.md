# Avoiding common attacks

Some common attacks against this contract are:
- Integer overflow/underflow
- Card reveal scheme
- Deck shuffling randomness 

These are addressed below.

## Integer overflow/underflow

The project uses **OpenZeppelin**'s `SafeMath` library throughout to prevent integer overflow / underflow.

## Card reveal scheme

There are two security aspects addressed with respect to the card revealing process:

- Dealer hole card

In brick & mortar casinos, the dealer is dealt 2 cards at the beginning of a game. In this implementation, the dealer is dealt just 1 card (the upcard), and no hole card. The hole card is the most critical piece of information - since that card is not dealt here, there is no information for an attacker to target. This also has the (non-security) drawback of not knowing whether the dealer has Blackjack until the action has completed.

- Order of drawing cards
Since Blackjack is a game requiring multiple steps, the transaction order is important. This project uses an *enum* (`enum Stage {Bet, PlayHand, PlaySplitHand, ConcludeHands}`) with `revert`s and `reset`s to control game flow and permit actions like drawing cards or triggering a `transfer`. 

May still add a commit-reveal scheme.

## Deck shuffling randomness 

Currently using timestamps and hashing as a source of randomness, which is actually a security weakness, to be improved upon. Plan is to implement the Provable API with Wolfram Alpha for random numbers on each request.
