const {run, network} = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();

    const StakeEnergy = await ethers.getContractFactory("StakeEnergy");
    const PowerReward = await ethers.getContractFactory("PowerReward");
    const StakingContract = await ethers.getContractFactory("StakingContract");

    const stakeToken = await StakeEnergy.deploy(ethers.parseEther("100000"));
    await stakeToken.waitForDeployment();
    const stakeAddress = await stakeToken.getAddress();

    const rewardToken = await PowerReward.deploy(ethers.parseEther("100000"));
    await rewardToken.waitForDeployment();
    const rewardAddress = await rewardToken.getAddress();

    const stakingContract = await StakingContract.deploy(stakeAddress, rewardAddress);
    await stakingContract.waitForDeployment();
    const stakingAddress = await stakingContract.getAddress();

    console.log("StakeEnergy (STK) Token Address:", stakeAddress);
    console.log("PowerReward (PWR) Token Address:", rewardAddress);
    console.log("Staking Contract Address:", stakingAddress);

    if (network.config.chainId === 11155111 && process.env.ETHERSCAN_API_KEY) {
        console.log("Waiting for 6 confirmations before verification...");
        await stakingContract.deploymentTransaction().wait(6);
        await verify(stakingAddress, [stakeAddress, rewardAddress]);
    }
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

async function verify(address, args) {
    try {
        await run("verify:verify", {
            address: address,
            constructorArguments: args,
        });
        console.log("Contract verified successfully!");
    } catch (e) {
        if (e.message.toLowerCase().includes("already verified")) {
            console.log("Already verified.");
        } else {
            console.error("Verification error:", e);
        }
    }
}
