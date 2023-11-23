require("dotenv").config({ path: ".env" });
const  { ethers } = require("hardhat");
//const { hre } = require("hardhat");
//require("@nomicfoundation/hardhat-toolbox");//
const { byteCode } = require("../artifacts/contracts/LockManager.sol/LockManager.json");
const { encoder, create2address } = require("../utils/utils.js");

async function main() {
  const factoryAddr = "0xC29be05E775dbB6B837bE6F399C3f282139b8d73";
  //console.log(_owner, "evaluate assess");
  const saltHex = ethers.utils.id("12345");
  console.log(saltHex, "defining");
  const initCode = byteCode + encoder(['string']);
  console.log(initCode, "where thee paper");
  console.log(encoder, "hello Big Booty"); 

  const create2Addr =  create2address(factoryAddr, saltHex, initCode);
  console.log("precomputed address:", create2Addr);//

  const Factory = await ethers.getContractFactory("DeterministicDeployFactory");
  const factory =  await Factory.attach(factoryAddr);
  console.log(Factory, "where is the money??");
 
  // Set higher default limit
  //const provider = new ethers.providers.JsonRpcProvider(); 
  //provider.gasLimit = 120_000_000;
   
  const lockManager = await factory.deploy(initCode, saltHex);
  console.log(lockManager, "hello world")
  lockManager.gasLimit = 30_000_000;
  const txReceipt = await lockManager.wait();
//  console.log("Deployed to:", txReceipt.events[0]);
 
 let deployedAddr;
  try {
    const deployEvent = txReceipt.events[0];
    deployedAddr = deployEvent.args[0];
  } catch (err) {
    console.log('Error parsing deploy event:', err);
  }
  
};
// We recommend this pattern to be able to use async/await everywhere
  // and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1; 
});