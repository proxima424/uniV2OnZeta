# Deploy UniswapV2 on Zetachain
`src/DeployTask.sol` : 
- Need to set BTC_ZRC20 address and ETH_ZRC20 address in deployment via constructor
- Call deployAndProvideLiquidity with the required params
- Public getters for fetching addresses of { Factory , Pool, Router } contracts are available
- Can also be fetched via emitted events

`test/DeployTask.t.sol` :
- Fork testing of DeployTask.sol on zetaAthensTestnet
- Need to hardcode BTC_ZRC20 address and ETH_ZRC20 address
- Need to hardcode two addresses on zeta-Testnet which are rich in BTC_ZRC20 and ETH_ZRC20
- Hardcode amount of BTC_ZRC20 and ETH_ZRC20 to be provided as liquidity to Pool
- Hardcode amount of BTC_ZRC20 and ETH_ZRC20 to be used for swap
- We are using `swapExactTokensForTokens` function of the router to make swaps

# ISSUES FACED
The uniswapV2-core and uniswapV2-periphery npm packages have inconsistent compiler versions across its contract. </br>
Still trying to find workaround it. </br>
I found the info from A Hardhat FAQ to be useful: </br>
In some scenarios, you might have a contract with pragma version ^0.7.0 that imports a contract with ^0.6.0. This can never be compiled. </br>
If the ^0.6.0 file comes from a dependency, one possible fix is to upgrade that dependency (assuming newer versions use a newer version of solidity). </br>
Alternatively, you might need to downgrade the pragma versions of the contracts in your project. </br>
Need to find a better solution than hardcoding solc versions. </br>
