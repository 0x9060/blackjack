import React, { Component } from "react";
import BlackjackContract from "./contracts/Blackjack.json";
import getWeb3 from "./getWeb3";

import "./App.css";

class App extends Component {

    constructor(){
        super();
        this.state = { betSize: '', web3: null, playerAccount: null, game: null , dealerHand: [], playerHand: [], splitHand: []};
        this.onChange = this.onChange.bind(this)
    }

    onChange(e){
        const re = /^[0-9\b]+$/;
        if (e.target.value === '' || re.test(e.target.value)) {
            this.setState({betSize: e.target.value})
        }
    }

    componentDidMount = async () => {
        try {
            // Get network provider and web3 instance.
            const web3 = await getWeb3();

            var playerAccount = web3.currentProvider.selectedAddress;

            // Get the contract instance.
            const networkId = await web3.eth.net.getId();
            const gameNetwork = BlackjackContract.networks[networkId];
            const gameInstance = new web3.eth.Contract(
                BlackjackContract.abi,
                gameNetwork && gameNetwork.address,
            );
            // Set web3, accounts, and contract to the state, and then proceed with an
            // example of interacting with the contract's methods.
            const responseGame = await gameInstance.methods.getGameState().call();
            this.setState({ web3, playerAccount, game: gameInstance, maxBet: responseGame.gameMaxBet });

        } catch (error) {
            // Catch any errors for any of the above operations.
            alert(
                `Failed to load web3, accounts, or contract. Check console for details.`,
            );
            console.error(error);
        }
    };

    newRound = async () => {
        const { playerAccount , game } = this.state;

        await game.methods.newRound().send({ from: playerAccount, value: this.state.betSize, gas: 450000 });

        const responseDealer = await game.methods.getDealerState().call();
        const responsePlayer = await game.methods.getPlayerState().call();
        const responseGame = await game.methods.getGameState().call();

        this.setState({
            stage: responseGame.stage,
            maxBet: responseGame.gameMaxBet,
            dealerHand: responseDealer.hand,
            playerHand: responsePlayer.hand,
            splitHand: responsePlayer.splitHand,
            dealerScore: responseDealer.score,
            handScore: responsePlayer.handScore,
            splitHandScore: responsePlayer.splitHandScore,
            bet: responsePlayer.bet,
            splitBet: responsePlayer.splitBet,
            doubleDownBet: responsePlayer.doubleDownBet,
            splitDoubleDownBet: responsePlayer.splitDoubleDownBet
        });
    };

    split = async () => {
        const { playerAccount , game } = this.state;

        await game.methods.split().send({ from: playerAccount, value: this.state.betSize, gas: 450000 });

        const responseDealer = await game.methods.getDealerState().call();
        const responsePlayer = await game.methods.getPlayerState().call();
        const responseGame = await game.methods.getGameState().call();

        this.setState({
            stage: responseGame.stage,
            maxBet: responseGame.gameMaxBet,
            dealerHand: responseDealer.hand,
            playerHand: responsePlayer.hand,
            splitHand: responsePlayer.splitHand,
            dealerScore: responseDealer.score,
            handScore: responsePlayer.handScore,
            splitHandScore: responsePlayer.splitHandScore,
            bet: responsePlayer.bet,
            splitBet: responsePlayer.splitBet,
            doubleDownBet: responsePlayer.doubleDownBet,
            splitDoubleDownBet: responsePlayer.splitDoubleDownBet
        });
    };

    doubleDown = async () => {
        const { playerAccount , game } = this.state;

        await game.methods.doubleDown().send({ from: playerAccount, value: this.state.betSize, gas: 450000 });

        const responseDealer = await game.methods.getDealerState().call();
        const responsePlayer = await game.methods.getPlayerState().call();
        const responseGame = await game.methods.getGameState().call();

        this.setState({
            stage: responseGame.stage,
            maxBet: responseGame.gameMaxBet,
            dealerHand: responseDealer.hand,
            playerHand: responsePlayer.hand,
            splitHand: responsePlayer.splitHand,
            dealerScore: responseDealer.score,
            handScore: responsePlayer.handScore,
            splitHandScore: responsePlayer.splitHandScore,
            bet: responsePlayer.bet,
            splitBet: responsePlayer.splitBet,
            doubleDownBet: responsePlayer.doubleDownBet,
            splitDoubleDownBet: responsePlayer.splitDoubleDownBet
        });
    };

