const MasterChef = artifacts.require("MasterChef");
const SushiToken = artifacts.require("SushiToken");
const SushiBar = artifacts.require("SushiBar");
const UniswapV2Pair = artifacts.require("UniswapV2Pair");
const SushiMaker = artifacts.require("SushiMaker");
const NSP = artifacts.require("NSP");
const NSPBar = artifacts.require("NSPBar");
const NSPMaker = artifacts.require("NSPMaker");


module.exports = async function (deployer, network, accounts) {
  console.log("accounts[0]:"+accounts[0]);

  const factory = "0x723913136a42684B5e3657e3cD2f67ee3e83A82D"; // test/main
  const wnew = "0xf4905b9bc02ce21c98eac1803693a9357d5253bf" // test/main

  // 部署NST合约
  await deployer.deploy(SushiToken);
  const sushiToken = await SushiToken.deployed();
  console.log("NST(sushiToken):"+ sushiToken.address);
  // 部署sushiBar(xNST)合约
  await deployer.deploy(SushiBar, sushiToken.address);
  const sushiBar = await SushiBar.deployed();
  console.log("sushiBar(xNST):"+ sushiBar.address);
  // 部署nstMaker(sushiMaker)
  await deployer.deploy(SushiMaker, factory, sushiBar.address, sushiToken.address, wnew)
  const sushiMaker = await SushiMaker.deployed();
  console.log("nstMaker(sushiMaker):"+ sushiMaker.address);
  
  // 部署NSP合约
  await deployer.deploy(NSP);
  const nsp = await NSP.deployed();
  console.log("NSP:"+ nsp.address);
  // 部署nspBar(xNSP)合约
  await deployer.deploy(NSPBar, nsp.address);
  const nspBar = await NSPBar.deployed();
  console.log("NSPBar(xNSP):"+ nspBar.address);
  // 部署nspMaker
  await deployer.deploy(NSPMaker, factory, nspBar.address, nsp.address, sushiToken.address, wnew)
  const nspMaker = await NSPMaker.deployed();
  console.log("nspMaker:"+ nspMaker.address);

  // 部署masterChef
  const devaddr = nspMaker.address;
  const sushiPerBlock = web3.utils.toWei("1", 'ether');
  const startBlock = 0;
  //_sushi, _devaddr, _sushiPerBlock, _startBlock, _bonusEndBlock, _nsp, _wnew, _factory, _nspBar
  await deployer.deploy(MasterChef, sushiToken.address, devaddr, sushiPerBlock, startBlock, 0, nsp.address, wnew, factory, nspBar.address)
  var masterChef = await MasterChef.deployed();
  console.log("masterChef:"+ masterChef.address);

  // nst owner改成 masterChef    转之前先预铸出？     TODO 如果用发币宝代替sushiToken，则需要将masterChef设置为minter
  await sushiToken.transferOwnership(masterChef.address)
  var owner = await sushiToken.owner();
  console.log("nst owner transfer to:"+owner);

  // 创建nusdt-new矿池
  const NUSDT_NEW = '0x56ae975581a382193ff36579c81281e179486c43' //TESTNET
  await masterChef.add(100, NUSDT_NEW, true)
  var poolLength = await masterChef.poolLength()
  console.log(Number(poolLength))
  var pool = await masterChef.poolInfo(poolLength-1)
  console.log("lpToken: " + pool['lpToken'])
  console.log("allocPoint: " + Number(pool['allocPoint']))
  console.log("lastRewardBlock:" + Number(pool['lastRewardBlock']))
  console.log("accSushiPerShare: " + Number(pool['accSushiPerShare']))


  // 创建nst-new矿池 TODO 这个需要修改
  // const NST_NEW = '0xffb1f3c23fe8ec28cd4e11711f6321f828f9cb60' //TESTNET
  // await masterChef.add(100, NST_NEW, true)
  // var poolLength = await masterChef.poolLength()
  // console.log(Number(poolLength))
  // // var pool = await masterChef.poolInfo(poolLength-1)
  // // console.log(pool)
 
  // testnet  TODO 全部修改，重新部署
  // NST(sushiToken):0xea8c987f9bf1688c714a5b9d9e2f4f9ef294f328
  // xNST(sushiBar):0x986a646d9522a9cde91f551bb08c0d78fd72c83d
  // masterChef:0x82a8fbeec9f1706944f1a750eaca0ce6817edcb7 
  // nstMaker(sushiMaker): 0x961e2C89ef87D32cb01b83232AaB247a24F3810c
  // 第一个矿池NUSDT_NEW: 0x56aE975581a382193FF36579C81281E179486c43
  // 第二个矿池NST_NEW: 0xffb1f3c23fe8ec28cd4e11711f6321f828f9cb60



   // 部署测试网 nstMaker(sushiMaker)
  // const factory = "0x723913136a42684B5e3657e3cD2f67ee3e83A82D";
  // const bar = "0x986a646d9522a9cde91f551bb08c0d78fd72c83d"
  // const nst = "0xea8c987f9bf1688c714a5b9d9e2f4f9ef294f328"
  // const wnew = "0xf4905b9bc02ce21c98eac1803693a9357d5253bf"
  // // _factory, _bar, _sushi, _weth
  // await deployer.deploy(SushiMaker, factory, bar, nst, wnew)
  // var sushiMaker = await SushiMaker.deployed();
  // console.log("sushiMaker:"+ sushiMaker.address);

  

  // sushimaker将token转成nst放入sushiBar
  // const nstPair = await UniswapV2Pair.at('0xffb1f3c23fe8ec28cd4e11711f6321f828f9cb60')
  // const bal1_1 = await nstPair.balanceOf('0x961e2C89ef87D32cb01b83232AaB247a24F3810c');
  // console.log(bal1_1/1e18)
  // const nst = await UniswapV2Pair.at('0xea8c987f9bf1688c714a5b9d9e2f4f9ef294f328')
  // const bal2_1 = await nst.balanceOf('0x986a646d9522a9cde91f551bb08c0d78fd72c83d');
  // console.log(bal2_1/1e18)
  // const nstMaker = await SushiMaker.at('0x961e2C89ef87D32cb01b83232AaB247a24F3810c')
  // await nstMaker.convert('0xea8c987f9bf1688c714a5b9d9e2f4f9ef294f328','0xf4905b9bc02ce21c98eac1803693a9357d5253bf')
  // const bal1_2 = await nstPair.balanceOf('0x961e2C89ef87D32cb01b83232AaB247a24F3810c');
  // console.log(bal1_2/1e18)
  // const bal2_2 = await nst.balanceOf('0x986a646d9522a9cde91f551bb08c0d78fd72c83d');
  // console.log(bal2_2/1e18)


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
