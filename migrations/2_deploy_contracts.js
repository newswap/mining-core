const MasterChef = artifacts.require("MasterChef");
const SushiToken = artifacts.require("SushiToken");
const SushiBar = artifacts.require("SushiBar");
const UniswapV2Pair = artifacts.require("UniswapV2Pair");

module.exports = async function (deployer, network, accounts) {
  console.log("accounts[0]:"+accounts[0]);

  //  部署NST合约
  await deployer.deploy(SushiToken);
  var sushiToken = await SushiToken.deployed();
  console.log("NST(sushiToken):"+ sushiToken.address);

  // 部署xNST(sushiBar)合约
  await deployer.deploy(SushiBar, sushiToken.address);
  var sushiBar = await SushiBar.deployed();
  console.log("xNST(sushiBar):"+ sushiBar.address);

  const devaddr = accounts[0];
  const sushiPerBlock = web3.utils.toWei("1", 'ether');
  //_sushi, _devaddr, _sushiPerBlock, _startBlock, _bonusEndBlock
  await deployer.deploy(MasterChef, sushiToken.address, devaddr, sushiPerBlock, 0, 0)
  var masterChef = await MasterChef.deployed();
  console.log("masterChef:"+ masterChef.address);

  // sushi owner改成 masterChef     TODO 如果用发币宝代替sushiToken，则需要将masterChef设置为minter
  await sushiToken.transferOwnership(masterChef.address)
  var owner = await sushiToken.owner();
  console.log("owner:"+owner);

  //创建nusdt-new矿池
  const NUSDT_NEW = '0x56ae975581a382193ff36579c81281e179486c43' //TESTNET
  await masterChef.add(100, NUSDT_NEW, true)
  var poolLength = await masterChef.poolLength()
  console.log(Number(poolLength))
  // var pool = await masterChef.poolInfo(poolLength-1)
  // console.log(pool)

  // testnet
  // sushiToken:0x51da6aacdd0b853a753f60854f702957721362fe
  // sushiBar(xSushi):0x2a5a57c3eccfa803b139fb1cbaca0d4ca72366d4
  // masterChef:0x180fa4f2bc3bcb533d96dd28291a7f98ab3d84f7 
  // 第一个矿池NUSDT_NEW: 0x56aE975581a382193FF36579C81281E179486c43



  


//==============================================计算获得的sushi
  // const masterChef = await MasterChef.at('0x8a81A03322789749F59DEb11C8B408529077574a');
  // var pool = await masterChef.poolInfo(0)
  // console.log("===========pool")
  // console.log(pool[0]) //lpToken
  // console.log(Number(pool[1])) //allocPoint
  // console.log(Number(pool[2])) //lastRewardBlock
  // console.log(Number(pool[3])) //accSushiPerShare

  // var user = await masterChef.userInfo(0, accounts[0])
  // console.log("===========user")
  // console.log(Number(user[[0]])) //amount
  // console.log(Number(user[[1]])) //rewardDebt

  // const pair = await UniswapV2Pair.at('0x56aE975581a382193FF36579C81281E179486c43')
  // var lpSupply = await pair.balanceOf(masterChef.address)
  // console.log(Number(lpSupply))

  // console.log("=============sushiReward")
  // var number = await web3.eth.getBlockNumber();
  // console.log(number);
  // var multiplier = await masterChef.getMultiplier(Number(pool[2]), number)
  // console.log(Number(multiplier))

  // var totalAllocPoint = await masterChef.totalAllocPoint()
  // var sushiPerBlock = await masterChef.sushiPerBlock()
  // console.log(Number(totalAllocPoint))
  // console.log(Number(sushiPerBlock))
  // var sushiReward = Number(multiplier) * Number(sushiPerBlock) * Number(pool[1]) * Number(totalAllocPoint)
  // console.log(Number(sushiReward))

  // console.log("=============pendingSushi")
  // var pending = Number(user[[0]]) * Number(sushiReward) / 1e12
  // console.log(Number(pending))

  // var pendingSushi = await masterChef.pendingSushi(0, accounts[0])
  // console.log(Number(pendingSushi))


//   PoolInfo storage pool = poolInfo[_pid];
//   UserInfo storage user = userInfo[_pid][_user];
//   uint256 accSushiPerShare = pool.accSushiPerShare;
//   uint256 lpSupply = pool.lpToken.balanceOf(address(this));
//   if (block.number > pool.lastRewardBlock && lpSupply != 0) {
//       uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
//       uint256 sushiReward = multiplier.mul(sushiPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
//       accSushiPerShare = accSushiPerShare.add(sushiReward.mul(1e12).div(lpSupply));
//   }
//   return user.amount.mul(accSushiPerShare).div(1e12).sub(user.rewardDebt);




};
