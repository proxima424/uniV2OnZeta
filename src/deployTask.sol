// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {UniswapV2Factory} from "@uniswapV2core/UniswapV2Factory.sol";
import {UniswapV2Pair} from "@uniswapV2core/UniswapV2Pair.sol";
import {UniswapV2Router02} from "@uniswapV2periphery/UniswapV2Router02.sol";
import {WETH9} from "./WETH9.sol";
import {IUniswapV2Factory} from "@uniswapV2core/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "@uniswapV2core/interfaces/IUniswapV2Pair.sol";
import {IUniswapV2Router02} from "@uniswapV2periphery/interfaces/IUniswapV2Router02.sol";
import {IERC20} from "./IERC20.sol";

contract DeployTask {
    uint256 private lock;
    address public poolAddress;
    address public immutable BTC_ZRC20;
    address public immutable ETH_ZRC20;
    IUniswapV2Factory public factory;
    IUniswapV2Pair public pool;
    IUniswapV2Router02 public router;
    WETH9 public weth9;

    // E-V-E-N-T-S
    event FactoryCreated(address indexed factory, address indexed creator);
    event PoolPairCreated(address indexed pair, address indexed creator);
    event RouterCreated(address indexed router, address indexed creator);

    constructor(address btc_zrc20, address eth_zrc20) {
        BTC_ZRC20 = btc_zrc20;
        ETH_ZRC20 = eth_zrc20;
    }

    modifier checkState() {
        require(lock == 0, "ZE-01");
        _;
        lock = 1;
    }

    // msg.sender need to approve this contract of the token amoubt
    // Return params :
    // factory address
    // pool address
    // router address
    // tokenA in pool
    // tokenB in pool
    // LP tokens
    function deployAndProvideLiquidity(uint256 btc_amount, uint256 eth_amount, uint256 deadline)
        public
        checkState
        returns (address, address, address, uint256, uint256, uint256)
    {
        factory = new UniswapV2Factory();
        // address tokenA;
        // address tokenB;
        // tokenA = tokenA > tokenB ? tokenA : ( tokenB && tokenB = tokenA );
        poolAddress = factory.createPair(BTC_ZRC20, ETH_ZRC20);
        weth9 = new WETH9();
        router = new UniswapV2Router02(address(factory),address(weth9));
        // All uni contracts deployed
        // Transfer liqudity tokens to this contract
        IERC20(BTC_ZRC20).transferFrom(msg.sender, address(this));
        IERC20(ETH_ZRC20).transferFrom(msg.sender, address(this));
        // Now provide liquidity to BTC<>ETH Pool via router
        (uint256 tokenA, uint256 tokenB, uint256 LPTokens) =
            router.addLiquidity(BTC_ZRC20, ETH_ZRC20, btc_amount, eth_amount, 0, 0, deadline);

        emit FactoryCreated(address(factory), msg.sender);
        emit PoolPairCreated(poolAddress, msg.sender);
        emit RouterCreated(router, msg.sender);

        return (address(factory), poolAddress, address(router), tokenA, tokenB, LPTokens);
    }
}
