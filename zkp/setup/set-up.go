package main

import (
	"fmt"
	"identity-zk/circuit"
	"identity-zk/utils"

	"github.com/consensys/gnark-crypto/ecc"
	"github.com/consensys/gnark/backend/groth16"
	"github.com/consensys/gnark/frontend"
	"github.com/consensys/gnark/frontend/cs/r1cs"
)

func main() {
	var circuit circuit.IdentityCheckCircuit
	cs, err := frontend.Compile(ecc.BN254.ScalarField(), r1cs.NewBuilder, &circuit)
	if err != nil {
		panic(err)
	}

	pk, vk, err := groth16.Setup(cs)
	if err != nil {
		return
	}
	
	path := "../compiled_bin"

	utils.WriteFile(cs, fmt.Sprintf("%s/01-cs.bin", path))
	utils.WriteFile(pk, fmt.Sprintf("%s/01-pk.bin", path))
	utils.WriteFile(vk, fmt.Sprintf("%s/02-vk.bin", path))

	fmt.Printf("cs sha256: %x\n", utils.FileSHA256(fmt.Sprintf("%s/01-cs.bin", path)))
	fmt.Printf("pk sha256: %x\n", utils.FileSHA256(fmt.Sprintf("%s/01-pk.bin", path)))
	fmt.Printf("vk sha256: %x\n", utils.FileSHA256(fmt.Sprintf("%s/02-vk.bin", path)))
}
