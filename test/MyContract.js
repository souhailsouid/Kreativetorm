const { expect } = require("chai");

describe("FeeToken", function () {
    let FeeToken, feeToken, owner, addr1, addr2, marketplace;

    beforeEach(async function () {
        [owner, addr1, addr2, marketplace] = await ethers.getSigners();
        FeeToken = await ethers.getContractFactory("FeeToken");
        console.log('deploying marketplace');

        feeToken = await FeeToken.deploy(1000, 1, marketplace.address); // Initial supply: 1000, Fee: 1%
        await feeToken.waitForDeployment();
        console.log(JSON.stringify(feeToken.marketplace, null, 2));
    });

    it("Should initialize the contract with correct values", async function () {
        expect(await feeToken.name()).to.equal("MyToken");
        expect(await feeToken.symbol()).to.equal("MTK");
        expect(await feeToken.totalSupply()).to.equal(1000);
        expect(await feeToken.balanceOf(owner.address)).to.equal(1000);
        expect(await feeToken.marketplace()).to.equal(marketplace.address);
    });
    
  
    it("Should transfer tokens with a 1% fee", async function () {
        // Owner transfers 100 tokens to addr1
        await feeToken.transfer(addr1.address, 100);

        // 1% fee deducted (1 token), so addr1 receives 99 tokens
        expect(await feeToken.balanceOf(addr1.address)).to.equal(99);
        // Owner receives 1 token as fee
        expect(await feeToken.balanceOf(owner.address)).to.equal(901);
    });
    it("Should apply a 2% fee on buying tokens", async function () {
        // Simulate a buy where addr1 buys 100 tokens
        await feeToken.connect(marketplace).buyTokens(addr1.address, 100);

        // 2% fee deducted (2 tokens), so addr1 receives 98 tokens
        expect(await feeToken.balanceOf(addr1.address)).to.equal(98);
        // Owner receives 2 tokens as fee
        expect(await feeToken.balanceOf(owner.address)).to.equal(902);
    });
    it("Should apply a 3% fee on selling tokens", async function () {
        // Step 1: Transfer tokens to addr1 so they have tokens to sell
        await feeToken.transfer(addr1.address, 100); // Transfer 100 tokens to addr1
    
        // Step 2: Log balance of addr1 to verify they received the tokens
        console.log("Balance of addr1 before selling:", await feeToken.balanceOf(addr1.address));
    
        // Step 3: Connect marketplace signer and simulate a sale by addr1
        await feeToken.connect(marketplace).sellTokens(addr1.address, 99); // Simulate selling 100 tokens via marketplace
    
        // Step 4: Log balance of addr1 after the sale (should be 0 as all tokens were sold)
        console.log("Balance of addr1 after selling:", await feeToken.balanceOf(addr1.address));
    
        // Step 5: Verify the expected results
        // addr1 should have 0 tokens (since they sold all)
        expect(await feeToken.balanceOf(addr1.address)).to.equal(0);
    
        // // Owner should have received the 3% fee from the sale (which is 3 tokens)
        expect(await feeToken.balanceOf(owner.address)).to.equal(903); // Owner initially had 900 tokens, and received 3 as a fee
    });
    
    it("Should allow the owner to adjust the fee percentages", async function () {
        // Set new fees: 3% for buy, 4% for sell, 2% for transfer
        await feeToken.setFeePercent(3, 4, 2);

        // Check that the fee percentages have been updated
        expect(await feeToken.buyFeePercent()).to.equal(3);
        expect(await feeToken.sellFeePercent()).to.equal(4);
        expect(await feeToken.transferFeePercent()).to.equal(2);
    });
    it("Should only allow the marketplace to call buyTokens and sellTokens", async function () {
        // addr1 should not be able to call buyTokens or sellTokens directly
        await expect(feeToken.connect(addr1).buyTokens(addr1.address, 100)).to.be.revertedWith("Only marketplace can call this function");
        await expect(feeToken.connect(addr1).sellTokens(addr1.address, 100)).to.be.revertedWith("Only marketplace can call this function");
    });

});
