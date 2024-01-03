require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.19",

  networks: {
    mainnet: {
      url: "https://polygon-mainnet.infura.io/v3/" + process.env.INFURA_KEY,
      accounts: [`${process.env.PRIVATE_KEY}`],
    },
    hardhat: {
      accounts: {
        count: 5
      }
    }
  }, 
  etherscan: {
    apiKey: process.env.POLYGONSCAN_KEY,
  }
};

// command to deploy with arguments
// # npx hardhat run --network mainnet scripts/deploy_mgp.js

// command to verify
// # npx hardhat verify <Contract Address> --network mainnetc <arg1> <arg2>