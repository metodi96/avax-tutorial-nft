const Collectible = artifacts.require('./Collectible')
const truffleAssert = require('truffle-assertions')

contract('Collectible', ([owner, artist, buyer]) => {
    let collectible;

    before(async () => {
        collectible = await Collectible.new()
    });

    describe('Collectible deployment', async () => {
        it('Deploys the Collectible SC successfully.', async () => {
            console.log('Address is ', collectible.address)
            assert.notEqual(collectible.address, '', 'should not be empty');
            assert.notEqual(collectible.address, 0x0, 'should not be the 0x0 address');
            assert.notEqual(collectible.address, null, 'should not be null');
            assert.notEqual(collectible.address, undefined, 'should not be undefined');
        })

        it('The collectible SC should have a name and a symbol.', async () => {
            const name = await collectible.name()
            assert.equal(name, 'NFTCollectible', 'The name should be NFTCollectible.')
            const symbol = await collectible.symbol()
            assert.equal(symbol, 'NFTC', 'The symbol should be NFTC.')
        })
    })
});
