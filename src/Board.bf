using System;
using System.Collections;
using System.Diagnostics;
using Dimtoo;
using Pile;

namespace NecroCard
{
	static
	{
		public static Random rand = new Random() ~ delete _;
	}

	class Board
	{
		static int lastCard;
		static List<Card> allCards = new List<Card>() ~ DeleteContainerAndItems!(_);
		static this()
		{
			mixin Register(Card card)
			{
				allCards.Add(card);
			}

			Register!(new Card("Thork", 1, 5, 0));
			Register!(new Card("Bacat", 3, 2, 1));
			Register!(new Card("Quak", 5, 1, 2));
		}

		const Rect endscreenRestart = .(132, 84, 56, 14);
		const Rect endscreenMenu = .(132, 101, 56, 14);
		const Point2 endscreenText = .(132, 76);
		const float GameEndDelay = 0.2f;

		public CardLayout playerLayout = new CardLayout(this, -4, true) ~ delete _;
		public CardLayout enemyLayout = new CardLayout(this, -(int)CardLayout.Size.Y - 8, false) ~ delete _;

		public Stats playerStats = new Stats(this, playerLayout, true) ~ delete _;
		public Stats enemyStats = new Stats(this, enemyLayout, false) ~ delete _;

		public Enemy enemy = new Enemy(enemyStats, enemyLayout) ~ delete _;

		String resultString;
		float gameEndDelayCounter;
		bool gameEnds;
		bool playerWon;
		bool prevPlayerTurn;
		public bool playerTurn = rand.Next(0, 2) == 1;

		int playerEmptyLayoutTurns;
		int enemyEmptyLayoutTurns;

		bool endscreenRestartHover;
		bool endscreenMenuHover;

		public this()
		{
			// Hand out cards
			for (int i < 4)
			{
				playerStats.DrawCard(true);
				enemyStats.DrawCard(true);
			}
		}

		public void Render(Batch2D batch)
		{
			Draw.background.Asset.Draw(batch, 0, .Zero);
			if (playerTurn)
				Draw.turn.Asset.Draw(batch, 0, .(20, 165));
			else
				Draw.turn.Asset.Draw(batch, 0, .(264, 165));

			// Draw cards button
			int frame = (playerStats.CanDrawCard() && !playerStats.buttonDown && playerTurn) ? 0 : 1;
			Draw.drawButton.Asset.Draw(batch, frame, .(27, 133));

			// Render health
			DrawNum(batch, playerStats.health, .(30, 171));
			DrawNum(batch, enemyStats.health, .(274, 171));

			enemyLayout.Render(batch);
			playerLayout.Render(batch);

			enemyLayout.RenderTop(batch);
			playerLayout.RenderTop(batch);

			playerStats.Render(batch);

			if (GameState == .GameEnd)
			{
				Draw.endscreen.Asset.Draw(batch, playerWon ? 1 : 0, .Zero);
				Draw.restartButton.Asset.Draw(batch, endscreenRestartHover ? 1 : 0, endscreenRestart.Position);
				Draw.menuButton.Asset.Draw(batch, endscreenMenuHover ? 1 : 0, endscreenMenu.Position);
			}
		}

		// hi res overlay
		public void RenderHiRes(Batch2D batch)
		{
			if (GameState == .Playing)
			{
				enemyLayout.RenderHiRes(batch);
				playerLayout.RenderHiRes(batch);

				enemyLayout.RenderTopHiRes(batch);
				playerLayout.RenderTopHiRes(batch);

				playerStats.RenderHiRes(batch);
			}
			else if(GameState == .GameEnd)
			{
				let baseScale = Vector2(((float)NecroCard.Instance.FrameScale / Draw.font.Size));

				if (resultString != null) batch.Text(Draw.font, resultString, NecroCard.Instance.FrameToWindow(endscreenText), baseScale * 6, .Zero, 0, .DarkText);
			}
		}

		void DrawNum(Batch2D batch, int num, Point2 position)
		{
			Draw.bigNumbers.Asset.Draw(batch, Math.Clamp((int)Math.Floor((float)num / 10), 0, 9), position);
			Draw.bigNumbers.Asset.Draw(batch, Math.Clamp(num % 10, 0, 9), position + .(9, 0));
		}

		public void Update()
		{
			if (GameState == .Playing && !gameEnds)
			{
				prevPlayerTurn = playerTurn;

				playerLayout.Update();
				enemyLayout.Update();

				// These are player controlled
				playerStats.Update();
				if (playerTurn)
				{
					playerLayout.RunPlayerControls();
					playerStats.RunPlayerControls();
				}
				else
				{
					enemy.MakeMove();
				}

				// Test for winning/loosing conditions on turn change
				if (prevPlayerTurn != playerTurn)
				{
					// Player had empty layout at end of turn

					if (prevPlayerTurn)
					{
						if (playerLayout.count == 0)
							playerEmptyLayoutTurns++;
						else playerEmptyLayoutTurns = 0;
					}

					if (playerEmptyLayoutTurns > 1)
					{
						gameEnds = true;
						resultString = "No cards to defend YOU";

						if (enemyLayout.count == 0)
							resultString = "No cards to left, both loose";
					}

					if (!prevPlayerTurn)
					{
						if (enemyLayout.count == 0)
							enemyEmptyLayoutTurns++;
						else enemyEmptyLayoutTurns = 0;
					}

					if (enemyEmptyLayoutTurns > 1)
					{
						playerWon = true;
						gameEnds = true;
						resultString = "No cards to defend COM";
					}

					if (prevPlayerTurn && playerStats.health <= 0)
					{
						gameEnds = true;
						resultString = "YOU ran out of energy";
					}
					else if (!prevPlayerTurn && enemyStats.health <= 0)
					{
						gameEnds = true;
						playerWon = true;
						resultString = "COM ran out of energy";
					}

					if (gameEnds)
					{
						Log.Debug($"Game Ends. PlayerWins {playerWon}");
						gameEndDelayCounter = GameEndDelay;
					}
				}
			}
			else if (GameState == .GameEnd)
			{
				endscreenRestartHover = endscreenRestart.Contains(PixelMouse);
				endscreenMenuHover = endscreenMenu.Contains(PixelMouse);

				if (Core.Input.Mouse.Pressed(.Left))
				{
					if (endscreenRestartHover)
						NecroCard.Instance.RestartBoard();
					else if (endscreenMenuHover)
						NecroCard.Instance.LoadMenu();
				}
			}
			else
			{
				// Game end delay
				if (gameEnds)
					gameEndDelayCounter -= Time.Delta;

				if (gameEnds && gameEndDelayCounter <= 0)
				{
					GameState = .GameEnd;
				}
			}
		}

		public Card DrawCard()
		{
			// Nobody wants the same card twice!
			var newCard = rand.Next(0, allCards.Count);
			while (newCard == lastCard)
				newCard = rand.Next(0, allCards.Count);

			lastCard = newCard;
			return allCards[newCard];
		}
	}
}
