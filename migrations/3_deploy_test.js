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

  const nspMaker = "0xc0d74c05fcd7274e3C1355BF9eD5Ba1d1215d12b"
  // TODO 测试 将nspMaker持有的nusdt-new、nst转成nsp
  const pair = await UniswapV2Pair.at('0x56ae975581a382193ff36579c81281e179486c43'); //NUSDT_NEW
  const bal = await pair.balanceOf(nspMaker);
  console.log(bal/1e18);
  const nst = await UniswapV2Pair.at('0xb627764e8833Ad2b4dc4F53DdBCe57611801AE1C'); //nst
  const bal2 = await nst.balanceOf(nspMaker);
  console.log(bal2/1e18); //638.4

  // TODO 激活
  const masterChef = await MasterChef.at("0x78260098C307b381FFF9Ee21AD22425A4f26C832");
  // const sushiPerBlock = web3.utils.toWei("32", 'ether');
  // const number = await web3.eth.getBlockNumber();
  // console.log(number)
  // const endBlock = number+2+(10*24*60*20)   //再挖10天-1个区块
  // var tx = await masterChef.activate(endBlock, sushiPerBlock, true)
  // console.log(tx)




  

  // // 部署NSP合约
  // await deployer.deploy(NSP);
  // const nsp = await NSP.deployed();
  // console.log("NSP:"+ nsp.address);
  // // 部署nspBar(xNSP)合约
  // await deployer.deploy(NSPBar, nsp.address);
  // const nspBar = await NSPBar.deployed();
  // console.log("NSPBar(xNSP):"+ nspBar.address);
  // // 部署nspMaker
  // await deployer.deploy(NSPMaker, factory, nspBar.address, nsp.address, wnew)
  // const nspMaker = await NSPMaker.deployed();
  // console.log("nspMaker:"+ nspMaker.address);


  // const nsp = await NSP.at("0xf3FC63F6293B5E33E87351CB3bfDd21E1348a9C1");
  // await nsp.mint(accounts[1], web3.utils.toWei("100", 'ether'));
  // const bal = await nsp.balanceOf(accounts[1]);
  // console.log(bal/1e18);
};

