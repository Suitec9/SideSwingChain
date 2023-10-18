require("@nomicfoundation/hardhat-toolbox");
//require("@nomiclabs/hardhat-ethers");
require("dotenv").config({ path: ".env" });


const SCROLL_SEPOLIA_API_KEY_URL = process.env.SCROLL_SEPOLIA_API_KEY_URL;
const SCROLL_SEPOLIA_WALLET_KEY = process.env.SCROLL_SEPOLIA_WALLET_KEY;
const ETHERSCAN_SCROLL_SEPOLIA_KEY= process.env.SCROLL_SEPOLIA_ETHERSCAN_KEY;
const ALCHEMY_OPTIMISM_API_KEY_URL = process.env.ALCHEMY_OPTIMISM_API_KEY_URL
const OPTIMISM_WALLET_KEY = process.env.OPTIMISM_WALLET_KEY;
const ETHERSCAN_OPTIMISM_KEY= process.env.OPTIMISM_ETHERSCAN_KEY;
const ALCHEMY_API_KEY_URL = process.env.ALCHEMY_API_KEY_URL;
const MUMBAI_PRIVATE_KEY = process.env.MUMBAI_PRIVATE_KEY;
const POLYGONSCAN_KEY = process.env.POLYGONSCAN_KEY;

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.19",
  networks: {
    scroll: {
      url: SCROLL_SEPOLIA_API_KEY_URL,
      accounts: [SCROLL_SEPOLIA_WALLET_KEY],
    },
    optimism: {
      url: ALCHEMY_OPTIMISM_API_KEY_URL,
      account: [OPTIMISM_WALLET_KEY],
      
    },
    mumbai: {
      url: ALCHEMY_API_KEY_URL,
      accounts: [MUMBAI_PRIVATE_KEY],
    }
   
  },
  
  etherscan: {
    apiKey: {
      scroll: ETHERSCAN_SCROLL_SEPOLIA_KEY, // Zora's API key
      optimismGoerli: ETHERSCAN_OPTIMISM_KEY, // Etherscan API key 
      polygonMumbai: POLYGONSCAN_KEY
    }
  }
};
