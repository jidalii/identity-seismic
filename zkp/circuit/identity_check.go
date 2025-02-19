package circuit

import (
	tedwards "github.com/consensys/gnark-crypto/ecc/twistededwards"
	"github.com/consensys/gnark/frontend"
	"github.com/consensys/gnark/std/algebra/native/twistededwards"
	"github.com/consensys/gnark/std/hash/mimc"
	// zksha3 "github.com/consensys/gnark/std/hash/sha3"
	// "github.com/consensys/gnark/std/math/uints"
	// "github.com/consensys/gnark/std/math/bits"

	// "github.com/consensys/gnark/std/hash/sha3"
	"github.com/consensys/gnark/std/signature/eddsa"
)

const MaxLen = 10

type CheckBalanceCircuit struct {
	PublicKey eddsa.PublicKey   `gnark:",public"`
	Signature eddsa.Signature   `gnark:",public"`
	Message   frontend.Variable `gnark:",public"`
}

func (circuit *CheckBalanceCircuit) Define(api frontend.API) error {
	curve, err := twistededwards.NewEdCurve(api, tedwards.BN254)
	if err != nil {
		return err
	}

	// hash function
	mimc, err := mimc.NewMiMC(api)
	if err != nil {
		return err
	}

	// tip: gnark profiles enable circuit developers to measure the number of constraints
	// generated by a part of the (or the entire) circuit, using pprof.
	// see github.com/consensys/gnark/profile

	// verify the EdDSA signature
	eddsa.Verify(curve, circuit.Signature, circuit.Message, circuit.PublicKey, &mimc)

	// tip: api.Println behaves like go fmt.Println but accepts frontend.Variable
	// that are resolved at Proving time
	api.Println("message", circuit.Message)

	return nil
}

type EddsaCircuit struct {
	PublicKey eddsa.PublicKey   `gnark:",public"`
	Signature eddsa.Signature   `gnark:",public"`
	Message   frontend.Variable `gnark:",public"`
}

func (circuit *EddsaCircuit) Define(api frontend.API) error {
	// set the twisted edwards curve to use
	curve, err := twistededwards.NewEdCurve(api, tedwards.BN254)
	if err != nil {
		return err
	}

	// hash function
	mimc, err := mimc.NewMiMC(api)
	if err != nil {
		return err
	}

	// tip: gnark profiles enable circuit developers to measure the number of constraints
	// generated by a part of the (or the entire) circuit, using pprof.
	// see github.com/consensys/gnark/profile

	// verify the EdDSA signature
	eddsa.Verify(curve, circuit.Signature, circuit.Message, circuit.PublicKey, &mimc)

	api.Println("message", circuit.Message)

	return nil
}

const paramNum int = 9

type IdentityCheckCircuit struct {
	Owner           frontend.Variable `gnark:",secret"`
	IsGithub        frontend.Variable `gnark:",secret"`
	GithubStar      frontend.Variable `gnark:",secret"`
	IsTwitter       frontend.Variable `gnark:",secret"`
	TwitterFollower frontend.Variable `gnark:",secret"`
	TotalStaked     frontend.Variable `gnark:",secret"`
	Balance         frontend.Variable `gnark:",secret"`
	TxnFrequency    frontend.Variable `gnark:",secret"`
	LastUpdated     frontend.Variable `gnark:",secret"`
	// Signature       eddsa.Signature   `gnark:",secret"`
	// PublicKey       eddsa.PublicKey   `gnark:",secret"`
	// Make a hash=(input1,input2.....) to reduce public input counts
	Hash frontend.Variable `gnark:",public"`
	// Hash [9]frontend.Variable `gnark:",public"`
}

func HashAndCompare(api frontend.API, val frontend.Variable, hash frontend.Variable) {
	mimc1, _ := mimc.NewMiMC(api)
	mimc1.Write(val)
	result := mimc1.Sum()
	api.AssertIsEqual(hash, result)
	api.Println(result, hash)
}

func (circuit *IdentityCheckCircuit) Define(api frontend.API) error {

	mimc1, _ := mimc.NewMiMC(api)
	mimc1.Write(circuit.Owner)
	mimc1.Write(circuit.IsGithub)
	mimc1.Write(circuit.GithubStar)
	mimc1.Write(circuit.IsTwitter)
	mimc1.Write(circuit.TwitterFollower)
	mimc1.Write(circuit.TotalStaked)
	mimc1.Write(circuit.Balance)
	mimc1.Write(circuit.TxnFrequency)
	mimc1.Write(circuit.LastUpdated)
	result := mimc1.Sum()
	api.AssertIsEqual(circuit.Hash, result)
	api.Println(circuit.Hash, result)
	// HashAndCompare(api, circuit.Owner, circuit.Hash[0])
	// HashAndCompare(api, circuit.IsGithub, circuit.Hash[1])
	// HashAndCompare(api, circuit.GithubStar, circuit.Hash[2])
	// HashAndCompare(api, circuit.IsTwitter, circuit.Hash[3])
	// HashAndCompare(api, circuit.TwitterFollower, circuit.Hash[4])
	// HashAndCompare(api, circuit.TotalStaked, circuit.Hash[5])
	// HashAndCompare(api, circuit.Balance, circuit.Hash[6])
	// HashAndCompare(api, circuit.TxnFrequency, circuit.Hash[7])
	// HashAndCompare(api, circuit.LastUpdated, circuit.Hash[8])

	return nil
}
