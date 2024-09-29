// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract FeeToken is ERC20, Ownable {
    using MerkleProof for bytes32[];
    bytes32 public merkleRoot;
    uint256 public feePercent; // e.g., 1 means 1%
    uint256 public transferFeePercent = 1; // 1% fee for normal transfers
    uint256 public buyFeePercent = 2; // 2% fee for buying tokens
    uint256 public sellFeePercent = 3; // 3% fee for selling tokens

    // address public marketplace; // Address of the marketplace/DEX for handling buys and sells
    mapping(address => uint256) private _balances;

    constructor(
        uint256 initialSupply,
        uint256 _feePercent
    ) ERC20("MyToken", "MTK") Ownable(msg.sender) {
        _mint(msg.sender, initialSupply);
        feePercent = _feePercent;
        // marketplace = _marketplace; // Set marketplace/DEX address for buy/sell transactions
    }

    modifier validTransfer(address recipient, uint256 amount) {
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(
            amount <= _balances[msg.sender],
            "ERC20: transfer amount exceeds balance"
        );
        require(amount > 0, "Transfer amount must be greater than zero");
        _;
    }

    // Custom transfer function with fee logic
    function transfer(
        address sender,
        address recipient,
        uint256 amount,
        bytes32[] calldata proof
    ) public validTransfer(recipient, amount) {
        require(
            isInvestedAddress(recipient, proof),
            "Recipient address is not invested"
        );
        uint256 fee = (amount * transferFeePercent) / 100;
        uint256 amountAfterFee = amount - fee;

        // Transfer the fee to the owner
        _transfer(sender, owner(), fee);

        _transfer(sender, recipient, amountAfterFee);

        emit TransferEvent(sender, recipient, amountAfterFee);
    }

    function setMerkleRoot(bytes32 _merkleRoot) external {
        merkleRoot = _merkleRoot;
    }

    function verifyMerkleProof(
        bytes32[] calldata proof,
        bytes32 leaf
    ) external view returns (bool) {
        return proof.verify(merkleRoot, leaf);
    }

    function isInvestedAddress(
        address recipient,
        bytes32[] calldata proof
    ) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(recipient));
        return proof.verify(merkleRoot, leaf);
    }

    event TransferEvent(
        address indexed from,
        address indexed to,
        uint256 value
    );
}
