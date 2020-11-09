const path = require("path");

module.exports = {
    // See <http://truffleframework.com/docs/advanced/configuration>
    // to customize your Truffle configuration!
    contracts_build_directory: path.join(__dirname, "client/src/contracts"),

    compilers: {
        solc: {
            version: "0.7.4",    // Fetch exact version from solc-bin (default: truffle's version)
        }
    },


    networks: {
        development: {
            host: "127.0.0.1",
            port: "8545",
            network_id: "*"
        }
    }
};