const { expectRevert } = require('@openzeppelin/test-helpers');
const NSP = artifacts.require('NSP');

contract('NSP', ([alice, bob, carol]) => {
    beforeEach(async () => {
        this.nsp = await NSP.new({ from: alice });
    });

    it('should have correct name and symbol and decimal', async () => {
        const name = await this.nsp.name();
        const symbol = await this.nsp.symbol();
        const decimals = await this.nsp.decimals();
        assert.equal(name.valueOf(), 'NewSwapPower');
        assert.equal(symbol.valueOf(), 'NSP');
        assert.equal(decimals.valueOf(), '18');
    });

    it('should only allow owner to mint token', async () => {
        await this.nsp.mint(alice, '100', { from: alice });
        await this.nsp.mint(bob, '1000', { from: alice });
        await expectRevert(
            this.nsp.mint(carol, '1000', { from: bob }),
            'Ownable: caller is not the owner',
        );
        const totalSupply = await this.nsp.totalSupply();
        const aliceBal = await this.nsp.balanceOf(alice);
        const bobBal = await this.nsp.balanceOf(bob);
        const carolBal = await this.nsp.balanceOf(carol);
        assert.equal(totalSupply.valueOf(), '1100');
        assert.equal(aliceBal.valueOf(), '100');
        assert.equal(bobBal.valueOf(), '1000');
        assert.equal(carolBal.valueOf(), '0');
    });

    it('should supply token transfers properly', async () => {
        await this.nsp.mint(alice, '100', { from: alice });
        await this.nsp.mint(bob, '1000', { from: alice });
        await this.nsp.transfer(carol, '10', { from: alice });
        await this.nsp.transfer(carol, '100', { from: bob });
        const totalSupply = await this.nsp.totalSupply();
        const aliceBal = await this.nsp.balanceOf(alice);
        const bobBal = await this.nsp.balanceOf(bob);
        const carolBal = await this.nsp.balanceOf(carol);
        assert.equal(totalSupply.valueOf(), '1100');
        assert.equal(aliceBal.valueOf(), '90');
        assert.equal(bobBal.valueOf(), '900');
        assert.equal(carolBal.valueOf(), '110');
    });

    it('should fail if you try to do bad transfers', async () => {
        await this.nsp.mint(alice, '100', { from: alice });
        await expectRevert(
            this.nsp.transfer(carol, '110', { from: alice }),
            'ERC20: transfer amount exceeds balance',
        );
        await expectRevert(
            this.nsp.transfer(carol, '1', { from: bob }),
            'ERC20: transfer amount exceeds balance',
        );
    });
  });
