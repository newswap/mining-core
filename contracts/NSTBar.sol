pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

// NSTBar is the coolest bar in town. You come in with some NST, and leave with more! The longer you stay, the more NST you get.
//
// This contract handles swapping to and from xNST, NewSwap's staking token.
contract NSTBar is ERC20("NSTBar", "xNST"){
    using SafeMath for uint256;
    IERC20 public nst;

    // Define the NST contract
    constructor(IERC20 _nst) public {
        nst = _nst;
    }

    // Enter the bar. Pay some NSTs. Earn some shares.
    // Locks NST and mints xNST
    function enter(uint256 _amount) public {
        // Gets the amount of NST locked in the contract
        uint256 totalNST = nst.balanceOf(address(this));
        // Gets the amount of xNST in existence
        uint256 totalShares = totalSupply();
        // If no xNST exists, mint it 1:1 to the amount put in
        if (totalShares == 0 || totalNST == 0) {
            _mint(msg.sender, _amount);
        } 
        // Calculate and mint the amount of xNST the NST is worth. The ratio will change overtime, as xNST is burned/minted and NST deposited + gained from fees / withdrawn.
        else {
            uint256 what = _amount.mul(totalShares).div(totalNST);
            _mint(msg.sender, what);
        }
        // Lock the NST in the contract
        nst.transferFrom(msg.sender, address(this), _amount);
    }

    // Leave the bar. Claim back your NSTs.
    // Unclocks the staked + gained NST and burns xNST
    function leave(uint256 _share) public {
        // Gets the amount of xNST in existence
        uint256 totalShares = totalSupply();
        // Calculates the amount of NST the xNST is worth
        uint256 what = _share.mul(nst.balanceOf(address(this))).div(totalShares);
        _burn(msg.sender, _share);
        nst.transfer(msg.sender, what);
    }
}