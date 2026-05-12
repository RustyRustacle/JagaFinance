import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying with account:", deployer.address);
  console.log("Balance:", (await deployer.provider.getBalance(deployer.address)).toString());

  const ReceiptVerification = await ethers.getContractFactory("ReceiptVerification");
  const contract = await ReceiptVerification.deploy();
  await contract.waitForDeployment();

  const address = await contract.getAddress();
  console.log("ReceiptVerification deployed to:", address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
