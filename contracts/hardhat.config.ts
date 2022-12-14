import { HardhatUserConfig, task } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
require('dotenv').config();

const config: HardhatUserConfig = {
  solidity: "0.8.17",
  paths: { tests: "tests" },
  networks: {
    hardhat: {
        chainId: 31337,
    },
    goerli: {
        url: `https://eth-goerli.g.alchemy.com/v2/${process.env.ALCHEMY_KEY}`,
        accounts: process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
        chainId: 5,
    },
  },
  etherscan: {
    // yarn hardhat verify --network <NETWORK> <CONTRACT_ADDRESS> <CONSTRUCTOR_PARAMETERS>
    apiKey: {
        goerli: `${process.env.ETHERSCAN_API_KEY}`,
    },
},
};


task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});


export default config;
