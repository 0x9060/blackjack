import React, { Component } from "react";
import BlackjackContract from "./contracts/Blackjack.json";
import getWeb3 from "./getWeb3";

import "./App.css";

class App extends Component {

    //state = { web3: null, accounts: null, game: null , dealerHand: [], playerHand: [] };

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

            // Use web3 to get the user's accounts.
            const accounts = await web3.eth.getAccounts();

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
            this.setState({ web3, playerAccount, game: gameInstance });

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

        await game.methods.newRound().send({ from: playerAccount, value: this.state.betSize });

        const responseDealer = await game.methods.getDealerState().call();
        const responsePlayer = await game.methods.getPlayerState().call();

	console.log(responseDealer.score, responsePlayer.handScore);
        this.setState({ dealerHand: responseDealer.hand, playerHand: responsePlayer.hand, splitHand: responsePlayer.splitHand });
    };

    split = async () => {
        const { playerAccount , game } = this.state;

        await game.methods.split().send({ from: playerAccount, value: this.state.betSize });

        const responsePlayer = await game.methods.getPlayerState().call();

	console.log(responsePlayer.hand);
	console.log(responsePlayer.splitHand);
	
        this.setState({ playerHand: responsePlayer.hand, splitHand: responsePlayer.splitHand });
    };

    doubleDown = async () => {
        const { playerAccount , game } = this.state;

        await game.methods.doubleDown().send({ from: playerAccount, value: this.state.betSize });

        const responseDealer = await game.methods.getDealerState().call();
        const responsePlayer = await game.methods.getPlayerState().call();

        this.setState({ dealerHand: responseDealer.hand, playerHand: responsePlayer.hand, splitHand: responsePlayer.splitHand });
    };

    hit = async () => {
        const { playerAccount , game } = this.state;

        await game.methods.hit().send({ from: playerAccount });

        const responsePlayer = await game.methods.getPlayerState().call();

        this.setState({ playerHand: responsePlayer.hand, splitHand: responsePlayer.splitHand });
    };

    stand = async () => {
        const { playerAccount , game } = this.state;

        await game.methods.stand().send({ from: playerAccount });

        const responseDealer = await game.methods.getDealerState().call();
        const responsePlayer = await game.methods.getPlayerState().call();

	console.log(responseDealer);
	console.log(responsePlayer);

        this.setState({ dealerHand: responseDealer.hand });
    };

    render() {
	const rankStrings = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "T", "J", "Q", "K"]
	const rankValues = [11, 2, 3, 4, 5, 6, 7, 8, 9, 10, 10, 10, 10]
	const suitStrings = [String.fromCharCode(9827), String.fromCharCode(9830), String.fromCharCode(9829), String.fromCharCode(9824)]

        const canSplit = this.state.playerHand.length === 2 && (rankValues[this.state.playerHand[0] % 13]) === (rankValues[this.state.playerHand[1] % 13]);
	const hasSplit = this.state.splitHand.length > 0;

        let splitButton;
        if (canSplit) {
            splitButton = <button onClick={this.split.bind(this)}>Split</button>;
        }
	
        const playerSplitCards = this.state.splitHand.map(function(card,i){
            return <td align="center" border="20px" key={i}> {rankStrings[card % 13]}{suitStrings[card % 4]} </td>;
        });

	let splitHand;
	if (hasSplit) {
	    splitHand = <div><table align="center"><tbody><tr>{playerSplitCards}</tr></tbody></table></div>;
	}
	
        const canDoubleDown = this.state.playerHand.length === 2;
        let doubleDownButton;

        if (canDoubleDown) {
            doubleDownButton = <button onClick={this.doubleDown.bind(this)}>Double Down</button>;
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

        return (
                <div className="App">
                <h1>Blackjack dApp</h1>
                <br/><br/>
                <div>Dealer Cards: <table align="center"><tbody><tr>{dealerCards}</tr></tbody></table></div>
                <br/><br/>
                <div>Your Cards:
		<table align="center"><tbody><tr>{playerCards}</tr></tbody></table>
		<br/><br/>
	    
	        {splitHand}
	        </div>
                <br/>

                <button onClick={this.stand.bind(this)}>Stand</button>
                &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

		<button onClick={this.hit.bind(this)}>Hit</button>
		&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

	        {doubleDownButton}
		&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

	        {splitButton}

                <br/><br/><br/><br/>

	        Place your bet: <input value={this.state.betSize} onChange={this.onChange}/> wei
                &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
                <button onClick={this.newRound.bind(this)}>Deal</button>
                <br/>
                <br/>
		<i>(connected account: {this.state.playerAccount})</i>
                <p/>
		
                <br/>
                <hr style={{height: 2}}/>
                <br/>

                <p>No Insurance - Blackjack Pays 3:2 - Double After Split - No Resplit</p>

            </div>
        );
    }
}

export default App;
