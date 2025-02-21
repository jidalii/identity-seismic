package main

import (
	"fmt"
	"os"

	"identity-zk/utils"

	"github.com/consensys/gnark-crypto/ecc"
	"github.com/consensys/gnark/backend/groth16"
	"github.com/consensys/gnark/backend/witness"
)

func main() {
	vk := groth16.NewVerifyingKey(ecc.BN254)
	utils.ReadFile(vk, "../compiled_bin/02-vk.bin")

	file, err := os.Create("verifier.sol")
	if err != nil {
		panic(err)
	}
	if err = vk.ExportSolidity(file); err != nil {
		panic(err)
	}


	proof := groth16.NewProof(ecc.BN254)
	utils.ReadFile(proof, "../prover/02-proof.bin")

    fmt.Println(proof)


	publicWitness, err := witness.New(ecc.BN254.ScalarField())
	if err != nil {
		panic(err)
	}
	utils.ReadFile(publicWitness, "../prover/02-public_witness.bin")

	if err := groth16.Verify(proof, vk, publicWitness); err != nil {
		panic(err)
	}
}

func convertProofToSolidityArray(proof groth16.Proof) []int {
	return []int{
		int(proof[0].Uint64()),
	}
}
