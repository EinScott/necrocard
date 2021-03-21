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

	public enum ParticleType
	{
		case Attack = 0;
		case Sacrifice = 1;
		case Block = 2;
	}

	public struct Particle
	{
		public readonly ParticleType Type;
		public Point2 position;
		public Vector2 scale = .One;
		public float lifetime = 0;

		public this(ParticleType type, Point2 pos)
		{
			Type = type;
			position = pos;
		}
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

			Register!(new Card("Thork", 7, 1, 0));
			Register!(new Card("Bacat", 4, 4, 1));
			Register!(new Card("Quak", 5, 2, 2));
			Register!(new Card("Elok", 6, 3, 3));
			Register!(new Card("Bleh", 3, 2, 4));
			Register!(new Card("Snek", 5, 4, 6)); // index 5 is "none"
		}

		const Rect endscreenRestart = .(132, 84, 56, 14);
		const Rect endscreenMenu = .(132, 101, 56, 14);
		const Point2 endscreenText = .(133, 76);
		const int endscreenBoxWidth = 53;
		const float GameEndDelay = 0.2f;
		const int EmptyDamage = 2;

		const Point2 hardAIIndicatorPosition = .(297, 150);

		public CardLayout playerLayout = new CardLayout(this, -4, true) ~ delete _;
		public CardLayout enemyLayout = new CardLayout(this, -(int)CardLayout.Size.Y - 8, false) ~ delete _;

		public Stats playerStats = new Stats(this, playerLayout, true) ~ delete _;
		public Stats enemyStats = new Stats(this, enemyLayout, false) ~ delete _;

		public Enemy enemy ~ delete _;

		public List<Particle> particles = new List<Particle>() ~ delete _;

		String resultString;
		float gameEndDelayCounter;
		bool gameEnds;
		bool playerWon;
		bool prevPlayerTurn;
		int turn = 0;
		public bool playerTurn = rand.Next(0, 2) == 1;

		bool endscreenRestartHover;
		bool endscreenMenuHover;

		public this(bool first = false)
		{
			SoundSource.Play(Sound.cardShuffle);

			// Hand out cards
			for (int i < 4)
			{
				playerStats.DrawCard(true);
			}

			for (int i < 4)
			{
				enemyStats.DrawCard(true);
			}

			enemy = new Enemy(enemyStats, enemyLayout, first);
		}

		public void Render(Batch2D batch)
		{
			Draw.background.Asset.Draw(batch, 0, .Zero);

			// Empty board warning
			if (turn > 1) // Both have already played
			{
				if (playerLayout.count == 0)
					Draw.warning.Asset.Draw(batch, 0, .(46, 109));

				if (enemyLayout.count == 0)
					Draw.warning.Asset.Draw(batch, 1, .(46, 8));
			}

			// Turn indicator
			if (playerTurn)
				Draw.turn.Asset.Draw(batch, 0, .(20, 165));
			else
				Draw.turn.Asset.Draw(batch, 0, .(264, 165));

			// Hard ai indicator
			if (enemy.hard)
				Draw.hardAIIndicator.Asset.Draw(batch, 0, hardAIIndicatorPosition);

			// Draw cards button
			int frame = (playerStats.CanDrawCard() && !playerStats.buttonDown && playerTurn) ? 0 : 1;
			Draw.drawButton.Asset.Draw(batch, frame, .(27, 133));

			// Render health
			DrawNum(batch, playerStats.health, .(30, 171));
			DrawNum(batch, enemyStats.health, .(274, 171));

			enemyLayout.Render(batch);
			playerLayout.Render(batch);

			// Particles
			for (let part in ref particles)
				Draw.particles.Asset.Draw(batch, part.Type.Underlying, part.position, part.scale);

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
			/*if (GameState == .Playing)
			{
				enemyLayout.RenderHiRes(batch);
				playerLayout.RenderHiRes(batch);

				enemyLayout.RenderTopHiRes(batch);
				playerLayout.RenderTopHiRes(batch);

				playerStats.RenderHiRes(batch);
			}
			else*/ if(GameState == .GameEnd)
			{
				let textBoxWidth = NecroCard.Instance.FrameToWindow(.(endscreenBoxWidth)).X - NecroCard.Instance.FrameToWindow(.Zero).X;

				let scale = Vector2(((float)NecroCard.Instance.FrameScale / Draw.font.Size)) * 6;
				let widthNeeded = Draw.font.WidthOf(resultString) * scale.X;
				let drawOffset = (int)Math.Floor((textBoxWidth - widthNeeded) / 2); // Center

				if (resultString != null) batch.Text(Draw.font, resultString, NecroCard.Instance.FrameToWindow(endscreenText) + .(drawOffset, 0), scale, .Zero, 0, .DarkText);
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

				// Particles
				for (int i < particles.Count)
				{
					var part = ref particles[i];
					part.lifetime += Time.Delta;

					if (part.lifetime > 0.12f)
					{
						part.scale = Vector2.Lerp(part.scale, .(-0.2f, -0.2f), Time.Delta * 6);

						if (part.scale.X < 0.1f)
						{	
							particles.RemoveAtFast(i);
							i--;
						}
					}
				}

				// Test for winning/loosing conditions on turn change
				if (prevPlayerTurn != playerTurn)
				{
					turn++;

					// Empty board penalty
					if (prevPlayerTurn && playerLayout.count == 0)
						playerStats.health -= EmptyDamage;
					else if (!prevPlayerTurn && enemyLayout.count == 0)
						enemyStats.health -= EmptyDamage;

					// Out of health "energy"
					if (playerStats.health <= 0 && enemyStats.health <= 0)
					{
						gameEnds = true;
						resultString = "BOTH ran out of energy";
					}
					else if (playerStats.health <= 0)
					{
						gameEnds = true;
						resultString = "YOU ran out of energy";
					}
					else if (enemyStats.health <= 0)
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
				bool prevRestartHover = endscreenRestartHover;
				bool prevMenuHover = endscreenMenuHover;
				endscreenRestartHover = endscreenRestart.Contains(PixelMouse);
				endscreenMenuHover = endscreenMenu.Contains(PixelMouse);

				if (endscreenRestartHover && !prevRestartHover
					|| endscreenMenuHover && !prevMenuHover)
					SoundSource.Play(Sound.buttonHover);

				if (Input.Mouse.Pressed(.Left))
				{
					if (endscreenRestartHover)
					{
						SoundSource.Play(Sound.buttonClick);
						NecroCard.Instance.RestartBoard();
					}
					else if (endscreenMenuHover)
					{
						SoundSource.Play(Sound.buttonClick);
						NecroCard.Instance.LoadMenu();
					}
				}
			}
			else if (gameEnds)
			{
				// Game end delay
				if (gameEnds)
					gameEndDelayCounter -= Time.Delta;

				if (gameEnds && gameEndDelayCounter <= 0)
				{
					GameState = .GameEnd;
					if (playerWon)
						SoundSource.Play(Sound.win);
					//else SoundSource.Play(Sound.cardAttack);
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
