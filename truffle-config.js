const path = require("path");



const HDWalletProvider = require('@truffle/hdwallet-provider');
const infuraURL = 'https://rinkeby.infura.io/v3/7291b19128f64740ac9da315b3e0bc91'
const infuraKey = fs.readFileSync(".infuraProjectSecret").toString().trim();

const fs = require('fs');
const mnemonic = fs.readFileSync(".metamaskWalletMnemonic").toString().trim();

module.exports = {
    // See <http://truffleframework.com/docs/advanced/configuration>
    // to customize your Truffle configuration!
    contracts_build_directory: path.join(__dirname, "client/src/contracts"),

    compilers: {
        solc: {
            version: "0.6.12",    // Fetch exact version from solc-bin (default: truffle's version)
            optimizer: {
                enabled: true,
                runs: 200,
            },
        },
    },

    networks: {

        development: {
            host: "127.0.0.1",
            port: "8545",
            network_id: "*",
            gas: 5500000,
        },

        //rinkeby: {
        //    provider: () => new HDWalletProvider(mnemonic, infuraURL),
        //    network_id: 4,       // Rinkeby's network id
        //    gas: 5500000,
        //},

    },
};
