pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./uniswapv2/interfaces/IUniswapV2ERC20.sol";
import "./uniswapv2/interfaces/IUniswapV2Pair.sol";
import "./uniswapv2/interfaces/IUniswapV2Factory.sol";

// NSPMaker is MasterChef's left hand and kinda a wizard. He can cook up NSP from NST!
//
// This contract handles "serving up" rewards for xNSP holders by trading tokens collected from NST.
contract NSPMaker {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IUniswapV2Factory public factory;
    address public bar;
    address public nsp;
    address public wnew;
    address public nst;

    constructor(IUniswapV2Factory _factory, address _bar, address _nsp, address _wnew, address _nst) public {
        factory = _factory;
        bar = _bar;
        nsp = _nsp;
        wnew = _wnew;
        nst = _nst;
    }

    // covert NST to NSP
    function convertNST() public {
        uint amount = IERC20(nst).balanceOf(address(this));
        if(amount > 0) {
            // At least we try to make front-running harder to do.
            require(msg.sender == tx.origin, "do not convert from contract");
            // First we convert nst to wnew
            uint256 wnewAmount = _toWNEW(nst, amount);
            // Then we convert the wnew to nsp
            _toNSP(wnewAmount);
        }
    }

    // covert LPToken to NSP
    function convert(address tokenA, address tokenB) public {
        // At least we try to make front-running harder to do.
        require(msg.sender == tx.origin, "do not convert from contract");

        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        IUniswapV2Pair pair = IUniswapV2Pair(factory.getPair(token0, token1));
        pair.transfer(address(pair), pair.balanceOf(address(this)));
        (uint amount0, uint amount1) = pair.burn(address(this));
        // First we convert everything to WNEW
        uint256 wnewAmount = _toWNEW(token0, amount0) + _toWNEW(token1, amount1);
        // Then we convert the WNEW to NSP
        _toNSP(wnewAmount);
    }

    // Converts token passed as an argument to WNEW
    function _toWNEW(address token, uint amountIn) internal returns (uint256) {
        // If the passed token is nsp, don't convert anything
        if (token == nsp) {
            _safeTransfer(token, bar, amountIn);
            return 0;
        }
        // If the passed token is WNEW, don't convert anything
        if (token == wnew) {
            _safeTransfer(token, factory.getPair(wnew, nsp), amountIn);
            return amountIn;
        }

        // If the target pair doesn't exist, don't convert anything
        IUniswapV2Pair pair = IUniswapV2Pair(factory.getPair(token, wnew));
        if (address(pair) == address(0)) {
            return 0;
        }
        // Choose the correct reserve to swap from
        (uint reserve0, uint reserve1,) = pair.getReserves();
        address token0 = pair.token0();
        (uint reserveIn, uint reserveOut) = token0 == token ? (reserve0, reserve1) : (reserve1, reserve0);
        uint amountInWithFee = amountIn.mul(997);
        uint amountOut = amountInWithFee.mul(reserveOut) / reserveIn.mul(1000).add(amountInWithFee);
        (uint amount0Out, uint amount1Out) = token0 == token ? (uint(0), amountOut) : (amountOut, uint(0));
         _safeTransfer(token, address(pair), amountIn);
        pair.swap(amount0Out, amount1Out, factory.getPair(wnew, nsp), new bytes(0));
        return amountOut;
    }

    // Converts WNEW to NSP
    function _toNSP(uint256 amountIn) internal {
        IUniswapV2Pair pair = IUniswapV2Pair(factory.getPair(wnew, nsp));
        // Choose WNEW as input token
        (uint reserve0, uint reserve1,) = pair.getReserves();
        address token0 = pair.token0();
        (uint reserveIn, uint reserveOut) = token0 == wnew ? (reserve0, reserve1) : (reserve1, reserve0);
        // Calculate information required to swap
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        uint amountOut = numerator / denominator;
        (uint amount0Out, uint amount1Out) = token0 == wnew ? (uint(0), amountOut) : (amountOut, uint(0));
        // Swap WNEW for NSP
        pair.swap(amount0Out, amount1Out, bar, new bytes(0));
    }

    // Wrapper for safeTransfer
    function _safeTransfer(address token, address to, uint256 amount) internal {
        IERC20(token).safeTransfer(to, amount);
    }
}
