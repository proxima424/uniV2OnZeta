// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "../lib/forge-std/src/Test.sol";
import {DeployTaskT} from "../src/deployTask.sol";
import {IERC20} from "../src/IERC20.sol";
import {IUniswapV2Router02} from "../lib/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

// This will be a forked test
// Forked test will make it easier for us to test
// by funding random addresses with "whatever" amount
contract DeployTaskTest is Test {

    // the identifiers of the forks
    uint256 zetaAthensFork;

    // instance of task contract
    DeployTask public task;

    // Load the addresses from .env
    address public immutable BTC_ZRC20;
    address public immutable ETH_ZRC20;

    // Third person EOAs
    address public proxima;
    address public alpha;

    // EOAs/SC with enough BTC and ETH ZRC20
    // Fetched from etherscan
    address private immutable richTokenA;
    address private immutable richTokenB;

    // Compare uint256(BTC_ZRC20) < uint256(ETH_ZRC20) boolean and accordingly update these values
    uint256 public immutable tokenA_liquidity_to_add;
    uint256 public immutable tokenB_lquidity_to_add;

    // Amounts to swap
    uint256 public immutable amountToSwap_tokenA;
    uint256 public immutable amountToSwap_tokenB;

    // State variables
    address public factoryAddress;
    address public poolAddress;
    address public routerAddress;
    uint256 tokenALiquidity;
    uint256 tokenBLiquidity;
    uint256 LP_Tokens;

    // Deploys factory,pool,router on the chain
    // Provides initial liquity
    // This function is run every time other test function is called
    function setUp() public {
        zetaAthensFork = vm.createFork("https://rpc.ankr.com/zetachain_evm_athens_testnet");
        vm.selectFork(zetaAthensFork);

        task = new DeployTask(BTC_ZRC20,ETH_ZRC20);
        ( factoryAddress, poolAddress,
         routerAddress, tokenALiquidity, tokenBLiquidity, LP_Tokens) = task.deployAndProvideLiquidity(btc_amount, eth_amount, deadline);
         proxima = makeAddr("proxima424");
         alpha = makeAddr("alpha");
    }

    function testDeployments() public {
        assertTrue(factoryAddress!= address(0));
        assertTrue(poolAddress!= address(0));
        assertTrue(routerAddress!= address(0));
        assertTrue(tokenALiquidity!=0);
        assertTrue(tokenBLiquidity!=0);
        assertTrue(LP_Tokens!=0);
    }

    function testRouterApproval() public {
        vm.startPrank(proxima);
        IERC20(BTC_ZRC20).approve(routerAddress, 5*10**18);
        vm.stopPrank();
        assertEq(IERC20(BTC_ZRC20).allowance(proxima, routerAddress), 5*10**18);      
    }

    function testRouterInfiniteApproval() public {
        vm.startPrank(proxima);
        IERC20(BTC_ZRC20).approve(routerAddress, type(uint256).max);
        vm.stopPrank();
        assertEq(IERC20(BTC_ZRC20).allowance(proxima, routerAddress),type(uint256).max);
    }

    function testAddLiquidity() public {
        // arrange addresses in the desired UniswapContracts standard
        (address tokenA, address tokenB) = BTC_ZRC20<ETH_ZRC20 ? (BTC_ZRC20,ETH_ZRC20) : (ETH_ZRC20,BTC_ZRC20);

        // Give enough tokens to proxima to add liqudity
        // Transfer BTC-ZRC20 Liquidity
        vm.startPrank(richTokenA);
        IERC20(tokenA).transfer(proxima, tokenA_liquidity_to_add);
        vm.stopPrank();

        // Transfer ETH-ZRC20 Liquidity
        vm.startPrank(richTokenB);
        IERC20(tokenB).transfer(proxima, tokenB_liquidity_to_add);
        vm.stopPrank();

        uint256 prevTokenAPoolBalance = IERC20(tokenA).balanceOf(poolAddress);
        uint256 prevTokenBPoolBalance = IERC20(tokenB).balanceOf(poolAddress);

        // Add liquidity via router02
        ( uint256 amountAddedTokenA, uint256 amountAddedTokenB , uint256 LP_Tokens ) = IUniswapV2Router02(routerAddress).addLiquidity(tokenA, tokenB,tokenA_liquidity_to_add, tokenB_liquidity_to_add,0,0, proxima, block.timestamp + 10 minutes);

        // Check for non-zero returned variables
        assertNotEq(amountAddedTokenA, 0);
        assertNotEq(amountAddedTokenB,0);

        // Check LP tokens minted
        assertEq(IERC20(poolAddress).balanceOf(proxima),LP_Tokens);

        // Check updated pool balance
        assertEq(IERC20(tokenA).balanceOf(poolAddress), prevTokenAPoolBalance + amountAddedTokenA);
        assertEq(IERC20(tokenB).balanceOf(poolAddress), prevTokenBPoolBalance + amountAddedTokenB);
    }

    function testSwapTokenA() public {
        /* Adding Liquidity, copying above function's code */
        (address tokenA, address tokenB) = BTC_ZRC20<ETH_ZRC20 ? (BTC_ZRC20,ETH_ZRC20) : (ETH_ZRC20,BTC_ZRC20);
        vm.startPrank(richTokenA);
        IERC20(tokenA).transfer(proxima, tokenA_liquidity_to_add);
        vm.stopPrank();
        vm.startPrank(richTokenB);
        IERC20(tokenB).transfer(proxima, tokenB_liquidity_to_add);
        vm.stopPrank();  
        ( uint256 amountAddedTokenA, uint256 amountAddedTokenB , uint256 LP_Tokens ) = IUniswapV2Router02(routerAddress).addLiquidity(tokenA, tokenB,tokenA_liquidity_to_add, tokenB_liquidity_to_add,0,0, proxima, block.timestamp + 10 minutes); 
        /* Adding Liquidity Code Ends */

        // Fund Alpha with tokenA to swap with tokenB
        vm.startPrank(richTokenA);
        IERC20(tokenA).transfer(alpha,amountToSwap_tokenA);
        vm.stopPrank();

        // Swap using router
        // We will using swapExactTokensForTokens to get the tokenHoldings of EOA to zero

        // Token Addresses Array
        address[] memory path;
        path = new address[](2);
        path[0] = tokenA;
        path[1] = tokenB;    

        // Approve Router02 contract to make the transaction
        vm.startPrank(alpha);
        IERC20(tokenA).approve(routerAddress, amountToSwap_tokenA);
        vm.stopPrank();

        // Actual Swap
        vm.startPrank(alpha);
        uint[] memory amounts = IUniswapV2Router02(routerAddress).swapExactTokensForTokens(
            amountToSwap_tokenA,
            0,
            path,
            msg.sender,
            block.timestamp
        );
        vm.stopPrank();

        // Assertions
        // amounts[1] == tokenB Amount out
        assertNotEq(amounts[1], 0);
        
        // alpha's tokenA challenge
        assertEq(IERC20(tokenA).balanceOf(alpha), amountToSwap_tokenA - amounts[0]);
        // Alpha's tokenB previous balance was zero
        assertEq(IERC20(tokenB).balanceOf(alpha),amounts[1]);

        // Pool's amount balance check
        assertEq(IERC20(tokenA).balanceOf(poolAddress), amountAddedTokenA + amounts[0]);
        assertEq(IERC20(tokenB).balanceOf(poolAddress), amountAddedTokenB - amounts[1]);

    }

    function testSwapTokenB() public {
        /* Adding Liquidity, copying above function's code */
        (address tokenA, address tokenB) = BTC_ZRC20<ETH_ZRC20 ? (BTC_ZRC20,ETH_ZRC20) : (ETH_ZRC20,BTC_ZRC20);
        vm.startPrank(richTokenA);
        IERC20(tokenA).transfer(proxima, tokenA_liquidity_to_add);
        vm.stopPrank();
        vm.startPrank(richTokenB);
        IERC20(tokenB).transfer(proxima, tokenB_liquidity_to_add);
        vm.stopPrank();  
        ( uint256 amountAddedTokenA, uint256 amountAddedTokenB , uint256 LP_Tokens ) = IUniswapV2Router02(routerAddress).addLiquidity(tokenA, tokenB,tokenA_liquidity_to_add, tokenB_liquidity_to_add,0,0, proxima, block.timestamp + 10 minutes); 
        /* Adding Liquidity Code Ends */

        // Approve Router02 contract to make the transaction
        vm.startPrank(alpha);
        IERC20(tokenB).approve(routerAddress, amountToSwap_tokenB);
        vm.stopPrank();

         // Token Addresses Array
        address[] memory path;
        path = new address[](2);
        path[0] = tokenB;
        path[1] = tokenA;
        
        // Fund Alpha with tokenB to swap with tokenA
        vm.startPrank(richTokenB);
        IERC20(tokenB).transfer(alpha,amountToSwap_tokenB);
        vm.stopPrank();

        // Actual Swap
        vm.startPrank(alpha);
        uint[] memory amounts = IUniswapV2Router02(routerAddress).swapExactTokensForTokens(
            amountToSwap_tokenB,
            0,
            path,
            msg.sender,
            block.timestamp
        );
        vm.stopPrank();

        // Assertions
        // amounts[1] == tokenA Amount out
        assertNotEq(amounts[1], 0);
        
        // alpha's tokenA previous balance was zero
        assertEq(IERC20(tokenA).balanceOf(alpha), amounts[1]);
        // alpha's tokenB updated amount
        assertEq(IERC20(tokenB).balanceOf(alpha),amountToSwap_tokenB - amounts[0]);

        // Pool's amount balance check
        assertEq(IERC20(tokenA).balanceOf(poolAddress), amountAddedTokenA - amounts[1]);
        assertEq(IERC20(tokenB).balanceOf(poolAddress), amountAddedTokenB + amounts[0]);
    }  


 }

