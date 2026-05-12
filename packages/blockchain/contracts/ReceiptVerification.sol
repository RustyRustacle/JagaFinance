// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract ReceiptVerification {
    address public owner;
    uint256 public receiptCount;

    struct ReceiptRecord {
        bytes32 receiptHash;
        string tenantId;
        uint256 timestamp;
        bool exists;
    }

    mapping(bytes32 => ReceiptRecord) public records;
    mapping(string => bytes32[]) public tenantRecords;

    event ReceiptVerified(
        bytes32 indexed receiptHash,
        string indexed tenantId,
        uint256 timestamp
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function verifyReceipt(
        bytes32 _receiptHash,
        string calldata _tenantId
    ) external {
        require(_receiptHash != bytes32(0), "Invalid hash");
        require(!records[_receiptHash].exists, "Already exists");

        records[_receiptHash] = ReceiptRecord({
            receiptHash: _receiptHash,
            tenantId: _tenantId,
            timestamp: block.timestamp,
            exists: true
        });

        tenantRecords[_tenantId].push(_receiptHash);

        emit ReceiptVerified(_receiptHash, _tenantId, block.timestamp);
    }

    function getReceipt(
        bytes32 _receiptHash
    ) external view returns (ReceiptRecord memory) {
        return records[_receiptHash];
    }

    function getTenantReceipts(
        string calldata _tenantId
    ) external view returns (bytes32[] memory) {
        return tenantRecords[_tenantId];
    }

    function getReceiptCount() external view returns (uint256) {
        return receiptCount;
    }
}
