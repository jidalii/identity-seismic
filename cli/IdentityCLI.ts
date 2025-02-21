import { createShieldedPublicClient, createShieldedWalletClient, http } from 'seismic-viem';
import { privateKeyToAccount } from 'viem/accounts';
import { abi as IDProtocolABI } from '../contracts/build/IDProtocol.json';
import { abi as MerchantContractABI } from '../contracts/build/MerchantContract.json';
import { abi as MockOracleABI } from '../contracts/build/MockOracle.json';
import { abi as VerifierABI } from '../contracts/build/Verifier.json';
import { Command } from 'commander';
import dotenv from 'dotenv';

dotenv.config();
const program = new Command();

// Initialize Ethereum clients
const publicClient = createShieldedPublicClient({
  transport: http(process.env.RPC_URL),
});

const walletClient = createShieldedWalletClient({
  transport: http(process.env.RPC_URL),
  account: privateKeyToAccount(process.env.PRIVATE_KEY!),
});

const IDProtocolAddress = process.env.ID_PROTOCOL_ADDRESS;
const MerchantContractAddress = process.env.MERCHANT_CONTRACT_ADDRESS;
const MockOracleAddress = process.env.MOCK_ORACLE_ADDRESS;
const VerifierAddress = process.env.VERIFIER_ADDRESS;

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
  return await walletClient.writeContract({
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
