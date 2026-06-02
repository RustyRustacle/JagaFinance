import { ethers } from "ethers";

const CONTRACT_ADDRESS = process.env.BLOCKCHAIN_CONTRACT_ADDRESS || "";
const RPC_URL = process.env.BLOCKCHAIN_RPC_URL || "https://ethereum-sepolia.publicnode.com";
const PRIVATE_KEY = process.env.BLOCKCHAIN_PRIVATE_KEY || "";
const CHAIN_ID = process.env.BLOCKCHAIN_CHAIN_ID || "11155111";

const RECEIPT_VERIFICATION_ABI = [
  "function verifyReceipt(bytes32 _receiptHash, string calldata _tenantId) external",
  "function getReceipt(bytes32 _receiptHash) external view returns (tuple(string tenantId, uint256 timestamp, bool exists))",
  "function getTenantReceipts(string calldata _tenantId, uint256 offset, uint256 limit) external view returns (bytes32[])",
  "function getTenantReceiptCount(string calldata _tenantId) external view returns (uint256)",
  "event ReceiptVerified(bytes32 indexed receiptHash, string indexed tenantId, uint256 timestamp)",
];

let provider: ethers.JsonRpcProvider | null = null;
let signer: ethers.Wallet | null = null;
let contract: ethers.Contract | null = null;

function getProvider(): ethers.JsonRpcProvider {
  if (!provider) {
    provider = new ethers.JsonRpcProvider(RPC_URL, parseInt(CHAIN_ID), {
      staticNetwork: true,
    });
  }
  return provider;
}

function getSigner(): ethers.Wallet {
  if (!signer) {
    signer = new ethers.Wallet(PRIVATE_KEY, getProvider());
  }
  return signer;
}

function getContract(): ethers.Contract {
  if (!contract) {
    contract = new ethers.Contract(CONTRACT_ADDRESS, RECEIPT_VERIFICATION_ABI, getSigner());
  }
  return contract;
}

export function computeReceiptHash(
  receiptId: string,
  totalAmount: string,
  timestamp: string
): string {
  return ethers.keccak256(
    ethers.solidityPacked(
      ["string", "string", "string"],
      [receiptId, totalAmount, timestamp]
    )
  );
}

export interface BlockchainSubmissionResult {
  txHash: string;
  receiptHash: string;
  status: "PENDING" | "CONFIRMED" | "FAILED";
}

export async function submitReceiptToBlockchain(
  receiptId: string,
  tenantId: string,
  totalAmount: string,
  timestamp: string
): Promise<BlockchainSubmissionResult> {
  if (!CONTRACT_ADDRESS || !PRIVATE_KEY) {
    return {
      txHash: "",
      receiptHash: "",
      status: "FAILED",
    };
  }

  const receiptHash = computeReceiptHash(receiptId, totalAmount, timestamp);
  const c = getContract();

  try {
    const tx = await c.verifyReceipt(receiptHash, tenantId);
    const receipt = await tx.wait();

    return {
      txHash: receipt.hash,
      receiptHash,
      status: "CONFIRMED",
    };
  } catch (error) {
    console.error("Blockchain submission failed:", error);
    return {
      txHash: "",
      receiptHash,
      status: "FAILED",
    };
  }
}

export async function getBlockchainReceipt(
  receiptHash: string
): Promise<{ receiptHash: string; tenantId: string; timestamp: number; exists: boolean } | null> {
  if (!CONTRACT_ADDRESS) return null;

  try {
    const c = getContract();
    const record = await c.getReceipt(receiptHash);
    return {
      receiptHash: record.receiptHash,
      tenantId: record.tenantId,
      timestamp: Number(record.timestamp),
      exists: record.exists,
    };
  } catch {
    return null;
  }
}

export async function getTenantBlockchainReceipts(
  tenantId: string
): Promise<string[]> {
  if (!CONTRACT_ADDRESS) return [];

  try {
    const c = getContract();
    const hashes = await c.getTenantReceipts(tenantId);
    return hashes as string[];
  } catch {
    return [];
  }
}
