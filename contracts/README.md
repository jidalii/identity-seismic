# Scry Smart Contract

- Devnet smart contract address: 0x9Df298e2123DbfbEFa628D4fAcDfa3C4e8908f55.

## Commands

- Compile smart contracts to ABIs:

    ```shell
    ssolc --abi src/IDProtocol.sol --base-path . --include-path lib --output-dir build --allow-paths . @openzeppelin/=lib/openzeppelin-contracts/ --overwrite
    ```

- Run test case:

    ```shell
    sforge test -vvv
    ```

- Interacte with the blockchain: You can try any of the script in `script/script.sh`.
