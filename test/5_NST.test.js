const { expectRevert } = require('@openzeppelin/test-helpers');
const NST = artifacts.require('NST');

contract('NST', ([alice, bob, carol]) => {
    beforeEach(async () => {
        this.nst = await NST.new({ from: alice });
    });

    it('should have correct name and symbol and decimal', async () => {
        const name = await this.nst.name();
        const symbol = await this.nst.symbol();
        const decimals = await this.nst.decimals();
        assert.equal(name.valueOf(), 'NewSwapToken');
        assert.equal(symbol.valueOf(), 'NST');
        assert.equal(decimals.valueOf(), '18');
    });

    it('should only allow owner to mint token', async () => {
        await this.nst.mint(alice, '100', { from: alice });
        await this.nst.mint(bob, '1000', { from: alice });
        await expectRevert(
            this.nst.mint(carol, '1000', { from: bob }),
            'Ownable: caller is not the owner',
        );
        const totalSupply = await this.nst.totalSupply();
        const aliceBal = await this.nst.balanceOf(alice);
        const bobBal = await this.nst.balanceOf(bob);
        const carolBal = await this.nst.balanceOf(carol);
        assert.equal(totalSupply.valueOf(), '1100');
        assert.equal(aliceBal.valueOf(), '100');
        assert.equal(bobBal.valueOf(), '1000');
        assert.equal(carolBal.valueOf(), '0');
    });

    it('should supply token transfers properly', async () => {
        await this.nst.mint(alice, '100', { from: alice });
        await this.nst.mint(bob, '1000', { from: alice });
        await this.nst.transfer(carol, '10', { from: alice });
        await this.nst.transfer(carol, '100', { from: bob });
        const totalSupply = await this.nst.totalSupply();
        const aliceBal = await this.nst.balanceOf(alice);
        const bobBal = await this.nst.balanceOf(bob);
        const carolBal = await this.nst.balanceOf(carol);
        assert.equal(totalSupply.valueOf(), '1100');
        assert.equal(aliceBal.valueOf(), '90');
        assert.equal(bobBal.valueOf(), '900');
        assert.equal(carolBal.valueOf(), '110');
    });

    it('should fail if you try to do bad transfers', async () => {
        await this.nst.mint(alice, '100', { from: alice });
        await expectRevert(
            this.nst.transfer(carol, '110', { from: alice }),
            'ERC20: transfer amount exceeds balance',
        );
        await expectRevert(
            this.nst.transfer(carol, '1', { from: bob }),
            'ERC20: transfer amount exceeds balance',
        );
    });
  });
