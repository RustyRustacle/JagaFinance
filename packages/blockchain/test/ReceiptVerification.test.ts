import { expect } from "chai";
import { ethers } from "hardhat";
import { ReceiptVerification } from "../typechain-types";

describe("ReceiptVerification", function () {
  let contract: ReceiptVerification;

  beforeEach(async function () {
    const factory = await ethers.getContractFactory("ReceiptVerification");
    contract = (await factory.deploy()) as unknown as ReceiptVerification;
    await contract.waitForDeployment();
  });

  it("should deploy with owner set", async function () {
    const [owner] = await ethers.getSigners();
    expect(await contract.owner()).to.equal(owner.address);
  });

  it("should verify a receipt", async function () {
    const receiptHash = ethers.keccak256(ethers.toUtf8Bytes("test-receipt-1"));
    const tenantId = "tenant-1";

    await contract.verifyReceipt(receiptHash, tenantId);

    const record = await contract.getReceipt(receiptHash);
    expect(record.exists).to.be.true;
    expect(record.tenantId).to.equal(tenantId);
    expect(record.receiptHash).to.equal(receiptHash);
  });

  it("should increment receiptCount on verification", async function () {
    const receiptHash1 = ethers.keccak256(ethers.toUtf8Bytes("receipt-1"));
    const receiptHash2 = ethers.keccak256(ethers.toUtf8Bytes("receipt-2"));

    await contract.verifyReceipt(receiptHash1, "tenant-1");
    expect(await contract.getReceiptCount()).to.equal(1);

    await contract.verifyReceipt(receiptHash2, "tenant-1");
    expect(await contract.getReceiptCount()).to.equal(2);
  });

  it("should reject duplicate receipt hash", async function () {
    const receiptHash = ethers.keccak256(ethers.toUtf8Bytes("unique-receipt"));

    await contract.verifyReceipt(receiptHash, "tenant-1");
    await expect(
      contract.verifyReceipt(receiptHash, "tenant-2")
    ).to.be.revertedWith("Already exists");
  });

  it("should return tenant receipts", async function () {
    const hash1 = ethers.keccak256(ethers.toUtf8Bytes("r1"));
    const hash2 = ethers.keccak256(ethers.toUtf8Bytes("r2"));

    await contract.verifyReceipt(hash1, "tenant-a");
    await contract.verifyReceipt(hash2, "tenant-a");

    const hashes = await contract.getTenantReceipts("tenant-a");
    expect(hashes.length).to.equal(2);
  });
});
