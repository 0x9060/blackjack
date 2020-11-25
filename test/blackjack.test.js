// SPDX-License-Identifier: GPL-3.0-or-later
let Blackjack = artifacts.require('Blackjack')
let catchRevert = require("./exceptionsHelpers.js").catchRevert

contract('Blackjack', function(accounts) {

    const owner = accounts[0]
    const alice = accounts[1]
    const bob = accounts[2]
    const emptyAddress = '0x0000000000000000000000000000000000000000'

    let instance

    beforeEach(async () => {
        instance = await Blackjack.new()
	instance.send(web3.utils.toWei("1", "ether"))
    })

    it("should not be able to double down after hitting", async() => {
        await instance.newRound({from: alice, value: 100})
	await instance.hit({from: alice})
        await catchRevert(instance.doubleDown({from: alice}))
    })

    it("should not be able to double down after hitting, v2", async() => {
        await instance.newRound({from: alice, value: 100})
	await instance.hit({from: alice})
        await instance.doubleDown({from: alice})
    })

    it("should not be able to double down after hitting, v3", async() => {
        await instance.newRound({from: alice, value: 100})
        await catchRevert(instance.doubleDown({from: alice, value: 100}))
    })

    it("should not be able to double down after hitting, v4", async() => {
        await instance.newRound({from: alice, value: 100})
        await instance.doubleDown({from: alice, value: 100})
    })

    it("failed assertion", async() => {
        assert.equal(0, 1, 'Not equal')
    })

})
