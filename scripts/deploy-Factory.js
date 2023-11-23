//require("@nomicfoundation/hardhat-toolbox");
const hre = require("hardhat");
const { ethers } = require("ethers");
require("dotenv").config({ path: ".env" });

async function main()  {

    const LockManager = await hre.ethers.getContractFactory("LockManager");
    //console.log(getContractFactory, "Mysterious");
    // Here, we tell hardhat which contract we want to deploy.
    // Hardhat then knows how to handle the signer and cotract
    const lockManager = await LockManager.deploy();
    //const receipt = await factory.deploy();
    //console.log("Receit", receipt);
    console.log("lockManager", lockManager);
    // deploying the contract
    const deployedLockManager = await lockManager.deployed();
    console.log("lockManager deployed to:", lockManager.address);
    console.log("deployed", deployedLockManager.address);
};   

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});        