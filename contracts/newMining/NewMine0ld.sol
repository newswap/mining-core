pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./XNew.sol";

// MasterChef is the master of Sushi. He can make Sushi and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once SUSHI is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract NewMineOld is Ownable {
    // using SafeMath for uint256;
    // using SafeERC20 for IERC20;

    // // Info of each user.
    // struct UserInfo {
    //     uint256 amount;     // How many LP tokens the user has provided.
    //     uint256 rewardDebt; // Reward debt. See explanation below.
    //     //
    //     // We do some fancy math here. Basically, any point in time, the amount of SUSHIs
    //     // entitled to a user but is pending to be distributed is:
    //     //
    //     //   pending reward = (user.amount * pool.accSushiPerShare) - user.rewardDebt
    //     //
    //     // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
    //     //   1. The pool's `accSushiPerShare` (and `lastRewardBlock`) gets updated.
    //     //   2. User receives the pending reward sent to his/her address.
    //     //   3. User's `amount` gets updated.
    //     //   4. User's `rewardDebt` gets updated.
    // }

    // // Info of each pool.
    // struct PoolInfo {
    //     IERC20 lpToken;           // Address of LP token contract.
    //     // uint256 allocPoint;       // How many allocation points assigned to this pool. SUSHIs to distribute per block.

    //     // TODO 每次任何人进出都需要更新所有的池子！！！ 而不是当前的池子！！！这得消耗多少gas费用！！！！！ 
    //     // 其实本质就一个池子，大家都是分一个池子中的new    上面再虚拟化出了一层多矿池    
    //     // 怎么做到一个池子进来资金，其他池子无需计算收益？？====》不行，如果不计算，到时候其他池子的用户会少很多收益！！！
    //     uint256 newPerLP;   // TODO 大家吃一个池子，会出现新来的把之前的都吃掉嘛？？？？   
    // }

    // uint256 public lastRewardBlock;  // Last block number that NEW distribution occurs.
    // uint256 public accXNEWPerShare; // Accumulated NEW per share, times 1e12

    // XNew public xNew;
    // // XNEW tokens created per block.
    // uint256 public xNewPerBlock;
    // // update pool.newPerLP
    // address public oracle;

    // // Info of each pool.
    // PoolInfo[] public poolInfo;
    // // Info of each user that stakes LP tokens.
    // mapping (uint256 => mapping (address => UserInfo)) public userInfo;

    // // Total allocation points. Must be the sum of all allocation points in all pools.
    // // TODO 这个值的更新在用户每次添加或移除，而不是设置矿池时，设置矿池都不需要设置了！！，矿池的作用只是记录他有多少lp以及lp对应new的汇率
    // // TODO 如何确保这个值不会减到0以下？？？
    // uint256 public totalAllocNew = 0;

    // // The block number when SUSHI mining starts.
    // uint256 public startBlock;
    // // The block number when SUSHI mining finish.
    // uint256 public endBlock;

    // event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    // event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    // event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    // constructor(
    //     XNew _xNew,
    //     uint256 _xNewPerBlock,
    //     uint256 _startBlock,
    //     uint256 _endBlock   // TODO 有效期1年，之后若需要调用activate重新激活
    // ) public {
    //     xNew = _xNew;
    //     xNewPerBlock = _xNewPerBlock;
    //     startBlock = _startBlock;
    //     endBlock = _endBlock;

    //     // startBlock 可以不用了？？
    //     lastRewardBlock = block.number > startBlock ? block.number : startBlock;
    // }

    // event Activated(uint256 _endBlock, uint256 _xNewPerBlock);
    // // TODO 测试  是不是要加一个start？？？并且lastRewardBlock=start   还是以调用函数的时刻为重启点
    // function activate(uint256 _endBlock, uint256 _xNewPerBlock, bool _withUpdate) public onlyOwner {
    //     updateReward();
    //     endBlock = _endBlock;
    //     xNewPerBlock = _xNewPerBlock;

    //     emit Activated(_endBlock, _xNewPerBlock);
    // }

    // // TODO 测试
    // // NewMine若出现重大bug时，转移xnew的owner，并且转出所有xnew给owner
    // function transferAllXNewAndOwner(address _newOwner) public onlyOwner {
    //     // TODO 确定如果xnew全都转出，用户解除质押是否会出问题
    //     uint256 bal = xNew.balanceOf(address(this))
    //     xNew.transfer(_newOwner, bal);
    //     xNew.transferOwnership(_newOwner);
    // }

    // function updateLPPrice(bool _withUpdate) public onlyOrcle {
    //     if (_withUpdate) {
    //         updateReward();
    //     }


    //     for all???
    // }

    // function poolLength() external view returns (uint256) {
    //     return poolInfo.length;
    // }

    // // Add a new lp to the pool. Can only be called by the owner.
    // // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    // function add(IERC20 _lpToken, uint256 _newPerLP) public onlyOwner {
    //     updateReward();
    //     // TODO 在用户真正添加/移除时才更新totalAllocPoint 和 allocPoint     allocPoint是不是都不需要了！！！
    //     // totalAllocPoint = totalAllocPoint.add(_allocPoint);
    //     poolInfo.push(PoolInfo({
    //         lpToken: _lpToken,
    //         newPerLP: _newPerLP
    //     }));
    // }

    // // Update the given pool's SUSHI allocation point. Can only be called by the owner.
    // function set(uint256 _pid, uint256 _newPerLP) public onlyOwner {
    //     updateReward();
    //     totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
    //     poolInfo[_pid].allocPoint = _allocPoint;
    // }

    // // 改名getTotalXNewReward
    // // Return reward multiplier over the given _from to _to block.
    // function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
    //     if (_to <= endBlock) {
    //         return _to.sub(_from).mul(xNewPerBlock);
    //     } else if (_from >= endBlock) {
    //         return 0;
    //     } else {
    //         return endBlock.sub(_from).mul(xNewPerBlock);
    //     }
    // }

    // // View function to see pending SUSHIs on frontend.
    // function pendingSushi(uint256 _pid, address _user) external view returns (uint256) {
    //     PoolInfo storage pool = poolInfo[_pid];
    //     UserInfo storage user = userInfo[_pid][_user];
    //     uint256 accSushiPerShare = pool.accSushiPerShare;
    //     uint256 lpSupply = pool.lpToken.balanceOf(address(this));
    //     if (block.number > pool.lastRewardBlock && lpSupply != 0) {
    //         // TODO 测试下0的情况
    //         uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
    //         uint256 sushiReward = multiplier.mul(pool.allocPoint).div(totalAllocPoint);
    //         accSushiPerShare = accSushiPerShare.add(sushiReward.mul(1e12).div(lpSupply));
    //     }
    //     return user.amount.mul(accSushiPerShare).div(1e12).sub(user.rewardDebt);
    // }

    // // Update reward variables of the given pool to be up-to-date.
    // function updateReward() public {
    //     if (block.number <= lastRewardBlock) {
    //         return;
    //     }    

    //     // TODO 如果没有人锁仓，这段时间就不产矿     还是说这段时间的矿给下一次第一个进来的人？？？
    //     if (totalAllocNew == 0) {
    //         lastRewardBlock = block.number;
    //         return;
    //     }

    //     // TODO 测试，此处会返回0
    //     uint256 xNewReward = getMultiplier(lastRewardBlock, block.number);
    //     xNew.mint(address(this), xNewReward);
    //     accXNEWPerShare = accXNEWPerShare.add(xNewReward.mul(1e12).div(totalAllocNew));
    //     lastRewardBlock = block.number;
    // }

    // // Deposit LP tokens to MasterChef for SUSHI allocation.
    // function deposit(uint256 _pid, uint256 _amount) public {
    //     PoolInfo storage pool = poolInfo[_pid];
    //     UserInfo storage user = userInfo[_pid][msg.sender];
    //     // TODO 要更新所有的池子，而不是当前的
    //     updatePool(_pid);
    //     if (user.amount > 0) {
    //         uint256 pending = user.amount  是这个值代表的股份在变！！  .mul(accSushiPerShare).div(1e12).sub(user.rewardDebt);
    //         if(pending > 0) {
    //             safeSushiTransfer(msg.sender, pending);
    //         }
    //     }
        
    //     if(_amount > 0) {
    //         if(feeRate > 0) { // TODO 测试
    //             pool.lpToken.safeTransferFrom(address(msg.sender), devaddr, _amount.div(feeRate));           
    //             _amount = _amount.sub(_amount.div(feeRate));
    //         }

    //         pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
    //         user.amount = user.amount.add(_amount);
    //     }
    //     user.rewardDebt = user.amount.mul(pool.accSushiPerShare).div(1e12);
    //     emit Deposit(msg.sender, _pid, _amount);
    // }

    // // Withdraw LP tokens from MasterChef.
    // function withdraw(uint256 _pid, uint256 _amount) public {
    //     PoolInfo storage pool = poolInfo[_pid];
    //     UserInfo storage user = userInfo[_pid][msg.sender];
    //     require(user.amount >= _amount, "withdraw: not good");
    //     // TODO 要更新所有的池子，而不是当前的
    //     updatePool(_pid);
    //     uint256 pending = user.amount.mul(pool.accSushiPerShare).div(1e12).sub(user.rewardDebt);
    //     if(pending > 0) {
    //         safeSushiTransfer(msg.sender, pending);
    //     }
    //     if(_amount > 0) {
    //         user.amount = user.amount.sub(_amount);
    //         pool.lpToken.safeTransfer(address(msg.sender), _amount);
    //     }
    //     user.rewardDebt = user.amount.mul(pool.accSushiPerShare).div(1e12);
    //     emit Withdraw(msg.sender, _pid, _amount);
    // }

    // // Withdraw without caring about rewards. EMERGENCY ONLY.
    // function emergencyWithdraw(uint256 _pid) public {
    //     PoolInfo storage pool = poolInfo[_pid];
    //     UserInfo storage user = userInfo[_pid][msg.sender];
    //     pool.lpToken.safeTransfer(address(msg.sender), user.amount);
    //     emit EmergencyWithdraw(msg.sender, _pid, user.amount);
    //     user.amount = 0;
    //     user.rewardDebt = 0;
    // }

    // // Safe sushi transfer function, just in case if rounding error causes pool to not have enough SUSHIs.
    // function safeSushiTransfer(address _to, uint256 _amount) internal {
    //     uint256 sushiBal = sushi.balanceOf(address(this));
    //     if (_amount > sushiBal) {
    //         sushi.transfer(_to, sushiBal);
    //     } else {
    //         sushi.transfer(_to, _amount);
    //     }
    // }

    // // Update dev address by the previous dev.
    // function dev(address _devaddr) public {
    //     require(msg.sender == devaddr, "dev: wut?");
    //     devaddr = _devaddr;
    // }
}
