# 🥗 Salad Bowl Smart Contracts

This repository contains smart contracts written in Solidity. These contracts are designed to facilitate staking, and reward claiming.

## 📜 Table of Contents

- [📚 Introduction](#-introduction)
- [🛠️ Installation](#%EF%B8%8F-installation)
- [🚀 Deployment](#-deployment)
- [🔍 Verification and Publishing](#-verification-and-publishing)
- [📖 Usage](#-usage)
- [🔍 Contracts Overview](#-contracts-overview)
- [📜 License](#-license)

## 📚 Introduction

This repository contains smart contracts for blockchain-based applications. These contracts are implemented using Solidity and are designed to be robust, secure, and easy to integrate.

## 🛠️ Installation


1. To get started, clone the repository 
    ```bash
    git clone https://github.com/Salad-Ventures/salad-bowl-smart-contracts.git
    ```

    ```bash
    cd salad-bowl-smart-contracts
    ```
2. Make sure you have Remix installed globally
    ```bash
    npm install -g remixd
    ```
3. Run Remix locally with the command below
     ```bash
     remixd
     ```
4. Head over to [Remix - Ethereum IDE](https://remix.ethereum.org/). Under Workspaces, select "connect to local workspace" followed by "connect"

   ![Screenshot 2024-06-18 at 4 45 19 PM](https://github.com/Salad-Ventures/salad-bowl-smart-contracts/assets/137877850/6807a4b8-1e52-42bc-8989-043b639b2e8c)


## 🚀 Deployment

1. In the Remix IDE, navigate to the "File Explorers" section and open the files from your connected local workspace.

2. Open the contract you want to deploy (e.g., `TokenStake.sol`).

3. Compile the contract:
    - Go to the "Solidity Compiler" tab.
    - Select the appropriate compiler version (`v0.8.20+commit.a1b79de6`).
    - Click "Compile".

4. Deploy the contract:
    - Go to the "Deploy & Run Transactions" tab.
    - Select the environment (e.g., "Injected Web3" to connect to MetaMask).
    - To deploy on a specific change, configure it accordingly on MetaMask (Head over to Metamask extension and connect the specific network).
    - Select the contract to deploy.
    - Enter any constructor argument required, and click "Deploy"
    - Confirm the transaction in MetaMask.
    - 🚀 Your contract will be deployed shortly after a successful transaction.


## 🔍 Verification and Publishing

To verify and publish your contract using Remix:

1. **Install the Etherscan plugin in Remix:**
    - Go to the "Plugin Manager" tab in Remix.
    - Search for "Etherscan" and click "Activate".

2. **Obtain an Etherscan API Key:**
    - Visit [Etherscan](https://etherscan.io/).
    - Log in to your account or create a new one if you don't have an account.
    - Go to the API Key page under your profile settings.
    - Generate a new API key and save it for later use.

3. **Verify the contract:**
    - After deploying your contract, click on the Etherscan Plugin.
    - Enter the Etherscan API key you obtained earlier.
    - Fill in the required information:
      - **Contract Address:** The address of the deployed contract.
      - **Contract Constructor Arguments:** Provide any constructor arguments used during deployment.
      - **Contract Name:** The name of the contract (e.g., `TokenStaking`).
      - **Compiler Version:** The version of the Solidity compiler used to compile the contract (e.g., `v0.8.20+commit.a1b79de6`).
      - **Optimization:** Indicate whether optimization was enabled during compilation.
    - Click "Verify".

4. **Review the verification status:**
    - After submitting the verification request, wait for the process to complete.
    - You will see the status of the verification on the Etherscan plugin page in Remix.

5. **Publish the contract:**
    - Once verified, your contract will be published on Etherscan with the source code and ABI available for public view.
    - You can now view your contract on Etherscan, which will show the verified source code, contract ABI, and other details.


## 📖 Usage

Once deployed, you can interact with the smart contracts directly within Remix:

### Example: Staking Tokens with `TokenStaking`

1. Ensure your deployed contract instance is selected in the "Deploy & Run Transactions" tab in Remix.

2. To stake tokens:
    - Find the `stake` function in the deployed contract section.
    - Enter the amount of tokens to stake (in wei).
    - Click "transact" and confirm the transaction in MetaMask.

3. To unstake tokens:
    - Find the `unstake` function in the deployed contract section.
    - Enter the amount of tokens to unstake (in wei).
    - Click "transact" and confirm the transaction in MetaMask.

4. To set a new token to be staked (owner only):
    - Find the `setStakeToken` function in the deployed contract section.
    - Enter the address of the new token to be staked.
    - Click "transact" and confirm the transaction in MetaMask.

5. To check the total supply of staked tokens:
    - Find the `totalSupply` function in the deployed contract section.
    - Click "call" to retrieve the total amount of tokens staked.

### Example: Claiming Rewards with `RewardClaim`

1. Ensure your deployed contract instance is selected in the "Deploy & Run Transactions" tab in Remix.

2. To claim rewards:
    - Find the `claimReward` function in the deployed contract section.
    - Enter the token address of the token you want to claim.
    - Enter the amount of rewards to claim.
    - Provide the signature for verification.
    - Click "transact" and confirm the transaction in MetaMask.

3. To set a new signer (owner only):
    - Find the `setSigner` function in the deployed contract section.
    - Enter the address of the new signer.
    - Click "transact" and confirm the transaction in MetaMask.

4. To add a claimable token (owner only):
    - Find the `addClaimableToken` function in the deployed contract section.
    - Enter the address of the reward token you want to add.
    - Click "transact" and confirm the transaction in MetaMask.

5. To remove a claimable token (owner only):
    - Find the `removeClaimableToken` function in the deployed contract section.
    - Enter the address of the reward token you want to remove.
    - Click "transact" and confirm the transaction in MetaMask.

## 🔍 Contracts Overview

### 📄 TokenStaking

The `TokenStaking` contract allows users to stake and unstake tokens.

- **Functions:**
  - `stake(uint256 amount)`: Stakes a specified amount of tokens.
  - `unstake(uint256 amount)`: Unstakes a specified amount of tokens.
  - `setStakeToken(address _stakeToken)`: Sets the staking token address.
  - `setStakingActive(bool isActive)`: Activates or deactivates staking.
  - `setOwner(address _owner)`: Sets a new owner.
  - `totalSupply()`: Returns the total staked amount.
  - `name()`: Returns the name of the staking token.
  - `symbol()`: Returns the symbol of the staking token.
  - `decimals()`: Returns the decimals of the staking token.

### 📄 RewardClaim

The `RewardClaim` contract allows users to claim rewards in ERC20 tokens.

- **Functions:**
  - `claimReward(uint256 amount, token address, bytes memory signature)`: Claims rewards for the user.
  - `setSigner(address _signer)`: Sets the signer address.
  - `addClaimableToken(address _token)`: Sets the reward token address.
  - `removeClaimableToken(address _token)`: Sets the reward token address.

## 📜 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