    hit = async () => {
        const { playerAccount , game } = this.state;

        await game.methods.hit().send({ from: playerAccount, gas: 450000 });

        const responseDealer = await game.methods.getDealerState().call();
        const responsePlayer = await game.methods.getPlayerState().call();
        const responseGame = await game.methods.getGameState().call();

        this.setState({
            stage: responseGame.stage,
            maxBet: responseGame.gameMaxBet,
            dealerHand: responseDealer.hand,
            playerHand: responsePlayer.hand,
            splitHand: responsePlayer.splitHand,
            dealerScore: responseDealer.score,
            handScore: responsePlayer.handScore,
            splitHandScore: responsePlayer.splitHandScore,
            bet: responsePlayer.bet,
            splitBet: responsePlayer.splitBet,
            doubleDownBet: responsePlayer.doubleDownBet,
            splitDoubleDownBet: responsePlayer.splitDoubleDownBet
        });

    };

    stand = async () => {
        const { playerAccount , game } = this.state;

        await game.methods.stand().send({ from: playerAccount, gas: 450000 });

        const responseDealer = await game.methods.getDealerState().call();
        const responsePlayer = await game.methods.getPlayerState().call();
        const responseGame = await game.methods.getGameState().call();

        this.setState({
            stage: responseGame.stage,
            maxBet: responseGame.gameMaxBet,
            dealerHand: responseDealer.hand,
            playerHand: responsePlayer.hand,
            splitHand: responsePlayer.splitHand,
            dealerScore: responseDealer.score,
            handScore: responsePlayer.handScore,
            splitHandScore: responsePlayer.splitHandScore,
            bet: responsePlayer.bet,
            splitBet: responsePlayer.splitBet,
            doubleDownBet: responsePlayer.doubleDownBet,
            splitDoubleDownBet: responsePlayer.splitDoubleDownBet
        });

    };

    render() {
        const rankStrings = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "T", "J", "Q", "K"]
        const rankValues = [11, 2, 3, 4, 5, 6, 7, 8, 9, 10, 10, 10, 10]
        const suitStrings = [String.fromCharCode(9827), String.fromCharCode(9830), String.fromCharCode(9829), String.fromCharCode(9824)]

        const canSplit = this.state.playerHand.length === 2 &&
              this.state.splitHand.length === 0 &&
              (rankValues[this.state.playerHand[0] % 13]) === (rankValues[this.state.playerHand[1] % 13]);

        let splitButton;
        if (canSplit) {
            splitButton = <button onClick={this.split.bind(this)}>Split</button>;
        }

        const splitPlayerCards = this.state.splitHand.map(function(card,i){
            return <td align="center" border="20px" key={i}> {rankStrings[card % 13]}{suitStrings[card % 4]} </td>;
        });

        let splitPlayerScore;
        let splitPlayerBet;
        const playSplitHand = this.state.splitHand.length > 0;
        if (this.state.splitHandScore > 21) {var splitHandStatus = " - Busted!";}
        if (playSplitHand) {
            splitPlayerScore = <td><i>Split Hand Score: {this.state.splitHandScore}<b>{splitHandStatus}</b>&nbsp;&nbsp;&nbsp;&nbsp;</i></td>;
            splitPlayerBet = <td><i>Bet: {parseInt(this.state.splitBet) + parseInt(this.state.splitDoubleDownBet)} wei&nbsp;&nbsp;&nbsp;&nbsp;</i></td>;
        }

        const canDoubleDown = ((this.state.playerHand.length === 2) || (this.state.splitHand.length === 2));
        let doubleDownButton;
        if (canDoubleDown && this.state.stage === "1") {
            doubleDownButton = <button onClick={this.doubleDown.bind(this)}>Double Down</button>;
        }

