// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.4;

contract Blackjack {
    //using SafeMath for uint256;

    event StageChanged(uint256 gameId, uint64 round, Stage newStage);
    event NewRound(uint256 gameId, uint64 round, address player, uint256 bet);
    event CardDrawn(uint256 gameId, uint64 round, uint8 card, uint8 score, bool isDealer);
    event Result(uint256 gameId, uint64 round, uint256 payout, uint8 playerScore, uint8 dealerScore);
    event PlayerHand(uint256 gameId, uint256[] playerHand);

    enum Stage {
                SitDown,
                Bet,
                Play
    }

    struct Game {
        uint256 id;
        uint64 startTime;
        uint64 round;
        Stage stage;
        Player dealer;
        Player player;
    }

    struct Player {
        uint256 bet;
        uint256 seed;
        uint256[] hand;
        uint8 score;
    }

    uint256 constant NUMBER_OF_DECKS = 8;

    uint8[13] cardValues = [11, 2, 3, 4, 5, 6, 7, 8, 9, 10, 10, 10, 10];

    mapping(address => Game) games;

    uint256 seed;

    constructor() {
	// fix this, get off timestamp for seed
        seed = block.timestamp;
    }

    function getPlayerHand() public view returns (uint256[] memory hand) {
        Game storage game = games[msg.sender];
	hand = game.player.hand;
    }

    function getGameState() public view returns (uint256 gameId, uint64 startTime, uint64 round, Stage stage) {
        Game storage game = games[msg.sender];
        gameId = game.id;
        startTime = game.startTime;
        round = game.round;
        stage = game.stage;
    }

    modifier atStage(Stage _stage) {
        require(
                games[msg.sender].stage == _stage,
                "Function cannot be called at this time."
                );
        _;
    }

    function nextStage(Game storage game) internal {
        game.stage = Stage(uint(game.stage) + 1);
        emit StageChanged(game.id, game.round, game.stage);
    }

    function reset(Game storage game) internal {
        game.stage = Stage.Bet;
        emit StageChanged(game.id, game.round, game.stage);
        game.player.bet = 0;
        game.player.score = 0;
        game.dealer.score = 0;
        delete game.player.hand;
        delete game.dealer.hand;
    }

    //function initGame(uint256 _seed) public atStage(Stage.SitDown) {
    function initGame(uint256 _seed) public {
        uint64 _now = uint64(block.timestamp);
        uint256 id = uint256(keccak256(abi.encodePacked(block.number, _now, _seed)));

        seed += _seed;

        Player memory player;
        Player memory dealer;
        games[msg.sender] = Game(id, _now, 0, Stage.SitDown, dealer, player);

        nextStage(games[msg.sender]);
    }

    function newRound(uint256 _seed) public payable atStage(Stage.Bet) {
        Game storage game = games[msg.sender];

        seed += _seed;
        game.dealer.seed = _seed;
        game.player.seed = _seed;
        game.round++;

        emit NewRound(game.id, game.round, msg.sender, msg.value);

        nextStage(game);
        dealCards(game);
        emit PlayerHand(game.id, game.player.hand);
    }

    function addBet() payable public {
        Player memory player = games[msg.sender].player;
        //player.bet = player.bet.add(msg.value);
        player.bet = player.bet + msg.value;
    }

    function hit(uint256 _seed) public atStage(Stage.Play) {
        Game storage game = games[msg.sender];
        if (game.player.score > 21) {
            revert();
        }

        seed += _seed;

        drawCard(game, game.player);
        game.player.score = recalculate(game.player);

        if (game.player.score >= 21) {
            concludeGame(game);
        }
    }

    function stand(uint256 _seed) public atStage(Stage.Play) {
        Game storage game = games[msg.sender];
        seed += _seed;
        concludeGame(game);
    }

    function dealCards(Game storage game) private {
        drawCard(game, game.player);
        drawCard(game, game.dealer);
        drawCard(game, game.player);
    }

    /* TODO: Check for card repeatation */
    function drawCard(Game storage game, Player storage player) private returns (uint256) {
	// fix this, get off timestamp for seed
        uint64 _now = uint64(block.timestamp);

        // Drawing card by generating a random index in a set of 8 deck
        //uint256 card = ((player.seed * seed).add(_now)) % (NUMBER_OF_DECKS*52);
        uint256 card = ((player.seed * seed) + _now) % (NUMBER_OF_DECKS*52);

        // Modify seeds
        player.seed = uint256(keccak256(abi.encodePacked(player.seed, card, _now)));
        seed = uint256(keccak256(abi.encodePacked(seed, card, _now)));

        // Push the card index to player hand
        player.hand.push(card);

        // Recalculate player score
        card = card % 52 % 13;
        if (card == 0) {
            player.score = recalculate(player);
        } else if (card > 10) {
            player.score += cardValues[card];
        }

        emit CardDrawn(game.id, game.round, uint8(card % 52), player.score, player.bet == 0);

        return card;
    }

    function recalculate(Player storage player) private view returns (uint8 score) {
        uint8 numberOfAces = 0;
        for (uint8 i = 0; i < player.hand.length; i++) {
            uint8 card = (uint8) (player.hand[i] % 52 % 13);
            score += cardValues[card];
            if (card == 0) numberOfAces++;
        }
        while (numberOfAces > 0 && score > 21) {
            score -= 10;
            numberOfAces--;
        }
    }

    function concludeGame(Game storage game) private {
        uint256 payout = calculatePayout(game);
        if (payout != 0) {
            msg.sender.transfer(payout);
        }
        emit Result(game.id, game.round, payout, game.player.score, game.dealer.score);

        reset(game);
    }

    function calculatePayout(Game storage game) private returns (uint256 payout) {
        Player memory player = game.player;
        Player memory dealer = game.dealer;
        // Player busted
        if (player.score > 21) {
            payout = 0;
        } else {
            bool dealerHasBJ = drawDealerCards(game);

            // Player has BlackJack but dealer does not.
            if (player.score == 21 && player.hand.length == 2 && !dealerHasBJ) {
                // Pays 2 to 1
                payout = player.bet * 3;
            } else if (player.score > dealer.score || dealer.score > 21) {
                payout = player.bet * 2;
            } else if (player.score == dealer.score) {
                payout = player.bet;
            } else {
                payout = 0;
            }
        }
    }

    function drawDealerCards(Game storage game) private returns (bool) {
        // Draw dealer's next card to check for BlackJack
        drawCard(game, game.dealer);
        if (game.dealer.score == 21) {
            return true;
        }

        // Dealer must draw to 16 and stand on all 17's
        while (game.dealer.score < 17) {
            drawCard(game, game.dealer);
        }

        return false;
    }
}
