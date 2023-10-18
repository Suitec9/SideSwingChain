const hre = require("hardhat");

async function main() {

    const ProxyClone = await hre.ethers.getcontractfactory("ProxyClone");

    const proxycloneDeployer = await ProxyClone.deploy();

  await proxycloneDeployer.waitForDeployment();

  console.log("proxycloneDeployer deployed to:", ProxyClone);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
