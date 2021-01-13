pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./NST.sol";

// MasterChef is the master of NST. He can make NST and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once NST is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MasterChef is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of NSTs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accNSTPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accNSTPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. NSTs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that NSTs distribution occurs.
        uint256 accNSTPerShare; // Accumulated NSTs per share, times 1e12. See below.
    }

    NST public nst;

    uint256 public feeRate = 1000;

    // to NSPMaker
    address public devaddr;
    // NST tokens created per block.
    uint256 public nstPerBlock;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when NST mining starts.
    uint256 public startBlock;
    // The block number when NST mining finish.
    uint256 public endBlock;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        NST _nst,
        address _devaddr,
        uint256 _nstPerBlock,
        uint256 _startBlock,
        uint256 _endBlock
    ) public {
        nst = _nst;
        devaddr = _devaddr;
        nstPerBlock = _nstPerBlock;
        startBlock = _startBlock;
        endBlock = _endBlock;
    }

    event Activated(uint256 _endBlock, uint256 _nstPerBlock);
    // TODO 每年激活一次，4年后将_endBlock设置为无限大，永续奖励2NST/Block
    function activate(uint256 _endBlock, uint256 _nstPerBlock, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        endBlock = _endBlock;
        nstPerBlock = _nstPerBlock;

        emit Activated(_endBlock, _nstPerBlock);
    }

    function setFeeRate(uint256 _feeRate) public onlyOwner {
        feeRate = _feeRate;   
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accNSTPerShare: 0
        }));
    }

    // Update the given pool's NST allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        if (_to <= endBlock) {
            return _to.sub(_from).mul(nstPerBlock);
        } else if (_from >= endBlock) {
            return 0;
        } else {
            return endBlock.sub(_from).mul(nstPerBlock);
        }
    }

    // View function to see pending NSTs on frontend.
    function pendingNST(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accNSTPerShare = pool.accNSTPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 nstReward = multiplier.mul(pool.allocPoint).div(totalAllocPoint);
            nstReward = nstReward.sub(nstReward.div(10));
            accNSTPerShare = accNSTPerShare.add(nstReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accNSTPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 nstReward = multiplier.mul(pool.allocPoint).div(totalAllocPoint);
        nst.mint(devaddr, nstReward.div(10));
        uint256 poolNSTReward = nstReward.sub(nstReward.div(10));
        nst.mint(address(this), poolNSTReward);
        pool.accNSTPerShare = pool.accNSTPerShare.add(poolNSTReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for NST allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accNSTPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                safeNSTTransfer(msg.sender, pending);
            }
        }
        
        if(_amount > 0) {
            if(feeRate > 0) {
                pool.lpToken.safeTransferFrom(address(msg.sender), devaddr, _amount.div(feeRate));           
                _amount = _amount.sub(_amount.div(feeRate));
            }

            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accNSTPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accNSTPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            safeNSTTransfer(msg.sender, pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accNSTPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // Safe NST transfer function, just in case if rounding error causes pool to not have enough NSTs.
    function safeNSTTransfer(address _to, uint256 _amount) internal {
        uint256 nstBal = nst.balanceOf(address(this));
        if (_amount > nstBal) {
            nst.transfer(_to, nstBal);
        } else {
            nst.transfer(_to, _amount);
        }
    }

    function dev(address _devaddr) public onlyOwner {
        // require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }
}
