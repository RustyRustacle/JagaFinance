import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying with account:", deployer.address);

  const balance = await deployer.provider.getBalance(deployer.address);
  console.log("Balance:", ethers.formatEther(balance), "ETH");

  if (balance === 0n) {
    throw new Error("Deployer account has no balance. Fund it first.");
  }

  const ReceiptVerification = await ethers.getContractFactory("ReceiptVerification");
  const contract = await ReceiptVerification.deploy();
  await contract.waitForDeployment();

  const address = await contract.getAddress();
  console.log("ReceiptVerification deployed to:", address);

  const receiptCount = await contract.getReceiptCount();
  console.log("Initial receipt count:", receiptCount.toString());

  console.log("\nAdd these to your .env:");
  console.log(`BLOCKCHAIN_CONTRACT_ADDRESS="${address}"`);
  console.log(`BLOCKCHAIN_CHAIN_ID="84532"`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
