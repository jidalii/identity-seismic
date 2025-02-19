package main

import (
	"fmt"
	"math/big"

	"github.com/consensys/gnark-crypto/ecc"
	"github.com/consensys/gnark-crypto/ecc/bn254/fr"
	"github.com/consensys/gnark-crypto/hash"
	"github.com/consensys/gnark/backend/groth16"
	"github.com/consensys/gnark/frontend"
	_ "github.com/consensys/gnark/std/math/bits"

	"identity-zk/circuit"
	"identity-zk/utils"
)

type IdentityUpdateReq struct {
	Owner           string
	IsGithub        int
	GithubStar      int
	IsTwitter       int
	TwitterFollower int
	TotalStaked     int
	Balance         int
	TxnFrequency    int
	LastUpdated     int
}

func (i IdentityUpdateReq) ToString() string {
	return fmt.Sprintf("%s%d%d%d%d%d%d%d%d",
		i.Owner,
		i.IsGithub,
		i.GithubStar,
		i.IsTwitter,
		i.TwitterFollower,
		i.TotalStaked,
		i.Balance,
		i.TxnFrequency,
		i.LastUpdated)
}

func (i IdentityUpdateReq) ToArray() []string {
	arr := make([]string, 9)
	arr[0] = i.Owner
	arr[1] = fmt.Sprintf("%d", i.IsGithub)
	arr[2] = fmt.Sprintf("%d", i.GithubStar)
	arr[3] = fmt.Sprintf("%d", i.IsTwitter)
	arr[4] = fmt.Sprintf("%d", i.TwitterFollower)
	arr[5] = fmt.Sprintf("%d", i.TotalStaked)
	arr[6] = fmt.Sprintf("%d", i.Balance)
	arr[7] = fmt.Sprintf("%d", i.TxnFrequency)
	arr[8] = fmt.Sprintf("%d", i.LastUpdated)
	return arr
}

func (i IdentityUpdateReq) ToCircuit() circuit.IdentityCheckCircuit {
	return circuit.IdentityCheckCircuit{
		Owner:           i.Owner,
		IsGithub:        i.IsGithub,
		GithubStar:      i.GithubStar,
		IsTwitter:       i.IsTwitter,
		TwitterFollower: i.TwitterFollower,
		TotalStaked:     i.TotalStaked,
		Balance:         i.Balance,
		TxnFrequency:    i.TxnFrequency,
		LastUpdated:     i.LastUpdated,
	}
}

func main() {
	cs := groth16.NewCS(ecc.BN254)
	utils.ReadFile(cs, "../trust-setup/01-cs.bin")

	pk := groth16.NewProvingKey(ecc.BN254)
	utils.ReadFile(pk, "../trust-setup/01-pk.bin")

	req := IdentityUpdateReq{
		Owner:           "221bA23331E5395F2018eDafc2E0E9fF2Acb1aDa",
		IsGithub:        1,
		GithubStar:      203,
		IsTwitter:       1,
		TwitterFollower: 300400,
		TotalStaked:     100000,
		Balance:         1000,
		TxnFrequency:    100,
		LastUpdated:     1739983740,
	}

	// paramNum := 9
	var assignment = circuit.IdentityCheckCircuit{
		// Owner:           req.Owner,
		IsGithub:        req.IsGithub,
		GithubStar:      req.GithubStar,
		IsTwitter:       req.IsGithub,
		TwitterFollower: req.TwitterFollower,
		TotalStaked:     req.TotalStaked,
		Balance:         req.Balance,
		TxnFrequency:    req.TxnFrequency,
		LastUpdated:     req.LastUpdated,
	}

	arr := req.ToArray()
	// hashRes := [9]frontend.Variable{}
	// for i := 0; i < len(arr); i++ {
	// 	mimc := hash.MIMC_BN254.New()
	// 	var b1 fr.Element
	// 	b1.SetString(arr[i])
	// 	mimc.Write(b1.Marshal())
	// 	// mimc.Write([]byte(arr[i]))
	// 	result := mimc.Sum(nil)
	// 	// fmt.Println("Hashed value: ", result)
	// 	hashRes[i] = result
	// }

	mimc := hash.MIMC_BN254.New()
	var b1 fr.Element
	// addrBytes, err := hex.DecodeString("221bA23331E5395F2018eDafc2E0E9fF2Acb1aDa")
	ownerBigInt, _ := new(big.Int).SetString(req.Owner, 16)
	assignment.Owner = ownerBigInt
	fmt.Println("val1", ownerBigInt)

	b1.SetString(ownerBigInt.String())
	mimc.Write(b1.Marshal())

	fmt.Println("for loop start")
	for i := 1; i < len(arr); i++ {
		var b1 fr.Element
		fmt.Println("writing", arr[i])
		b1.SetString(arr[i])
		mimc.Write(b1.Marshal())
	}
	result := mimc.Sum(nil)

	assignment.Hash = result
	val := new(big.Int).SetBytes(result)
	fmt.Println("Hashed value: ", val.String())

	witness, err := frontend.NewWitness(&assignment, ecc.BN254.ScalarField())
	if err != nil {
		panic(err)
	}

	proof, err := groth16.Prove(cs, pk, witness)
	if err != nil {
		panic(err)
	}
	utils.WriteFile(proof, "02-proof.bin")

	publicWitness, err := witness.Public()
	if err != nil {
		panic(err)
	}
	utils.WriteFile(publicWitness, "02-public_witness.bin")

	fmt.Printf("proof sha256: %x\n", utils.FileSHA256("02-proof.bin"))
	fmt.Printf("public witness sha256: %x\n", utils.FileSHA256("02-public_witness.bin"))
}
