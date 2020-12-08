const { expectRevert, time } = require('@openzeppelin/test-helpers');
const NST = artifacts.require('NST');
const MasterChef = artifacts.require('MasterChef');
const MockERC20 = artifacts.require('MockERC20');

// 本地跑测试用例，每次重启ganache-cli -h 0.0.0.0
contract('MasterChef', ([alice, bob, carol, dev, minter]) => {
    beforeEach(async () => {
        this.nst = await NST.new({ from: alice });
    });

    it('should set correct state variables', async () => {
        this.chef = await MasterChef.new(this.nst.address, dev, '1000', '100', '10000', { from: alice });
        await this.nst.transferOwnership(this.chef.address, { from: alice });
        const nst = await this.chef.nst();
        const devaddr = await this.chef.devaddr();
        const owner = await this.nst.owner();
        const nstPerBlock = await this.chef.nstPerBlock();
        const startBlock = await this.chef.startBlock();
        const endBlock = await this.chef.endBlock();

        assert.equal(nst.valueOf(), this.nst.address);
        assert.equal(devaddr.valueOf(), dev);
        assert.equal(owner.valueOf(), this.chef.address);
        assert.equal(nstPerBlock.valueOf(), '1000');
        assert.equal(startBlock.valueOf(), '100');
        assert.equal(endBlock.valueOf(), '10000');
    });

    it('should allow owner and only owner to update dev', async () => {
        this.chef = await MasterChef.new(this.nst.address, dev, '1000', '0', '1000', { from: alice });
        assert.equal((await this.chef.devaddr()).valueOf(), dev);
        await expectRevert(this.chef.dev(bob, { from: dev }), 'Ownable: caller is not the owner');
        await this.chef.dev(bob, { from: alice });
        assert.equal((await this.chef.devaddr()).valueOf(), bob);
        await this.chef.dev(alice, { from: alice });
        assert.equal((await this.chef.devaddr()).valueOf(), alice);
    })

    it('should allow owner and only owner to set feeRate', async () => {
        this.chef = await MasterChef.new(this.nst.address, dev, '1000', '0', '1000', { from: alice });
        assert.equal((await this.chef.feeRate()).valueOf(), '1000');
        await expectRevert(this.chef.setFeeRate('10', { from: dev }), 'Ownable: caller is not the owner');
        await this.chef.setFeeRate('10', { from: alice });
        assert.equal((await this.chef.feeRate()).valueOf(), '10');
    })

    it('should allow owner and only owner to activate', async () => {
        this.chef = await MasterChef.new(this.nst.address, dev, '1000', '0', '1000', { from: alice });
        await expectRevert(this.chef.activate('3000', '5', true, {from: dev}), 'Ownable: caller is not the owner');
        await this.chef.activate('3000', '5', true, {from: alice});
        assert.equal((await this.chef.endBlock()).valueOf(), '3000');
        assert.equal((await this.chef.nstPerBlock()).valueOf(), '5');
    })

    context('With ERC/LP token added to the field', () => {
        beforeEach(async () => {
            this.lp = await MockERC20.new('LPToken', 'LP', '10000000000', { from: minter });
            await this.lp.transfer(alice, '10000', { from: minter });
            await this.lp.transfer(bob, '10000', { from: minter });
            await this.lp.transfer(carol, '10000', { from: minter });
            this.lp2 = await MockERC20.new('LPToken2', 'LP2', '10000000000', { from: minter });
            await this.lp2.transfer(alice, '10000', { from: minter });
            await this.lp2.transfer(bob, '10000', { from: minter });
            await this.lp2.transfer(carol, '10000', { from: minter });
        });

        it('should allow emergency withdraw', async () => {
            // 100 per block farming rate starting at block 100 with bonus until block 1000
            this.chef = await MasterChef.new(this.nst.address, dev, '100', '100', '1000', { from: alice });
            await this.chef.add('100', this.lp.address, true);
            await this.lp.approve(this.chef.address, '10000', { from: bob });
            await this.chef.deposit(0, '1000', { from: bob });
            assert.equal((await this.lp.balanceOf(bob)).valueOf(), '9000');
            assert.equal((await this.lp.balanceOf(dev)).valueOf(), '1');
            await this.chef.emergencyWithdraw(0, { from: bob });
            assert.equal((await this.lp.balanceOf(bob)).valueOf(), '9999');
        });

        it('should give out NSTs only after farming time', async () => {
            // 1000 per block farming rate starting at block 100 with bonus until block 1000
            this.chef = await MasterChef.new(this.nst.address, dev, web3.utils.toWei('1000', 'ether'), '100', '1000', { from: alice });
            await this.nst.transferOwnership(this.chef.address, { from: alice });
            await this.chef.add('100', this.lp.address, true);
            await this.lp.approve(this.chef.address, '1000', { from: bob });
            await this.chef.deposit(0, '1000', { from: bob });
            assert.equal((await this.lp.balanceOf(dev)).valueOf(), '1');
            await time.advanceBlockTo('89');
            await this.chef.deposit(0, '0', { from: bob }); // block 90
            assert.equal((await this.nst.balanceOf(bob)).valueOf(), '0');
            await time.advanceBlockTo('94');
            await this.chef.deposit(0, '0', { from: bob }); // block 95
            assert.equal((await this.nst.balanceOf(bob)).valueOf(), '0');
            await time.advanceBlockTo('99');
            await this.chef.deposit(0, '0', { from: bob }); // block 100
            assert.equal((await this.nst.balanceOf(bob)).valueOf(), '0');
            await time.advanceBlockTo('100')
            await this.chef.deposit(0, '0', { from: bob }); // block 101
            assert.equal((await this.nst.balanceOf(bob))/1e18, '900');
            assert.equal((await this.nst.balanceOf(dev))/1e18, '100');
            await time.advanceBlockTo('104');
            await this.chef.deposit(0, '0', { from: bob }); // block 105
            assert.equal((await this.nst.balanceOf(bob))/1e18, '4500');
            assert.equal((await this.nst.balanceOf(dev))/1e18, '500');
            assert.equal((await this.nst.totalSupply())/1e18, '5000');
        });

        it('should not distribute NSTs if no one deposit', async () => {
            // 1000 per block farming rate starting at block 200 with bonus until block 1000
            this.chef = await MasterChef.new(this.nst.address, dev, web3.utils.toWei('1000', 'ether'), '200', '1000', { from: alice });
            await this.nst.transferOwnership(this.chef.address, { from: alice });
            await this.chef.add('100', this.lp.address, true);
            await this.lp.approve(this.chef.address, '10000', { from: bob });
            await time.advanceBlockTo('199');
            assert.equal((await this.nst.totalSupply()).valueOf(), '0');
            await time.advanceBlockTo('204');
            assert.equal((await this.nst.totalSupply()).valueOf(), '0');
            await time.advanceBlockTo('209');
            await this.chef.deposit(0, '1000', { from: bob }); // block 210
            assert.equal((await this.nst.totalSupply()).valueOf(), '0');
            assert.equal((await this.nst.balanceOf(bob)).valueOf(), '0');
            assert.equal((await this.nst.balanceOf(dev)).valueOf(), '0');
            assert.equal((await this.lp.balanceOf(bob)).valueOf(), '9000');
            assert.equal((await this.lp.balanceOf(dev)).valueOf(), '1');
            assert.equal((await this.lp.balanceOf(this.chef.address)).valueOf(), '999');
            await time.advanceBlockTo('218');
            await expectRevert(this.chef.withdraw(0, '1000', { from: bob }), 'withdraw: not good'); //219
            await this.chef.withdraw(0, '999', { from: bob }); // block 220
            assert.equal((await this.nst.totalSupply())/1e18, '10000');
            assert.equal((await this.nst.balanceOf(bob))/1e18, '9000');
            assert.equal((await this.nst.balanceOf(dev))/1e18, '1000');
            assert.equal((await this.lp.balanceOf(bob)).valueOf(), '9999');
        });

        it('should distribute NSTs properly for each staker', async () => {
            // 1000 per block farming rate starting at block 300 with bonus until block 1000
            this.chef = await MasterChef.new(this.nst.address, dev, web3.utils.toWei('1000', 'ether'), '300', '1000', { from: alice });
            await this.nst.transferOwnership(this.chef.address, { from: alice });
            await this.chef.add('100', this.lp.address, true);
            await this.lp.approve(this.chef.address, '10000', { from: alice });
            await this.lp.approve(this.chef.address, '10000', { from: bob });
            await this.lp.approve(this.chef.address, '10000', { from: carol });
            // Alice deposits 10 LPs at block 310
            await time.advanceBlockTo('309');
            await this.chef.deposit(0, '1001', { from: alice });
            // Bob deposits 20 LPs at block 314
            await time.advanceBlockTo('313');
            await this.chef.deposit(0, '2002', { from: bob });
            // Carol deposits 30 LPs at block 318
            await time.advanceBlockTo('317');
            await this.chef.deposit(0, '3003', { from: carol });
            assert.equal((await this.lp.balanceOf(dev)).valueOf(), '6');
            // Alice deposits 10 more LPs at block 320. At this point:
            //   Alice should have: 4*900 + 4*1/3*900 + 2*1/6*900 = 5100
            //   MasterChef should have the remaining: 9000 - 5100 = 3900
            await time.advanceBlockTo('319')
            await this.chef.deposit(0, '1001', { from: alice });
            assert.equal((await this.nst.totalSupply())/1e18, '10000');
            assert.equal(parseInt((await this.nst.balanceOf(alice))/1e18), '5100');
            assert.equal((await this.nst.balanceOf(bob))/1e18, '0');
            assert.equal((await this.nst.balanceOf(carol))/1e18, '0');
            assert.equal(parseInt((await this.nst.balanceOf(this.chef.address))/1e18), '3900');
            assert.equal((await this.nst.balanceOf(dev))/1e18, '1000');

            // Bob withdraws 5 LPs at block 330. At this point:
            //   Bob should have: 4*2/3*900 + 2*2/6*900 + 10*2/7*900 = 5571
            await time.advanceBlockTo('329')
            await this.chef.withdraw(0, '1000', { from: bob });
            assert.equal((await this.nst.totalSupply())/1e18, '20000');
            assert.equal(Math.round((await this.nst.balanceOf(alice))/1e18), '5100');
            assert.equal(Math.round((await this.nst.balanceOf(bob))/1e18), '5571');
            assert.equal((await this.nst.balanceOf(carol))/1e18, '0');
            assert.equal(Math.round((await this.nst.balanceOf(this.chef.address))/1e18), '7329');
            assert.equal((await this.nst.balanceOf(dev))/1e18, '2000');
            // Alice withdraws all LPs at block 340.
            // Bob withdraws all LPs at block 350.
            // Carol withdraws all LPs at block 360.
            await time.advanceBlockTo('339')
            await this.chef.withdraw(0, '2000', { from: alice });
            await time.advanceBlockTo('349')
            await this.chef.withdraw(0, '1000', { from: bob });
            await time.advanceBlockTo('359')
            await this.chef.withdraw(0, '3000', { from: carol });
            assert.equal(Math.round((await this.nst.totalSupply())/1e18), '50000');
            assert.equal((await this.nst.balanceOf(dev))/1e18, '5000');
            // Alice should have: 5100 + 10*2/7*900 + 10*2/6*900 = 10671
            assert.equal(Math.round((await this.nst.balanceOf(alice))/1e18), '10671');
            // Bob should have: 5571 + 10*1/6*900 + 10*1/4*900 = 9321
            assert.equal(Math.round((await this.nst.balanceOf(bob))/1e18), '9321');
            // Carol should have: 2*3/6*900 + 10*3/7*900 + 10*3/6*900 + 10*3/4*900 + 10*900 = 25007
            assert.equal(Math.round((await this.nst.balanceOf(carol))/1e18), '25007');

            // All of them should have 1000 LPs back.
            assert.equal((await this.lp.balanceOf(alice)).valueOf(), '9998');
            assert.equal((await this.lp.balanceOf(bob)).valueOf(), '9998');
            assert.equal((await this.lp.balanceOf(carol)).valueOf(), '9997');
        });

        it('should give proper NSTs allocation to each pool', async () => {
            // 1000 per block farming rate starting at block 400 with bonus until block 1000
            this.chef = await MasterChef.new(this.nst.address, dev, '1000', '400', '1000', { from: alice });
            await this.nst.transferOwnership(this.chef.address, { from: alice });
            await this.lp.approve(this.chef.address, '10000', { from: alice });
            await this.lp2.approve(this.chef.address, '10000', { from: bob });
            // Add first LP to the pool with allocation 1
            await this.chef.add('10', this.lp.address, true);
            // Alice deposits 10 LPs at block 410
            await time.advanceBlockTo('409');
            await this.chef.deposit(0, '1001', { from: alice });
            // Add LP2 to the pool with allocation 2 at block 420
            await time.advanceBlockTo('419');
            await this.chef.add('20', this.lp2.address, true);
            // Alice should have 10*900 pending reward
            assert.equal((await this.chef.pendingNST(0, alice)).valueOf(), '9000');
            // Bob deposits 10 LP2s at block 425
            await time.advanceBlockTo('424');
            await this.chef.deposit(1, '1001', { from: bob });
            // Alice should have 9000 + 5*1/3*900 = 10500 pending reward
            assert.equal((await this.chef.pendingNST(0, alice)).valueOf(), '10500');
            await time.advanceBlockTo('430');
            // At block 430. Bob should get 5*2/3*900 = 3333. Alice should get 10500+1500=12000 .
            assert.equal((await this.chef.pendingNST(0, alice)).valueOf(), '12000');
            assert.equal((await this.chef.pendingNST(1, bob)).valueOf(), '3000');       
        });

        it('should stop giving bonus NSTs after the endblock', async () => {
            // 1000 per block farming rate starting at block 500 with bonus until block 600
            this.chef = await MasterChef.new(this.nst.address, dev, '1000', '500', '600', { from: alice });
            await this.nst.transferOwnership(this.chef.address, { from: alice });
            await this.lp.approve(this.chef.address, '10000', { from: alice });
            await this.chef.add('1', this.lp.address, true);
            // Alice deposits 10 LPs at block 590
            await time.advanceBlockTo('589');
            await this.chef.deposit(0, '1001', { from: alice });
            // At block 605, she should have 900*10 + 0*5 = 9000 pending.
            await time.advanceBlockTo('605');
            assert.equal((await this.chef.pendingNST(0, alice)).valueOf(), '9000');
            // At block 606, Alice withdraws all pending rewards and should get 9000.
            await this.chef.deposit(0, '0', { from: alice });
            assert.equal((await this.chef.pendingNST(0, alice)).valueOf(), '0');
            assert.equal((await this.nst.balanceOf(alice)).valueOf(), '9000');
            assert.equal((await this.nst.balanceOf(dev)).valueOf(), '1000');
            await time.advanceBlockTo('610');
            await this.chef.deposit(0, '1001', { from: alice });
            assert.equal((await this.chef.pendingNST(0, alice)).valueOf(), '0');
            await time.advanceBlockTo('620');
            await this.chef.withdraw(0, '2000', { from: alice }); // non add bonus
            assert.equal((await this.chef.pendingNST(0, alice)).valueOf(), '0');
            assert.equal((await this.nst.balanceOf(alice)).valueOf(), '9000');
            assert.equal((await this.nst.balanceOf(dev)).valueOf(), '1000');           
        });

        it('should giving bonus NSTs after activate', async () => {
            // 1000 per block farming rate starting at block 700 with bonus until block 800
            this.chef = await MasterChef.new(this.nst.address, dev, '1000', '700', '800', { from: alice });
            await this.nst.transferOwnership(this.chef.address, { from: alice });
            await this.lp.approve(this.chef.address, '10000', { from: alice });
            await this.chef.add('1', this.lp.address, true);
            // Alice deposits 10 LPs at block 790
            await time.advanceBlockTo('789');
            await this.chef.deposit(0, '1001', { from: alice });
            // At block 805, she should have 900*10 + 0*5 = 9000 pending.
            await time.advanceBlockTo('805');
            assert.equal((await this.chef.pendingNST(0, alice)).valueOf(), '9000');
            // At block 806, Alice withdraws all pending rewards and should get 9000.
            await this.chef.deposit(0, '0', { from: alice });
            assert.equal((await this.chef.pendingNST(0, alice)).valueOf(), '0');
            assert.equal((await this.nst.balanceOf(alice)).valueOf(), '9000');
            assert.equal((await this.nst.balanceOf(dev)).valueOf(), '1000');

            // activate at block 810, nstPerBlock set 2000
            await time.advanceBlockTo('809');
            await this.chef.activate('1000', '2000', true, {from: alice});
            // at block 820, she should have 1800*10 = 18000 pending.
            await time.advanceBlockTo('820');
            assert.equal((await this.chef.pendingNST(0, alice)).valueOf(), '18000');
            // at block 821, Alice withdraws all pending rewards and should get 1800*11=19800.
            await this.chef.deposit(0, '0', { from: alice });
            assert.equal((await this.chef.pendingNST(0, alice)).valueOf(), '0');
            assert.equal((await this.nst.balanceOf(alice)).valueOf(), '28800');
            assert.equal((await this.nst.balanceOf(dev)).valueOf(), '3200');           
        });
    });
});
