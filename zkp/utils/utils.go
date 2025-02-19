package utils

import (
	"crypto/sha256"
	"io"
	"os"
)

func FileSHA256(filename string) []byte {
	file, err := os.Open(filename)
	if err != nil {
		panic(err)
	}
	defer file.Close()
	h := sha256.New()
	_, err = io.Copy(h, file)
	if err != nil {
		panic(err)
	}
	return h.Sum(nil)
}

func WriteFile(f io.WriterTo, filename string) {
	file, err := os.Create(filename)
	if err != nil {
		panic(err)
	}
	defer file.Close()
	_, err = f.WriteTo(file)
	if err != nil {
		panic(err)
	}
}

func ReadFile(f io.ReaderFrom, filename string) {
	file, err := os.Open(filename)
	if err != nil {
		panic(err)
	}
	defer file.Close()
	_, err = f.ReadFrom(file)
	if err != nil {
		panic(err)
	}
}
