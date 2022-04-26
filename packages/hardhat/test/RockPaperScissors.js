const { ethers } = require("hardhat");
const { use, expect } = require("chai");
const { solidity } = require("ethereum-waffle");

use(solidity);

describe("My Dapp", function () {
  let rockPaperScissors;

  // quick fix to let gas reporter fetch data from gas station & coinmarketcap
  before((done) => {
    setTimeout(done, 2000);
  });

  beforeEach(async function () {
    const RockPaperScissors = await ethers.getContractFactory("RockPaperScissors");

    rockPaperScissors = await RockPaperScissors.deploy(1, "0xd8da6bf26964af9d7eed9e03e53415d37aa96045", 10);

    await rockPaperScissors.deployed();

  });

  describe("RockPaperScissors", async function () {
    it("should add a userBet correctly", async function () {
      const [owner] = await ethers.getSigners();

      const bet = 1;
      const round = 0;

      await rockPaperScissors.shoot(bet, { value: ethers.utils.parseEther("0.01") });

      const userBet = await rockPaperScissors['getUserBet(uint256)'](round);

      expect(userBet.bet).to.equal(bet);
      expect(userBet.claimed).to.be.false;
      expect(userBet.exists).to.be.true;
      expect(userBet.round.toNumber()).to.equal(round);
    });

    it("should revert if bet placed is invalid", async function () {
      const bet = 20;

      await expect(rockPaperScissors.shoot(bet, { value: ethers.utils.parseEther("0.01") })).to.revertedWith("Invalid bet placed");
    });

    it("should revert if bet amount is too high", async function () {
      await expect(rockPaperScissors.shoot(2, { value: ethers.utils.parseEther("1") })).to.revertedWith("Invalid bet amount sent");
    });

    it("should revert if bet amount is too low", async function () {
      await expect(rockPaperScissors.shoot(2, { value: ethers.utils.parseEther("0.001") })).to.revertedWith("Invalid bet amount sent");
    });

    it("should revert if user already betted this round", async function () {
      const bet = 2;
      await rockPaperScissors.shoot(bet, { value: ethers.utils.parseEther("0.01") });
      await expect(rockPaperScissors.shoot(bet, { value: ethers.utils.parseEther("0.01") })).to.revertedWith("Bet already placed for this round");
    });
  });
});
