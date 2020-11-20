pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import '../uniswapv2/interfaces/IUniswapV2Pair.sol';
import "./XNew.sol";

// MasterChef is the master of Sushi. He can make Sushi and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once SUSHI is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract NewMine is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of SUSHIs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accXNewPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accXNewPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract.
        // TODO 所有池子共享一个池子的xnew，池子的加/减以及newPerLP的变化都要更新allocPoint以及totalAllocPoint
        uint256 allocPoint;       // How many allocation points assigned to this pool. SUSHIs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that SUSHIs distribution occurs.
        uint256 accXNewPerShare; // Accumulated xNew per share, times 1e12. See below.
        uint256 newPerLP; // LP token price against NEW, times 1e12  TODO 此处要注意！！！
        bool state; // true-enable, false-disable
    }

    XNew public xNew;
    address public wNew;

    // xNew tokens created per block.
    uint256 public xNewPerBlock;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when SUSHI mining starts.
    uint256 public startBlock;
    // The block number when SUSHI mining finish.
    uint256 public endBlock;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        XNew _xNew,
        address _wNew,
        uint256 _xNewPerBlock,
        uint256 _startBlock,
        uint256 _endBlock   // TODO 有效期1年，之后若可继续需要调用activate重新激活
    ) public {
        xNew = _xNew;
        wNew = _wNew;
        xNewPerBlock = _xNewPerBlock;
        startBlock = _startBlock;
        endBlock = _endBlock;
    }

    event Activated(uint256 _endBlock, uint256 _xNewPerBlock);
    // TODO 测试  重启挖xnew， 若将来出块时间改了(如3s改成15s)，重新激活就可以
    function activate(uint256 _endBlock, uint256 _xNewPerBlock, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        endBlock = _endBlock;
        xNewPerBlock = _xNewPerBlock;

        emit Activated(_endBlock, _xNewPerBlock);
    }

    // return LP token price against NEW, times 1e12 
    function getNewPerLP(address lpAddress) public view returns (uint256) {
        IUniswapV2Pair pair = IUniswapV2Pair(lpAddress);
        address token0 = pair.token0();
        address token1 = pair.token1();
        require(token0 == wNew || token1 == wNew, "getNewPerLP: lpToken doesn't include wnew");

        (uint reserve0, uint reserve1,) = pair.getReserves();
        uint256 lpTotalSupply = pair.totalSupply();
        if(lpTotalSupply > 0) {
            return token0 == wNew ? reserve0.mul(1e12).div(lpTotalSupply) : reserve1.mul(1e12).div(lpTotalSupply);
        } else {
            return 0;
        }     
    }

    // TODO 每天调用70多次？？
    function updateNewPerLP(uint256 _pid) public {
        massUpdatePools();

        PoolInfo storage pool = poolInfo[_pid];
        if(pool.state) {
            uint256 lpBalance = pool.lpToken.balanceOf(address(this));
            pool.newPerLP = getNewPerLP(address(pool.lpToken));

            // TODO 要除以1e12吗？？？？如果除还有增/减仓2处代码      如果除可能会出现小数而变0的问题
            uint256 allocPoint = lpBalance.mul(pool.newPerLP);
            totalAllocPoint = totalAllocPoint.sub(pool.allocPoint).add(allocPoint);
            pool.allocPoint = allocPoint;
        }
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function addPool(IERC20 _lpToken) public onlyOwner {
        uint256 newPerLP = getNewPerLP(address(_lpToken));

        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: 0,
            lastRewardBlock: lastRewardBlock,
            accXNewPerShare: 0,
            newPerLP: newPerLP,
            state: true
        }));
    }

    function setPoolState(uint256 _pid, bool _state, bool _withUpdate) public onlyOwner {
        if(_withUpdate) {
            massUpdatePools();
        }
        
        PoolInfo storage pool = poolInfo[_pid];
        require(pool.state != _state, "setPoolState: state is not changed");
        pool.state = _state;

        if(_state) { //enable
            uint256 lpBalance = pool.lpToken.balanceOf(address(this));
            pool.newPerLP = getNewPerLP(address(pool.lpToken));
            uint256 allocPoint = lpBalance.mul(pool.newPerLP);
            totalAllocPoint = totalAllocPoint.add(allocPoint);
            pool.allocPoint = allocPoint;
        } else { //disable
            totalAllocPoint = totalAllocPoint.sub(pool.allocPoint);
            pool.allocPoint = 0;            
        }
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        if (_to <= endBlock) {
            return _to.sub(_from).mul(xNewPerBlock);
        } else if (_from >= endBlock) {
            return 0;
        } else {
            return endBlock.sub(_from).mul(xNewPerBlock);
        }
    }

    // View function to see pending xNew on frontend.
    function pendingXNew(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accXNewPerShare = pool.accXNewPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (pool.state && block.number > pool.lastRewardBlock && lpSupply != 0 && totalAllocPoint != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 xNewReward = multiplier.mul(pool.allocPoint).div(totalAllocPoint);
            accXNewPerShare = accXNewPerShare.add(xNewReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accXNewPerShare).div(1e12).sub(user.rewardDebt);
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
        if (lpSupply == 0 || totalAllocPoint == 0 || !pool.state) {
            pool.lastRewardBlock = block.number;
            return;
        }

        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 xNewReward = multiplier.mul(pool.allocPoint).div(totalAllocPoint);
        xNew.mint(address(this), xNewReward);
        pool.accXNewPerShare = pool.accXNewPerShare.add(xNewReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for SUSHI allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        massUpdatePools();

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accXNewPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                safeXNewTransfer(msg.sender, pending);
            }
        }
        
        if(_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
            // 如果pool不可用，用户可以把token打进来，但获得不了收益(allocPoint还是0)   不能报错，因为提款用的就是deposit 或 withdraw
            if(pool.state) {
                // TODO 更新allocPoint和totalAllocPoint 
                uint256 addPoint = _amount.mul(pool.newPerLP);
                pool.allocPoint = pool.allocPoint.add(addPoint);
                totalAllocPoint = totalAllocPoint.add(addPoint);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accXNewPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");

        massUpdatePools();

        uint256 pending = user.amount.mul(pool.accXNewPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            safeXNewTransfer(msg.sender, pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);

            // 如果pool不可用，用户可以提取，allocPoint继续维持为0，不用减      不要报错，因为提款用的就是deposit 或 withdraw
            if(pool.state) {
                // TODO 更新allocPoint和totalAllocPoint    可能减出负数吗？？？
                uint256 subPoint = _amount.mul(pool.newPerLP);
                pool.allocPoint = pool.allocPoint.sub(subPoint);
                totalAllocPoint = totalAllocPoint.sub(subPoint);
            }
        }

        user.rewardDebt = user.amount.mul(pool.accXNewPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);

        if(pool.state) {
            // TODO 更新allocPoint和totalAllocPoint    可能减出负数吗？？？
            uint256 subPoint = user.amount.mul(pool.newPerLP);
            pool.allocPoint = pool.allocPoint.sub(subPoint);
            totalAllocPoint = totalAllocPoint.sub(subPoint);
        }

        user.amount = 0;
        user.rewardDebt = 0;
    }

    // Safe sushi transfer function, just in case if rounding error causes pool to not have enough SUSHIs.
    function safeXNewTransfer(address _to, uint256 _amount) internal {
        uint256 xNewBal = xNew.balanceOf(address(this));
        if (_amount > xNewBal) {
            xNew.transfer(_to, xNewBal);
        } else {
            xNew.transfer(_to, _amount);
        }
    }
}