        let splitDoubleDownButton;
        if (canDoubleDown && this.state.stage === "2") {
            splitDoubleDownButton = <button onClick={this.doubleDown.bind(this)}>Double Down</button>;
        }

        let standButton;
        if (this.state.stage === "1") {
            standButton = <button onClick={this.stand.bind(this)}>Stand</button>;
        }

        let splitStandButton;
        if (this.state.stage === "2") {
            splitStandButton = <button onClick={this.stand.bind(this)}>Stand</button>;
        }

        let hitButton;
        if (this.state.stage === "1") {
            hitButton = <button onClick={this.hit.bind(this)}>Hit</button>;
        }

        let splitHitButton;
        if (this.state.stage === "2") {
            splitHitButton = <button onClick={this.hit.bind(this)}>Hit</button>;
        }

        if (!this.state.web3) {
            return <div>Loading Web3, accounts, and contract...</div>;
        }

        const dealerCards = this.state.dealerHand.map(function(card,i){
            return <td align="center" border="20px" key={i}> {rankStrings[card % 13]}{suitStrings[card % 4]} </td>;
        });

        const playerCards = this.state.playerHand.map(function(card,i){
            return <td align="center" border="20px" key={i}> {rankStrings[card % 13]}{suitStrings[card % 4]} </td>;
        });

        const playHand = this.state.playerHand.length > 0;
        if (this.state.handScore > 21) {var handStatus = " - Busted!";}
        if (this.state.dealerScore > 21) {var dealerStatus = " - Busted!";}
        let dealerScore;
        let playerScore;
        let playerBet;
        if (playHand) {
            dealerScore = <td><i>Dealer Score: {this.state.dealerScore}<b>{dealerStatus}</b></i></td>;
            playerScore = <td><i>Hand Score: {this.state.handScore}<b>{handStatus}</b>&nbsp;&nbsp;&nbsp;&nbsp;</i></td>;
            playerBet = <td><i>Bet: {parseInt(this.state.bet) + parseInt(this.state.doubleDownBet)} wei&nbsp;&nbsp;&nbsp;&nbsp;</i></td>;
        }

        return (
                <div className="App">
                <h1>Blackjack dApp</h1>

                <h3>Dealer:</h3>

                <table align="center" style={{'font-size': "24px"}}><tbody><tr>{dealerCards}</tr></tbody></table>
                <table align="center"><tbody><tr>{dealerScore}</tr></tbody></table>

                <br/><br/>

                <h3>Your Cards:</h3>

                <table align="center" style={{'font-size': "24px"}}><tbody><tr>{playerCards}</tr></tbody></table>
                <table align="center"><tbody><tr>{playerScore}{playerBet}</tr></tbody></table>

            {standButton}&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
            {hitButton}&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
            {doubleDownButton}&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
            {splitButton}

                <br/><br/>

                <table align="center" style={{'font-size': "24px"}}><tbody><tr>{splitPlayerCards}</tr></tbody></table>
                <table align="center"><tbody><tr>{splitPlayerScore}{splitPlayerBet}</tr></tbody></table>


            {splitStandButton}&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
            {splitHitButton}&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
            {splitDoubleDownButton}

                <br/><br/>

            Place your bet: <input value={this.state.betSize} onChange={this.onChange}/> wei &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
                <button onClick={this.newRound.bind(this)}>Deal</button>
                <br/>
                <div> Maximum bet: {this.state.maxBet} wei</div>
                <br/>
                <i>(connected account: {this.state.playerAccount})</i>

                <p/><hr style={{height: 2}}/>

                <p>Blackjack Pays 3:2 {String.fromCharCode(9827)} Dealer Stands on Soft 17 {String.fromCharCode(9829)} No Insurance {String.fromCharCode(9830)} Double After Split {String.fromCharCode(9824)} No Resplit</p>

            </div>
        );
    }
}

export default App;
