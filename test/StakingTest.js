const {
  BN, // Big Number support
  constants, // Common constants, like the zero address and largest integers
  expectEvent, // Assertions for emitted events
  expectRevert, // Assertions for transactions that should fail
} = require("@openzeppelin/test-helpers");

const truffleAssert = require("truffle-assertions");
const { assert, expect } = require("chai");
const Token = artifacts.require("Token");
const Staking = artifacts.require("Staking");

require("chai").use(require("chai-bignumber")(BN)).should();

const denominator = new BN(10).pow(new BN(18));

const getWith18Decimals = function (amount) {
  return new BN(amount).mul(denominator);
};

var account1 = "0xD80087e4ebF828471dEa0377b3cC426b1f4bc5F6";

contract("Staking", () => {
  it("Should deploy smart contract properly", async () => {
    const token = await Token.deployed();
    const stake = await Staking.deployed(token.address);
    assert(stake.address !== "");
  });

  beforeEach(async function () {
    token = await Token.new();
    stake = await Staking.new([token.address]);
  });

  describe("[Testcase 1: To determine whether the token is listed or not]", () => {
    it("", async () => {
      assert.isTrue(await stake.listedToken.call(token.address));
    });
  });

  describe("[Testcase 2: To stake the token after being approved ]", () => {
    it("Stake Token ", async () => {
      await token.approve(stake.address, getWith18Decimals(10));
      assert.isTrue(
        await stake.stake.call(token.address, getWith18Decimals(10))
      );
    });
  });

  describe("[Testcase 3: To stake the token without being approved ]", () => {
    it("Stake Token ", async () => {
      try {
        assert.isFalse(
          await stake.stake.call(token.address, getWith18Decimals(10))
        );
      } catch (e) {}
    });
  });

  describe("[Testcase 4: To stake the token that has not been listed ]", () => {
    var _token = "0x3b4F6ab61e1e08Aa0889B7e1a73F88D30797300c";
    it("Stake Token ", async () => {
      await token.approve(stake.address, getWith18Decimals(10));
      try {
        assert.isFalse(
          await stake.stake.call(_token, getWith18Decimals(10)),
          "Trying to stake the token that has not been listed"
        );
      } catch (e) {}
    });
  });

  describe("[Testcase 5: To test the stake function]", () => {
    it("Stake", async () => {
      await token.approve(stake.address, getWith18Decimals(10));
      await stake.setAnnualMintPercentage(token.address, 500);
      result = await stake.stake.call(token.address, getWith18Decimals(10));
      console.log("Staking :", result.toString());
    });
  });

  describe("[Testcase 6: To claim the rewards and withdraw it ]", () => {
    it("Claiming of Rewards ", async () => {
      await token.approve(stake.address, getWith18Decimals(10));
      await stake.setAnnualMintPercentage(token.address, 500);
      await stake.stake(token.address, getWith18Decimals(10));
      try {
        assert.isTrue(
          await stake.claimRewardsOnlyAndWithDraw.call(token.address)
        );
      } catch (e) {}
    });
  });

  describe("[Testcase 7: To claim the rewards and restake it ]", () => {
    it("Claiming of Rewards ", async () => {
      await token.approve(stake.address, getWith18Decimals(10));
      await stake.setAnnualMintPercentage(token.address, 500);
      await stake.stake(token.address, getWith18Decimals(10));
      assert.isTrue(await stake.claimRewardsOnlyAndStake.call(token.address));
    });
  });

  describe("[Testcase 8: To claim the rewards of the unstaked token ]", () => {
    it("Claiming of Rewards ", async () => {
      var _token = "0x3b4F6ab61e1e08Aa0889B7e1a73F88D30797300c";
      await token.approve(stake.address, getWith18Decimals(10));
      await stake.setAnnualMintPercentage(token.address, 500);
      await stake.stake(token.address, getWith18Decimals(10));
      try {
        assert.isFalse(
          await stake.claimRewardsOnlyAndWithDraw.call(_token),
          "The token needs to staked before claiming any rewards"
        );
      } catch (e) {}
    });
  });

  describe("[Testcase 9: To test unstake the token ] ", () => {
    it("Unstake token", async () => {
      await token.approve(stake.address, getWith18Decimals(10));
      await stake.setAnnualMintPercentage(token.address, 500);
      await stake.stake(token.address, getWith18Decimals(10));
      assert.isTrue(await stake.unStake.call(token.address));
    });
  });

  describe("[Testcase 10: To add the Pay Nodes ] ", () => {
    it("PayNode", async () => {
      await token.approve(stake.address, getWith18Decimals(10));
      await stake.setAnnualMintPercentage(token.address, 500);
      await stake.stake(token.address, getWith18Decimals(10));
      await stake.setMinimumBalanceForPayNoder(
        token.address,
        getWith18Decimals(10)
      );
      await stake.setPayNoderSlot(token.address, 2);
      assert.isTrue(
        await stake.addaccountToPayNode.call(token.address, account1)
      );
    });
  });

  describe("[Testcase 11: To add already added PayNode for the token ] ", () => {
    it("PayNode", async () => {
      await token.approve(stake.address, getWith18Decimals(10));
      await stake.setAnnualMintPercentage(token.address, 500);
      await stake.stake(token.address, getWith18Decimals(10));
      await stake.setMinimumBalanceForPayNoder(
        token.address,
        getWith18Decimals(10)
      );
      await stake.setPayNoderSlot(token.address, 2);
      await stake.addaccountToPayNode(token.address, account1);
      try {
        assert.isFalse(
          await stake.addaccountToPayNode.call(token.address, account1)
        );
      } catch (e) {}
    });
  });

  describe("[Testcase 12: To add paynode whose balance is less than minimum balance ] ", () => {
    it("PayNode", async () => {
      await token.approve(stake.address, getWith18Decimals(5));
      await stake.setAnnualMintPercentage(token.address, 500);
      await stake.stake(token.address, getWith18Decimals(5));
      await stake.setMinimumBalanceForPayNoder(
        token.address,
        getWith18Decimals(10)
      );
      await stake.setPayNoderSlot(token.address, 2);
      try {
        assert.isFalse(
          await stake.addaccountToPayNode.call(token.address, account1)
        );
      } catch (e) {}
    });
  });

  describe("[Testcase 13: To remove the Pay Node ] ", () => {
    it("Removing the Pay Node", async () => {
      await token.approve(stake.address, getWith18Decimals(10));
      await stake.setAnnualMintPercentage(token.address, 500);
      await stake.stake(token.address, getWith18Decimals(10));
      await stake.setMinimumBalanceForPayNoder(
        token.address,
        getWith18Decimals(10)
      );
      await stake.setPayNoderSlot(token.address, 2);
      await stake.addaccountToPayNode(token.address, account1);
      assert.isTrue(
        await stake.removeaccountToPayNode.call(token.address, account1)
      );
    });
  });
});
