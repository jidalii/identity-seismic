import { createShieldedPublicClient, createShieldedWalletClient, shieldedWriteContract, seismicDevnet, sanvil } from 'seismic-viem';
import { privateKeyToAccount } from 'viem/accounts';
import IDProtocolABI from '../contracts/build/IDProtocol.json';
import MerchantContractABI from '../contracts/build/MerchantContract.json';
import MockOracleABI from '../contracts/build/MockOracle.json';
import VerifierABI from '../contracts/build/Verifier.json';
import { Command } from 'commander';
import dotenv from 'dotenv';

dotenv.config();
const program = new Command();

// Initialize Ethereum clients
const publicClient = createShieldedPublicClient({
  process.env.CHAIN_ID === sanvil.id.toString() ? sanvil : seismicDevnet
});

const walletClient = createShieldedWalletClient({
  account: privateKeyToAccount(process.env.PRIVATE_KEY! as `0x${string}`),
  process.env.CHAIN_ID === sanvil.id.toString() ? sanvil : seismicDevnet
});


const IDProtocolAddress = process.env.ID_PROTOCOL_ADDRESS as `0x${string}`;
const MerchantContractAddress = process.env.MERCHANT_CONTRACT_ADDRESS as `0x${string}`;
const MockOracleAddress = process.env.MOCK_ORACLE_ADDRESS as `0x${string}`;
const VerifierAddress = process.env.VERIFIER_ADDRESS as `0x${string}`;

// Utility function for error handling
async function safeExecute(fn: Function, ...args: any[]) {
  try {
    const result = await fn(...args);
    console.log("\n[Success]:", result);
  } catch (error) {
    console.error("\n[Error]:", error.message || error);
  }
}

// Example function to interact with IDProtocol
async function getMerchantName() {
  return await publicClient.readContract({
    address: IDProtocolAddress!,
    abi: IDProtocolABI,
    functionName: "name",
  });
}

async function registerMerchant(name: string) {
  return await walletClient.shieldedWriteContract({
    address: IDProtocolAddress!,
    abi: IDProtocolABI,
    functionName: "registerMerchant",
    args: [name],
  });
}

async function verifyProof(proof: string) {
  return await publicClient.readContract({
    address: VerifierAddress!,
    abi: VerifierABI,
    functionName: "verify",
    args: [proof],
  });
}

async function getTokenPrice(tokenAddress: string) {
  return await publicClient.readContract({
    address: MockOracleAddress!,
    abi: MockOracleABI,
    functionName: "oracle",
    args: [tokenAddress],
  });
}

program
  .command("merchant-name")
  .description("Get the merchant name")
  .action(async () => {
    await safeExecute(getMerchantName);
  });

program
  .command("register-merchant <name>")
  .description("Register a new merchant")
  .action(async (name) => {
    await safeExecute(registerMerchant, name);
  });

program
  .command("verify-proof <proof>")
  .description("Verify a proof using the Verifier contract")
  .action(async (proof) => {
    await safeExecute(verifyProof, proof);
  });

program
  .command("token-price <tokenAddress>")
  .description("Get the price of a token from the Mock Oracle")
  .action(async (tokenAddress) => {
    await safeExecute(getTokenPrice, tokenAddress);
  });

program.parse(process.argv);
