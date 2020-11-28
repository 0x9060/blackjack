# Blackjack dApp

Blackjack game run on the Ethereum blockchain using `web3.js` and React web framework.

Planning to put this on mainnet and stake it for some small amount, and see what happens, after thoroughly testing. For now, this project is run locally on a development server at http://127.0.0.1:3000 and the contract is also deployed to *Rinkeby*.

## Getting started

This project and guide are built and tested on an Ubuntu 18.04 virtual machine. I'm using `ganache-cli` for local Ethereum blockchain deployment and `Metamask` for wallet management. 

### Prerequisites

First install required software, `node.js` and `npm`, `Solidity` compiler, `Truffle` suite, and `Ganache` if you don't already have these. `Git` and `curl` are also required for acquiring software.

```
sudo add-apt-repository ppa:ethereum/ethereum -y && \
sudo apt update && \
sudo apt install -y solc git curl && \
cd ~ && \
curl -sL https://deb.nodesource.com/setup_10.x -o nodesource_setup.sh && \
sudo bash nodesource_setup.sh && \
sudo apt install -y nodejs && \
sudo npm install -g truffle ganache-cli
```

### Installation

Installing this project involves a `git` clone and a few `npm install` commands. For example, this installs the project in the `~/blackjack` directory.

```
mkdir ~/blackjack && \
git clone https://github.com/0x9060/blackjack ~/blackjack && \
cd ~/blackjack && \
npm install && \
cd ~/blackjack/client && \
npm install
```

I also use the browser wallet, [Metamask](https://addons.mozilla.org/en-US/firefox/addon/ether-metamask/).

### Starting up

First run a local test Ethereum blockchain with `ganache-cli`. Then connect `Metamask` to the local blockchain using **mnemonic** provided by `ganache`. Then run the following.

```
cd ~/blackjack && \
truffle compile --all && \
truffle test && \
truffle migrate --reset
```

Make note of the **blackjack** contract address. Select a `ganache` account (separate than the one used for playing) to fund the **blackjack** contract using the `fallback` function.

```
cd ~/blackjack/client && \
npm run start
```

Connect the player's `ganache` account to the dApp when prompted via `Metamask`.

### Demo

A ![Getting Started demo video](https://github.com/0x9060/blackjack/blob/master/demo.mp4 "Getting Started demo video") is provided in this repo, which includes all the above steps. The 8-minute video starts from scratch on a Ubuntu 18.04 system. Most of the duration are the setup steps, with dApp interaction beginning at the 6:22 mark.

## Deployed addresses

Commit [d31c917](https://github.com/0x9060/blackjack/commit/d31c9175378587cd42907c2cdbc9762ae634d80a) was published to a contract on `Rinkeby` at address [Etherscan](https://rinkeby.etherscan.io/address/0xaF56258bD8BD29Bc37d77E2d886192eF20888A59). See [deployed_addresses.md](deployed_addresses.md "Deployed addresses") for more details.

## Game rules

- Single deck
- Shuffle after each hand
- Dealer stands on soft 17

- Double any first two cards
- Double after split
- Split only once
- Can hit split aces

- Blackjack pays 3:2
- Late surrender refunds 1:2
- No Insurance

## Contract design

See [design_pattern_decisions.md](design_pattern_decisions.md "Design pattern decisions") for details on the following:
- Access control and mortality
- Circuit breakers

## Contract security

See [avoiding_common_attacks.md](avoiding_common_attacks.md "Avoiding common attacks") for details on the following:
- Integer overflow/underflow
- Card reveal scheme
- Deck shuffling randomness 

## Project structure

This is a `truffle` project using a `React` front-end, built from the truffle react box. The project directory is constructed as follows:

```
.
├── avoiding_common_attacks.md
├── client
│   ├── package.json
│   ├── package-lock.json
│   ├── public
│   │   ├── favicon.ico
│   │   ├── index.html
│   │   ├── manifest.json
│   │   └── robots.txt
│   ├── README.md
│   ├── src
│   │   ├── App.css
│   │   ├── App.js
│   │   ├── App.test.js
│   │   ├── contracts
│   │   │   ├── Blackjack.json
│   │   │   ├── Buffer.json
│   │   │   ├── CBOR.json
│   │   │   ├── Context.json
│   │   │   ├── Migrations.json
│   │   │   ├── OracleAddrResolverI.json
│   │   │   ├── Ownable.json
│   │   │   ├── ProvableI.json
│   │   │   ├── SafeMath.json
│   │   │   ├── solcChecker.json
│   │   │   └── usingProvable.json
│   │   ├── getWeb3.js
│   │   ├── index.css
│   │   ├── index.js
│   │   ├── logo.svg
│   │   └── serviceWorker.js
│   └── yarn.lock
├── contracts
│   ├── Blackjack.sol
│   ├── Migrations.sol
│   └── provableAPI.sol
├── deployed_addresses.md
├── design_pattern_decisions.md
├── LICENSE
├── migrations
│   ├── 1_initial_migration.js
│   └── 2_deploy_contracts.js
├── package.json
├── package-lock.json
├── README.md
├── test
│   ├── blackjack.test.js
│   ├── exceptionsHelpers.js
│   └── TestBlackjack.sol
└── truffle-config.js

```

## TO-DO

High level plans for major changes to project, most not yet started.

- Use oracle for RNG on the fly (e.g., from Wolfram Alfa using `provableAPI`).
- Provide a gas proxy such that the player only interacts with MetaMask when placing bets (i.e., the house pays the gas for hitting and standing). Should also mitigate risk of leaking information through OOG reverts.
- Implement upgradeability using a proxy contract.
- Separate betting and action functions entirely.
- Fix refunds for dealer Blackjack, other payout quirks - write a lot more payment tests.
- Gas optimization
- General refactoring
