# IDProtocol

## Tech Stack

- Language: Solidity
- Testing and Deployment framework: Foundry

## Setup

0. Ensure that you have Rust and Foundry installed in your machine.
   - Rust installation instructions: [Rust install](https://www.rust-lang.org/tools/install).
   - Foundry installation instructions: [Foundry install](https://book.getfoundry.sh/getting-started/installation).

1. Install dependencies:

   ```shell
   # Install Foundry testing framework standard library
   sforge install foundry-rs/forge-std --no-commit  

   # Install Uniswap V3 core and periphery contracts
   sforge install uniswap/v3-core uniswap/v3-periphery --no-commit

   # Install Uniswap V2 core and periphery contracts
   sforge install uniswap/v2-core uniswap/v2-periphery --no-commit

   # Install OpenZeppelin core contracts
   sforge install OpenZeppelin/openzeppelin-contracts  --no-commit  

   ```

