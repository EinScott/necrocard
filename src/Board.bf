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

			Register!(new Card("Thork", 1, 5, 3, 0));
			Register!(new Card("Bacat", 3, 2, 1, 1));
			Register!(new Card("Quak", 5, 1, 4, 2));
		}

		public CardLayout playerLayout = new CardLayout(-4) ~ delete _;
		public CardLayout enemyLayout = new CardLayout(-(int)CardLayout.Size.Y - 8) ~ delete _;

		public Stats playerStats = new Stats(this, playerLayout, true) ~ delete _;
		public Stats enemyStats = new Stats(this, enemyLayout, false) ~ delete _;

		public Enemy enemy = new Enemy(enemyStats, enemyLayout) ~ delete _;

		public bool playerTurn = rand.Next(0, 2) == 1;

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
			Draw.button.Asset.Draw(batch, frame, .(27, 133));

			// Render health
			DrawNum(batch, playerStats.health, .(30, 171));
			DrawNum(batch, playerStats.health, .(274, 171));

			enemyLayout.Render(batch);
			playerLayout.Render(batch);

			playerStats.Render(batch);
		}

		// hi res overlay
		public void RenderHiRes(Batch2D batch)
		{
			enemyLayout.RenderHiRes(batch);
			playerLayout.RenderHiRes(batch);

			playerStats.RenderHiRes(batch);
		}

		void DrawNum(Batch2D batch, int num, Point2 position)
		{
			Draw.bigNumbers.Asset.Draw(batch, Math.Clamp((int)Math.Floor((float)num / 10), 0, 9), position);
			Draw.bigNumbers.Asset.Draw(batch, Math.Clamp(num % 10, 0, 9), position + .(9, 0));
		}

		public void Update()
		{
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
		}	

		public Card DrawCard()
		{
			var newCard = rand.Next(0, allCards.Count);
			while (newCard == lastCard)
				newCard = rand.Next(0, allCards.Count);

			lastCard = newCard;
			return allCards[newCard];
		}
	}
}
