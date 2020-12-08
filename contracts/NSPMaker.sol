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
// TODO 重点测试
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

    // covert NST to NSP    TODO 不允许传token地址，否则可以恶意攻击！！
    function convertNST() public {
        uint amount = IERC20(nst).balanceOf(address(this));
        if(amount > 0) {
            // At least we try to make front-running harder to do.
            require(msg.sender == tx.origin, "do not convert from contract");
            // First we convert nst to wnew
            uint256 wnewAmount = _toNEW(nst);
            // Then we convert the wnew to nsp
            _toNSP(wnewAmount);
        }
    }

    // covert LPToken to NSP
    function convert(address token0, address token1) public {
        // At least we try to make front-running harder to do.
        require(msg.sender == tx.origin, "do not convert from contract");
        IUniswapV2Pair pair = IUniswapV2Pair(factory.getPair(token0, token1));
        pair.transfer(address(pair), pair.balanceOf(address(this)));
        pair.burn(address(this));

        // TODO 此处有bug，需要记录获得的token数！_toWNEW中传数量
        // First we convert everything to WNEW
        uint256 wethAmount = _toNEW(token0) + _toNEW(token1);
        // Then we convert the WNEW to NSP
        _toNSP(wethAmount);
    }

    // Converts token passed as an argument to WNEW
    function _toNEW(address token) internal returns (uint256) {
        // If the passed token is nsp, don't convert anything
        if (token == nsp) {
            uint amount = IERC20(token).balanceOf(address(this));
            _safeTransfer(token, bar, amount);
            return 0;
        }
        // If the passed token is WNEW, don't convert anything
        if (token == wnew) {
            uint amount = IERC20(token).balanceOf(address(this));
            _safeTransfer(token, factory.getPair(wnew, nsp), amount);
            return amount;
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
        // Calculate information required to swap
        uint amountIn = IERC20(token).balanceOf(address(this));
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        uint amountOut = numerator / denominator;
        (uint amount0Out, uint amount1Out) = token0 == token ? (uint(0), amountOut) : (amountOut, uint(0));
        // Swap the token for WNEW
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
