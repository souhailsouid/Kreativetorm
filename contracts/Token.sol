// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FeeToken is ERC20, Ownable {
    uint256 public feePercent; // e.g., 1 means 1%
    uint256 public transferFeePercent = 1; // 1% fee for normal transfers
    uint256 public buyFeePercent = 2; // 2% fee for buying tokens
    uint256 public sellFeePercent = 3; // 3% fee for selling tokens

    address public marketplace; // Address of the marketplace/DEX for handling buys and sells

    constructor(
        uint256 initialSupply,
        uint256 _feePercent,
        address _marketplace
    ) ERC20("MyToken", "MTK") Ownable(msg.sender) {
        _mint(msg.sender, initialSupply);
        feePercent = _feePercent;
        marketplace = _marketplace; // Set marketplace/DEX address for buy/sell transactions
    }

    // Custom transfer function with fee logic
    function transfer(
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        uint256 fee = (amount * transferFeePercent) / 100;
        uint256 amountAfterFee = amount - fee;

        // Transfer the fee to the owner
        _transfer(_msgSender(), owner(), fee);
        // Transfer the remaining tokens to the recipient
        _transfer(_msgSender(), recipient, amountAfterFee);
        return true;
    }

    // Custom transferFrom function with fee logic
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        uint256 fee = (amount * transferFeePercent) / 100;
        uint256 amountAfterFee = amount - fee;

        // Deduct allowance for the full amount (including fee)
        uint256 currentAllowance = allowance(sender, _msgSender());
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        _approve(sender, _msgSender(), currentAllowance - amount);

        // Transfer the fee to the owner
        _transfer(sender, owner(), fee);
        // Transfer the remaining tokens to the recipient
        _transfer(sender, recipient, amountAfterFee);
        return true;
    }

    // Function to handle token buying with a 2% fee
    function buyTokens(address buyer, uint256 amount) external {
        require(
            _msgSender() == marketplace,
            "Only marketplace can call this function"
        );

        uint256 fee = (amount * buyFeePercent) / 100;
        uint256 amountAfterFee = amount - fee;

        // Transfer the fee to the owner
        _transfer(owner(), owner(), fee);
        // Transfer the remaining tokens to the buyer
        _transfer(owner(), buyer, amountAfterFee);
    }

    // Function to handle token selling with a 3% fee
    function sellTokens(address seller, uint256 amount) external {
        require(
            _msgSender() == marketplace,
            "Only marketplace can call this function"
        );

        uint256 fee = (amount * sellFeePercent) / 100;
        uint256 amountAfterFee = amount - fee;

        // Transfer the fee to the owner
        _transfer(seller, owner(), fee);
        // Burn the remaining tokens (simulate selling)
        _burn(seller, amountAfterFee);
    }

    // Function to update the marketplace/DEX address
    function setMarketplace(address _marketplace) external onlyOwner {
        marketplace = _marketplace;
    }

    // Function to adjust the fees dynamically
    function setFeePercent(
        uint256 _buyFeePercent,
        uint256 _sellFeePercent,
        uint256 _transferFeePercent
    ) external onlyOwner {
        buyFeePercent = _buyFeePercent;
        sellFeePercent = _sellFeePercent;
        transferFeePercent = _transferFeePercent;
    }
}
