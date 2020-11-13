import React, { Component } from "react";
import BlackjackContract from "./contracts/Blackjack.json";
import getWeb3 from "./getWeb3";

import "./App.css";

class App extends Component {

    //state = { web3: null, accounts: null, game: null , dealerHand: [], playerHand: [] };

    constructor(){
        super();
        //this.state = {value: ''};
        this.state = { betSize: '', web3: null, accounts: null, game: null , dealerHand: [], playerHand: [] };
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

            // Get the contract instance.
            const networkId = await web3.eth.net.getId();
            const gameNetwork = BlackjackContract.networks[networkId];
            const gameInstance = new web3.eth.Contract(
                BlackjackContract.abi,
                gameNetwork && gameNetwork.address,
            );
            // Set web3, accounts, and contract to the state, and then proceed with an
            // example of interacting with the contract's methods.
            this.setState({ web3, accounts, game: gameInstance });

        } catch (error) {
            // Catch any errors for any of the above operations.
            alert(
                `Failed to load web3, accounts, or contract. Check console for details.`,
            );
            console.error(error);
        }
    };

    newRound = async () => {
        const { accounts, game } = this.state;

        await game.methods.initGame(0).send({ from: accounts[0] })
        await game.methods.newRound(0).send({ from: accounts[0] });

        const responseDealer = await game.methods.getDealerHand().call();
        const responsePlayer = await game.methods.getPlayerHand().call();

        //await game.methods.wolframDraw().call();

        this.setState({ dealerHand: responseDealer, playerHand: responsePlayer });
    };

    hit = async () => {
        const { accounts, game } = this.state;

        await game.methods.hit(0).send({ from: accounts[0] });

        const responsePlayer = await game.methods.getPlayerHand().call();

        this.setState({ playerHand: responsePlayer });
    };

    stand = async () => {
        const { accounts, game } = this.state;

        await game.methods.stand(0).send({ from: accounts[0] });

        const responseDealer = await game.methods.getDealerHand().call();

        this.setState({ dealerHand: responseDealer });
    };

    render() {
        const canSplit = this.state.playerHand.length == 2 && (this.state.playerHand[0] % 13) == (this.state.playerHand[1] % 13);
        let splitButton;

        if (canSplit) {
            splitButton = <button onClick={this.hit.bind(this)}>Split</button>;
        }

        const canDoubleDown = this.state.playerHand.length == 2;
        let doubleDownButton;

        if (canDoubleDown) {
            doubleDownButton = <button onClick={this.hit.bind(this)}>Double Down</button>;
        }

        if (!this.state.web3) {
            return <div>Loading Web3, accounts, and contract...</div>;
        }

        const dealerCards = this.state.dealerHand.map(function(card,i){
            return <td align="center" key={i}> {card} </td>;
        });

        const playerCards = this.state.playerHand.map(function(card,i){
            return <td align="center" key={i}> {card % 13} </td>;
        });

        return (
                <div className="App">
                <h1>Blackjack Smart Contract dApp</h1>
                <br/><br/>
                <div>Dealer Cards: <table align="center">{dealerCards}</table></div>
                <br/><br/>
                <div>Your Cards: <table align="center">{playerCards}</table></div>
                <br/><br/><br/>

                <input value={this.state.betSize} onChange={this.onChange}/>
		<button onClick={this.newRound.bind(this)}>Deal</button>
                <br/>
                <p/>
                <button onClick={this.stand.bind(this)}>Stand</button>
                <button onClick={this.hit.bind(this)}>Hit</button>
                {doubleDownButton}
            {splitButton}
                <br/>
                <br/>
                <br/>
                <hr style={{height: 2}}/>
                <br/>

                <p>No Insurance - Blackjack Pays 3:2 - Double After Split - No Resplit</p>

            </div>
        );
    }
}

export default App;
