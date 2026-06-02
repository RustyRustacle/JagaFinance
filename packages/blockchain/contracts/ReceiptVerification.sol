// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract ReceiptVerification {
    address public owner;
    uint256 public receiptCount;

    struct ReceiptRecord {
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
    ) external onlyOwner {
        require(_receiptHash != bytes32(0), "Invalid hash");
        require(!records[_receiptHash].exists, "Already exists");

        records[_receiptHash] = ReceiptRecord({
            tenantId: _tenantId,
            timestamp: block.timestamp,
            exists: true
        });

        tenantRecords[_tenantId].push(_receiptHash);
        receiptCount++;

        emit ReceiptVerified(_receiptHash, _tenantId, block.timestamp);
    }

    function getReceipt(
        bytes32 _receiptHash
    ) external view returns (ReceiptRecord memory) {
        return records[_receiptHash];
    }

    function getTenantReceipts(
        string calldata _tenantId,
        uint256 offset,
        uint256 limit
    ) external view returns (bytes32[] memory) {
        bytes32[] storage all = tenantRecords[_tenantId];
        uint256 end = offset + limit;
        if (end > all.length) end = all.length;
        if (offset >= all.length) return new bytes32[](0);
        bytes32[] memory result = new bytes32[](end - offset);
        for (uint256 i = offset; i < end; i++) {
            result[i - offset] = all[i];
        }
        return result;
    }

    function getTenantReceiptCount(
        string calldata _tenantId
    ) external view returns (uint256) {
        return tenantRecords[_tenantId].length;
    }

    function getReceiptCount() external view returns (uint256) {
        return receiptCount;
    }
}
