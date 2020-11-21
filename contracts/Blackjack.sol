// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

import "./provableAPI.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.2.0/contracts/access/Ownable.sol";
//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.2.0/contracts/math/SafeMath.sol";


/// @title A blackjack game
/// @author Clark Henry
/// @notice This contract has known security risks. It is a work-in-progress and should not be deployed in production
contract Blackjack is Ownable, usingProvable {

    using SafeMath for *;

    event StageChanged(uint256 gameId, uint64 round, Stage newStage);
    event NewRound(uint256 gameId, uint64 round, address player, uint256 bet);
    event CardDrawn(uint256 gameId, uint64 round, uint8 card, uint8 score, bool isDealer);
    event Result(uint256 gameId, uint64 round, uint256 payout, uint8 playerScore, uint8 dealerScore);
    event PlayerHand(uint256 gameId, uint256[] playerHand, uint256[] playerSplitHand);
    event LogNewWolframRandomDraw(string cards);
    event LogNewProvableQuery(string description);
    event Received(address, uint);

    enum Stage {
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

    /// @dev seed should not be based on timestamp. This is a security risk and placeholder for now
    constructor() public {
        seed = block.timestamp;
    }

    fallback() external {}

    receive() external payable
    {
        emit Received(msg.sender, msg.value);
    }

    function kill() public onlyOwner()
    {
	selfdestruct(address(uint160(owner())));
    }
    
    modifier atStage(Stage _stage)
    {
        require(
                games[msg.sender].stage == _stage,
                "Function cannot be called at this time."
                );
        _;
    }

    modifier eitherStage(Stage _stage1, Stage _stage2)
    {
        require(
                games[msg.sender].stage == _stage1 || games[msg.sender].stage == _stage2,
                "Function cannot be called at this time."
                );
        _;
    }

    /// @dev Could be used for more complex check-reveal scheme for payable functions?
    /// @param game The current game which requires stage update
    function nextStage(Game storage game)
	internal
    {
        game.stage = Stage(uint(game.stage) + 1);

        if(game.stage == Stage.PlaySplitHand && game.splitPlayer.hand.length == 0) {
            game.stage = Stage(uint(game.stage) + 1);
        }

        emit StageChanged(game.id, game.round, game.stage);
    }

    /// @dev Not sure this is optimized in terms of stage updates and call timing
    /// @param game The current game which requires stage reset
    function reset(Game storage game)
	internal
    {
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

    /// @notice Start a new round of Blackjack with the transferred value as the original bet.
    /// @dev seed should not be based on timestamp. This is a security risk and placeholder for now
    function newRound()
	public
	payable
    {
	uint256 _seed;
        uint64 _now = uint64(block.timestamp);
        uint256 id = uint256(keccak256(abi.encodePacked(block.number, _now, _seed)));

	seed += seed;
	

        Player memory dealer;
        Player memory player;
        Player memory splitPlayer;

        games[msg.sender] = Game(id, _now, 0, Stage.Bet, dealer, player, splitPlayer);
        Game storage game = games[msg.sender];

        reset(game);

        player.bet = msg.value;
        game.dealer.seed = ~_seed;
        game.player.seed = _seed;
        game.splitPlayer.seed = _seed;
        game.round++;

        emit NewRound(game.id, game.round, msg.sender, msg.value);

        nextStage(game);
        dealCards(game);
        emit PlayerHand(game.id, game.player.hand, game.splitPlayer.hand);
    }


    /// @notice Split first two cards into two hands, drawing one additional card for each. An equivalent bet value is required.
    /// @dev not working correctly on last check - the require for bet size was reverting
    function split()
	public
	payable
	atStage(Stage.PlayHand)
    {

        Game storage game = games[msg.sender];

        require(msg.value == game.player.bet, "Must match original bet to split");
        require(game.player.hand.length == 2, "Can only split with two cards");
        require(game.splitPlayer.hand.length == 0, "Can only split once");
        require(cardValues[game.player.hand[0] % 13] == cardValues[game.player.hand[1] % 13], "First two cards must be same");

        game.splitPlayer.hand.push(game.player.hand[1]);
        game.player.hand.pop();

        drawCard(game, game.player);
        drawCard(game, game.splitPlayer);
        emit PlayerHand(game.id, game.player.hand, game.splitPlayer.hand);

        game.player.score = recalculate(game.player);
        game.splitPlayer.score = recalculate(game.splitPlayer);

        game.splitPlayer.bet = msg.value;
    }

    /// @notice Double down on first two cards, taking one additional card and standing, with an opportunity to double original bet.
    /// @dev is this vulnerable to OOG leaking drawn card info?
    function doubleDown()
	public
	payable
	eitherStage(Stage.PlayHand, Stage.PlaySplitHand)
    {
        Game storage game = games[msg.sender];

        require((game.player.hand.length == 2 && game.stage == Stage.PlayHand) ||
                (game.splitPlayer.hand.length == 2 && game.stage == Stage.PlaySplitHand),
                "Can only double down with two cards");
        require(msg.value <= game.player.bet, "Bet cannot be greater than original bet");

        if (game.stage == Stage.PlayHand) {
            drawCard(game, game.player);
            SafeMath.add(game.player.bet, msg.value);
            game.player.score = recalculate(game.player);
	    game.player.doubleDown = true;

        } else if (game.stage == Stage.PlaySplitHand) {
            drawCard(game, game.splitPlayer);
            SafeMath.add(game.splitPlayer.bet, msg.value);
            game.splitPlayer.score = recalculate(game.splitPlayer);
	    game.splitPlayer.doubleDown = true;

        }

        nextStage(game);
    }

    /// @notice Hit, taking one additional card on the current hand.
    /// @dev is this vulnerable to OOG leaking drawn card info?
    function hit()
	public
	eitherStage(Stage.PlayHand, Stage.PlaySplitHand)
    {
        Game storage game = games[msg.sender];

        require(game.player.score < 21  && game.stage == Stage.PlayHand || (game.splitPlayer.score < 21 && game.stage == Stage.PlaySplitHand));

        if(game.stage == Stage.PlayHand) {

            drawCard(game, game.player);
            game.player.score = recalculate(game.player);

            if (game.player.score >= 21) {
                nextStage(game);

                if (game.splitPlayer.hand.length == 0){
                    concludeGame(game);
                }

            }

        } else {

            drawCard(game, game.splitPlayer);
            game.splitPlayer.score = recalculate(game.splitPlayer);

            if (game.splitPlayer.score >= 21) {
                concludeGame(game);
            }

        }

    }

    /// @notice Standing, taking no more additional cards and concluding the current hand.
    /// @dev is this vulnerable to gas limit leaking drawn card info?
    function stand()
	public 
	eitherStage(Stage.PlayHand, Stage.PlaySplitHand)
    {
        Game storage game = games[msg.sender];

        if((game.stage == Stage.PlayHand && game.splitPlayer.hand.length == 0) || game.stage == Stage.PlaySplitHand) {
            nextStage(game);
            concludeGame(game);
        } else {
        nextStage(game);
	}
    }

    /// @dev done only at start of hand
    /// @param game The current game which is starting
    function dealCards(Game storage game)
	private
	atStage(Stage.Bet)
    {
        drawCard(game, game.player);
        drawCard(game, game.dealer);
        drawCard(game, game.player);
    }

    /// @dev Need to implement card removal
    /// @dev seed should not be based on timestamp. This is a security risk and placeholder for now
    /// @param game The current game containing the player drawing a card
    /// @param player A player from a Blackjack game, holding a hand to draw card to
    function drawCard(Game storage game,
		      Player storage player)
	private
    {
        uint64 _now = uint64(block.timestamp);
        uint256 card = ((player.seed * seed) + _now) % (NUMBER_OF_DECKS*52);
        player.seed = uint256(keccak256(abi.encodePacked(player.seed, card, _now)));
        seed = uint256(keccak256(abi.encodePacked(seed, card, _now)));

        player.hand.push(card);
        player.score = recalculate(player);

        emit CardDrawn(game.id, game.round, uint8(card % 52), player.score, player.bet == 0);
    }

    /// @param player A player from a Blackjack game, holding a hand to calculate the score on
    /// @return score The Blackjack score for the player.
    function recalculate(Player storage player)
	private
	view
	returns (uint8 score)
    {
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

    /// @param game The game to conclude, paying out players if necessary
    function concludeGame(Game storage game)
	private
    {
        uint256 payout = SafeMath.add( calculatePayout(game, game.player) ,
				       calculatePayout(game, game.splitPlayer) );
        if (payout != 0) {
            msg.sender.transfer(payout);
        }
        emit Result(game.id, game.round, payout, game.player.score, game.dealer.score);
    }

    /// @dev TODO: Properly handle when dealer has Blackjack (i.e., refund doubles and splits?)
    /// @param game The concluded Blackjack game
    /// @param player A player from the game to calculate the payout for
    /// @return payout Amount of ether to transfer to player for winnings
    function calculatePayout(Game storage game,
			     Player storage player)
	private
	returns (uint256 payout)
    {
        Player memory dealer = game.dealer;
        // Player busted
        if (player.score > 21) {
            payout = 0;
        } else {
            bool dealerHasBJ = drawDealerCards(game);

            // Player has BlackJack but dealer does not.
            if (player.score == 21 && player.hand.length == 2 && !dealerHasBJ) {
                // Pays 3 to 2
                payout = SafeMath.div(SafeMath.mul(player.bet, 5), 2);
            } else if (player.score > dealer.score || dealer.score >= 21) {
                payout = SafeMath.mul(player.bet, 2);
            } else if (player.score == dealer.score) {
                payout = player.bet;
            } else {
                payout = 0;
            }
        }
    }

    /// @dev TODO: Change dealer rules from S17 to H17
    /// @dev TODO: Properly handle when dealer has Blackjack (i.e., refund doubles and splits?)
    /// @param game The concluded Blackjack game
    /// @return bool Whether the dealer has Blackjack
    function drawDealerCards(Game storage game)
	private
	returns (bool)
    {
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


    /// Getters
    /// @notice Returns the dealer's opened hand
    /// @return hand The dealer's hand
    function getDealerHand()
        public
        view
        returns (uint256[] memory hand)
    {
        Game storage game = games[msg.sender];
        hand = game.dealer.hand;
    }

    /// @notice Returns all player's hands
    /// @return hand The player's primary hand
    /// @return splitHand The player's split hand, if any
    function getPlayerHand()
        public
        view
        returns (uint256[] memory hand,
		 uint256[] memory splitHand)
    {
        Game storage game = games[msg.sender];
        hand = game.player.hand;
        splitHand = game.splitPlayer.hand;
    }

    /// @notice Returns selected elements from a game
    /// @dev Also add bet (and original) to return
    /// @return gameId ID for the current Blackjack game
    /// @return startTime Time the current Blackjack game began
    /// @return round Number of round of Blackjack game played
    /// @return stage Stage of the Blackjack game
    function getGameState()
        public
        view
        returns (uint256 gameId,
		 uint64 startTime,
		 uint64 round,
		 Stage stage)
    {
        Game storage game = games[msg.sender];
        gameId = game.id;
        startTime = game.startTime;
        round = game.round;
        stage = game.stage;
    }
}
