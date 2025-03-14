require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config(); // Load environment variables

module.exports = {
  solidity: "0.8.20",
  networks: {
    sepolia: {
      url: process.env.SEPOLIA_RPC_URL, // Infura or Alchemy RPC URL
      //use the public key  --- edit it after the meeting
      accounts: [process.env.PRIVATE_KEY], // MetaMask private key
    },
  },
  // etherscan: {
  //   apiKey: process.env.ETHERSCAN_API_KEY, // For verifying contracts
  // },
};