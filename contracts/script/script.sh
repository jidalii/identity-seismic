sforge script --chain-id 5124 script/Deploy.s.sol:DeployScript \
    --rpc-url https://node-1.seismicdev.net/rpc \
    --broadcast --legacy -vvvv
    
sforge script --chain-id 5124 script/CreateMerchantNoCouponTrade.s.s.sol:CreateMerchantScript \
    --rpc-url https://node-1.seismicdev.net/rpc \
    --broadcast --legacy -vvvv

sforge script --chain-id 5124 script/CreateMerchantAmountCouponTrade.s.sol:TradeCouponScript \
    --rpc-url https://node-1.seismicdev.net/rpc \
    --broadcast --legacy -vvvv