pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

// NSPBar is the coolest bar in town. You come in with some NSP, and leave with more! The longer you stay, the more SNP you get.
//
// This contract handles swapping to and from xNSP, NewSwap's staking token.
contract NSPBar is ERC20("NSPBar", "xNSP"){ //TODO 重点测试
    using SafeMath for uint256;
    IERC20 public nsp;

    // Define the nsp token contract
    constructor(IERC20 _nsp) public {
        nsp = _nsp;
    }

    // Enter the bar. Pay some NSPs. Earn some shares.
    // Locks NSP and mints xNSP
    function enter(uint256 _amount) public {
        // Gets the amount of NSP locked in the contract
        uint256 totalNSP = nsp.balanceOf(address(this));
        // Gets the amount of xNSP in existence
        uint256 totalShares = totalSupply();
        // If no xNSP exists, mint it 1:1 to the amount put in
        if (totalShares == 0 || totalNSP == 0) {
            _mint(msg.sender, _amount);
        } 
        // Calculate and mint the amount of xNSP the NSP is worth. The ratio will change overtime, as xNSP is burned/minted and NSP deposited + gained from fees / withdrawn.
        else {
            uint256 what = _amount.mul(totalShares).div(totalNSP);
            _mint(msg.sender, what);
        }
        // Lock the NSP in the contract
        nsp.transferFrom(msg.sender, address(this), _amount);
    }

    // Leave the bar. Claim back your NSPs.
    // Unclocks the staked + gained NSP and burns xNSP
    function leave(uint256 _share) public {
        // Gets the amount of xNSP in existence
        uint256 totalShares = totalSupply();
        // Calculates the amount of NSP the xNSP is worth
        uint256 what = _share.mul(nsp.balanceOf(address(this))).div(totalShares);
        _burn(msg.sender, _share);
        nsp.transfer(msg.sender, what);
    }
}