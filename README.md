# Blackjack dApp

Blackjack game run on the Ethereum blockchain using `web3.js` and React web framework.

Planning to put this on mainnet and stake it for some small amount, and see what happens, after thoroughly testing. For now, this project is run locally on a development server at http://127.0.0.1:3000.

### Getting started

This project and guide are built and tested on an Ubuntu 18.04 virtual machine. I'm using `ganache-cli` for local Ethereum blockchain deployment and `Metamask` for wallet management. 

#### Prerequisites

First install required software, `node.js` and `npm`, `Solidity` compiler, `Truffle` suite, and `Ganache` if you don't already have these. 

```
cd ~
curl -sL https://deb.nodesource.com/setup_10.x -o nodesource_setup.sh
sudo bash nodesource_setup.sh
sudo apt install -y nodejs
sudo add-apt-repository ppa:ethereum/ethereum
sudo apt update
sudo apt install -y solc
sudo npm install -g truffle
sudo npm install -g ganache-cli
```

#### Installation

```
mkdir ~/blackjack

...

git clone ...

...

cd ~/blackjack
```


#### Starting up

First run a local test Ethereum blockchain with `ganache-cli`. Then connect `Metamask` to the local blockchain using the provided **mnemonic**. Then run the following.

```
truffle migrate
cd client
npm run start
```

### Deployed addresses

See [deployed_addresses.md](deployed_addresses.md "Deployed addresses") for details on where to find this contract publicly.

### Game rules

- Single deck
- Shuffle after each hand
- Dealer hits on soft 17

- Double any first two cards
- Double after split
- Split only once
- Cannot hit split aces

- Blackjack pays 3:2
- Late surrender refunds 1:2
- No Insurance

### Contract design

See [design_pattern_decisions.md](design_pattern_decisions.md "Design pattern decisions") for details on the following:
- Access control
- Upgradeability 
- Circuit breakers
- Mortality

### Contract security

See [avoiding_common_attacks.md](avoiding_common_attacks.md "Avoiding common attacks") for details on the following:
- Integer overflow/underflow
- Reentrancy
- Deck shuffling randomness 
- Card reveal scheme
- Payment strategy

### Project structure

This is a `truffle` project using a `React` front-end, built from the truffle react box. The project directory is constructed as follows:

```
.
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
│   │   │   └── Migrations.json
│   │   ├── getWeb3.js
│   │   ├── index.css
│   │   ├── index.js
│   │   ├── logo.svg
│   │   └── serviceWorker.js
│   └── yarn.lock
├── contracts
│   ├── Blackjack.sol
│   └── Migrations.sol
├── LICENSE
├── migrations
│   ├── 1_initial_migration.js
│   └── 2_deploy_contracts.js
├── package-lock.json
├── README.md
├── test
│   └── TestBlackjack.sol
└── truffle-config.js

```
