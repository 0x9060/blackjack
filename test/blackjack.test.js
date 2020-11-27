// SPDX-License-Identifier: GPL-3.0-or-later
let Blackjack = artifacts.require('Blackjack')
let catchRevert = require("./exceptionsHelpers.js").catchRevert

contract('Blackjack', function(accounts) {

    const owner = accounts[0]
    const alice = accounts[1]
    const bob = accounts[2]

    let instance

    before(async () => {
        instance = await Blackjack.new()
        instance.send(web3.utils.toWei("1", "ether"))
    })

    /// newRound Tests
    it("should have one dealer card and two player cards for a new round", async() => {
        await instance.newRound({from: alice, value: 100})
        const dealer = await instance.getDealerState({from: alice})
        const player = await instance.getPlayerState({from: alice})
        assert.equal(dealer.hand.length, 1, 'Dealer should have only one card to start new games')
        assert.equal(player.hand.length, 2, 'Player should have only two cards to start new games')
    })

    it("should only be able to act in ones own game", async() => {
        await instance.newRound({from: alice, value: 100})
        await catchRevert(instance.hit({from: bob}))
    })

    /// doubleDown Tests
    it("should not be able to double down after hitting", async() => {
        await instance.newRound({from: alice, value: 100})
        const score = await instance.getPlayerState({from: alice}).handScore
        if (score < 21) {
            await instance.hit({from: alice})
            await catchRevert(instance.doubleDown({from: alice}))
        }
    })

    it("should not be able to double down after standing", async() => {
        await instance.newRound({from: alice, value: 100})
        await instance.stand({from: alice})
        await catchRevert(instance.doubleDown({from: alice}))
    })

    it("should not be able to double for more than original bet", async() => {
        await instance.newRound({from: alice, value: 100})
        await catchRevert(instance.doubleDown({from: alice, value: 200}))
    })

    it("should be able to double for exactly the original bet size", async() => {
        await instance.newRound({from: alice, value: 100})
        await instance.doubleDown({from: alice, value: 100})
    })

    it("should be able to double for less than original bet", async() => {
        await instance.newRound({from: alice, value: 100})
        await instance.doubleDown({from: alice, value: 20})
    })

    it("should be able to double down after a new round", async() => {
        await instance.newRound({from: alice, value: 100})
        await instance.doubleDown({from: alice, value: 100})
    })

    /// split Tests
    it("should not be able to split after hitting", async() => {
        await instance.newRound({from: alice, value: 100})
        await instance.hit({from: alice})
        await catchRevert(instance.split({from: alice}))
    })

    it("should not be able to split after standing", async() => {
        await instance.newRound({from: alice, value: 100})
        await instance.stand({from: alice})
        await catchRevert(instance.split({from: alice}))

    })

    /// hit Tests
    it("should have three cards after hitting once", async() => {
        await instance.newRound({from: alice, value: 100})
        const dealer = await instance.getDealerState({from: alice})
        var player = await instance.getPlayerState({from: alice})
        assert.equal(dealer.hand.length, 1, 'Dealer should have only one card to start new games')
        assert.equal(player.hand.length, 2, 'Player should have only two cards to start new games')
        await instance.hit({from: alice})
        player = await instance.getPlayerState({from: alice})
        assert.equal(player.hand.length, 3, 'Player should have three cards after hitting once')
    })

    // test for busting
    it("should not be able to hit after busting", async() => {
        await instance.newRound({from: alice, value: 100})

        do {
            await instance.hit({from: alice})
            var player = await instance.getPlayerState({from: alice})
        } while(player.handScore < 21)

        await catchRevert(instance.hit({from: alice}))
    })

    //    /// stand Tests
    it("should have two cards when standing", async() => {
        await instance.newRound({from: alice, value: 100})
        var dealer = await instance.getDealerState({from: alice})
        const player = await instance.getPlayerState({from: alice})
        assert.equal(dealer.hand.length, 1, 'Dealer should have only one card to start new games')
        assert.equal(player.hand.length, 2, 'Player should have only two cards to start new games')
        await instance.stand({from: alice})
        dealer = await instance.getDealerState({from: alice})
        assert.equal(dealer.hand.length > 1, true, 'Dealer should have more than one card after concluding game')
        assert.equal(player.hand.length, 2, 'Player should still have only two cards')
    })

})
