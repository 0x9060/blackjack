// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

import "./provableAPI_0.6.sol";

contract NewBlackjack is usingProvable {
    //using SafeMath for uint256;

    event StageChanged(uint256 gameId, uint64 round, Stage newStage);
    event NewRound(uint256 gameId, uint64 round, address player, uint256 bet);
    event CardDrawn(uint256 gameId, uint64 round, uint8 card, uint8 score, bool isDealer);
    event Result(uint256 gameId, uint64 round, uint256 payout, uint8 playerScore, uint8 dealerScore);
    event PlayerHand(uint256 gameId, uint256[] playerHand, uint256[] playerSplitHand);
    event LogNewWolframRandomDraw(string cards);
    event LogNewProvableQuery(string description);

    enum Stage {
                SitDown,
                Bet,
                PlayHand,
                PlaySplitHand,
		ConcludeHands
    }

    struct Game {
        uint256 id;
        uint64 startTime;
        uint64 round;
        Stage stage;
        Player dealer;
        Player player;
        Player splitPlayer;
    }

    struct Player {
        uint256 bet;
        uint256 seed;
        uint8 score;
        bool doubleDown;
        uint256[] hand;
    }

    uint256 constant NUMBER_OF_DECKS = 1;

    uint8[52] cardValues = [11, 2, 3, 4, 5, 6, 7, 8, 9, 10, 10, 10, 10];

    mapping(string => uint8) burnt; // dealt cards

    mapping(address => Game) games;

    string private randomCards;

    uint256 seed;

    constructor() public {
        // fix this, get off timestamp for seed
        seed = block.timestamp;
    }

    fallback() external payable {}

    receive() external payable {}

    modifier atStage(Stage _stage) {
        require(
                games[msg.sender].stage == _stage,
                "Function cannot be called at this time."
                );
        _;
    }

    modifier eitherStage(Stage _stage1, Stage _stage2) {
        require(
                games[msg.sender].stage == _stage1 || games[msg.sender].stage == _stage2,
                "Function cannot be called at this time."
                );
        _;
    }

    function nextStage(Game storage game) internal {
        game.stage = Stage(uint(game.stage) + 1);

	if(game.stage == Stage.PlaySplitHand && game.splitPlayer.hand.length == 0) {
	    game.stage = Stage(uint(game.stage) + 1);
	}
	
        emit StageChanged(game.id, game.round, game.stage);
    }

    function reset(Game storage game) internal {
        game.stage = Stage.Bet;
        emit StageChanged(game.id, game.round, game.stage);

        game.player.bet = 0;

        game.player.score = 0;
        delete game.player.hand;

        game.splitPlayer.score = 0;
        delete game.splitPlayer.hand;

        game.dealer.score = 0;
        delete game.dealer.hand;
    }

    function newRound(uint256 _seed) public payable atStage(Stage.Bet) {
        uint64 _now = uint64(block.timestamp);
        uint256 id = uint256(keccak256(abi.encodePacked(block.number, _now, _seed)));

        seed += _seed;

        Player memory dealer;

        Player memory player;
        player.bet = msg.value;

        Player memory splitPlayer; // placeholder

        games[msg.sender] = Game(id, _now, 0, Stage.SitDown, dealer, player, splitPlayer);

        Game storage game = games[msg.sender];

        game.dealer.seed = _seed;
        game.player.seed = _seed;
        game.splitPlayer.seed = _seed;
        game.round++;

        emit NewRound(game.id, game.round, msg.sender, msg.value);

        nextStage(game);
        dealCards(game);
        emit PlayerHand(game.id, game.player.hand, game.splitPlayer.hand);
    }

    function addBet() payable public {
        Player memory player = games[msg.sender].player;
        //player.bet = player.bet.add(msg.value);
        player.bet = player.bet + msg.value;
    }

    function split() public payable atStage(Stage.PlayHand) {

        Game storage game = games[msg.sender];

        require(msg.value == game.player.bet, "Must match original bet to split");
        require(game.player.hand.length == 2, "Can only split with two cards");
        require(game.splitPlayer.hand.length == 0, "Can only split once");
        require((game.player.hand[0] % 13) == (game.player.hand[1] % 13), "First two cards must be same");

        game.splitPlayer.hand.push(game.player.hand[1]);
	delete game.player.hand[1];

        drawCard(game, game.player);
        drawCard(game, game.splitPlayer);
        emit PlayerHand(game.id, game.player.hand, game.splitPlayer.hand);

        game.player.score = recalculate(game.player);
        game.splitPlayer.score = recalculate(game.splitPlayer);

        game.splitPlayer.bet = msg.value;
    }

    function doubleDown() public payable eitherStage(Stage.PlayHand, Stage.PlaySplitHand) {
        Game storage game = games[msg.sender];

	require((game.player.hand.length == 2 && game.stage == Stage.PlayHand) ||
		(game.splitPlayer.hand.length == 2 && game.stage == Stage.PlaySplitHand),
		"Can only double down with two cards");
        require(msg.value <= game.player.bet, "Bet cannot be greater than original bet");

	if (game.stage == Stage.PlayHand) {
	    drawCard(game, game.player);
	    game.player.bet += msg.value;
	    game.player.score = recalculate(game.player);
	    
	} else if (game.stage == Stage.PlaySplitHand) {
	    drawCard(game, game.splitPlayer);
	    game.splitPlayer.bet += msg.value;
	    game.splitPlayer.score = recalculate(game.splitPlayer);

	}

	nextStage(game);
    }

    
    function hit(uint256 _seed) public eitherStage(Stage.PlayHand, Stage.PlaySplitHand) {
        Game storage game = games[msg.sender];

        require(game.player.score < 21  && game.stage == Stage.PlayHand || (game.splitPlayer.score < 21 && game.stage == Stage.PlaySplitHand));

        seed += _seed;

	if(game.stage == Stage.PlayHand) {
	    
	    drawCard(game, game.player);
	    game.player.score = recalculate(game.player);

	    if (game.player.score >= 21) {
		nextStage(game);

		if (game.splitPlayer.hand.length == 0){
		    nextStage(game);
		    concludeGame(game);
		}
		
	    }
	    
	} else {

	    drawCard(game, game.splitPlayer);
	    game.splitPlayer.score = recalculate(game.splitPlayer);

	    if (game.splitPlayer.score >= 21) {
		nextStage(game);
		concludeGame(game);
	    }
	    
	}
	
    }

    function stand(uint256 _seed) public eitherStage(Stage.PlayHand, Stage.PlaySplitHand) {
        Game storage game = games[msg.sender];
        seed += _seed;


	if(game.stage == Stage.PlayHand && game.splitPlayer.hand.length == 0 || game.stage == Stage.PlaySplitHand) {
	    nextStage(game);
	    concludeGame(game);
	}

	nextStage(game);
    }

    function dealCards(Game storage game) private { // better called startGame?
        drawCard(game, game.player);
        drawCard(game, game.dealer);
        drawCard(game, game.player);
    }

    /* TODO: Check for card repeatation */
    function drawCard(Game storage game, Player storage player) private {
        // fix this, get off timestamp for seed
        uint64 _now = uint64(block.timestamp);

        //uint256 card = ((player.seed * seed).add(_now)) % (NUMBER_OF_DECKS*52);
        uint256 card = ((player.seed * seed) + _now) % (NUMBER_OF_DECKS*52);

        // Modify seeds
        player.seed = uint256(keccak256(abi.encodePacked(player.seed, card, _now)));
        seed = uint256(keccak256(abi.encodePacked(seed, card, _now)));

        player.hand.push(card);
        player.score = recalculate(player);

        emit CardDrawn(game.id, game.round, uint8(card % 52), player.score, player.bet == 0);
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
        uint256 payout = calculatePayout(game, game.player) + calculatePayout(game, game.splitPlayer);
        if (payout != 0) {
            msg.sender.transfer(payout);
        }
        emit Result(game.id, game.round, payout, game.player.score, game.dealer.score);

        reset(game);
    }

    function calculatePayout(Game storage game, Player storage player) private returns (uint256 payout) {
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


    /// Getters:

    function getDealerHand()
        public
        view
        returns (uint256[] memory hand)
    {
        Game storage game = games[msg.sender];
        hand = game.dealer.hand;
    }

    function getPlayerHand()
        public
        view
        returns (uint256[] memory hand,uint256[] memory splitHand)
    {
        Game storage game = games[msg.sender];
        hand = game.player.hand;
        splitHand = game.splitPlayer.hand;
    }

    function getGameState()
        public
        view
        returns (uint256 gameId, uint64 startTime, uint64 round, Stage stage)
    {
        Game storage game = games[msg.sender];
        gameId = game.id;
        startTime = game.startTime;
        round = game.round;
        stage = game.stage;
    }
}
