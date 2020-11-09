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

