const { ethers } = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contract with account:", deployer.address);

    const GymMembership = await hre.ethers.getContractFactory("GymMembership");
    const gymMembership = await GymMembership.deploy(
        "0x58FA6f7646C077cCaF3A7016a830c1125743e993" // Replace with your ERC-20 token address
    );

    await gymMembership.waitForDeployment();

    const contractAddress = await gymMembership.getAddress();
    const contractAbi = await JSON.stringify(GymMembership.interface.fragments);


    console.log("GymMembership contract deployed to:", contractAddress);
    console.log("GymMembership contract abi:", contractAbi);
    console.log("GymMembership contract details:", gymMembership);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

