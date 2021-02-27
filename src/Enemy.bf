using System;
using Pile;

namespace NecroCard
{
	class Enemy
	{
		readonly Stats Stats;
		readonly CardLayout Layout;

		float waitCounter = 0.8f;

		public this(Stats stats, CardLayout layout)
		{
			Stats = stats;
			Layout = layout;
		}

		public void MakeMove()
		{
			// So that the ai doesnt just intimidate you with its speed...
			if (waitCounter > 0)
			{
				waitCounter -= Time.Delta;
				return;
			}

			ActuallyMakeMove();

			waitCounter = (float)rand.Next(5, 21) / 10;
		}

		[Inline]
		void ActuallyMakeMove()
		{
			// all these actions have chances so that this thing does dumb stuff!

			// if my board is empty try to play card that is equal to the card played by the player

			if (Stats.hand.Count > 0)
			{
				Stats.PlayCard(0);
			}
			else
			{
				Stats.DrawCard();
			}

			if (!Stats.[Friend]Board.playerTurn)
			{
				// temp anti stuck skip turn
				Stats.[Friend]EndTurn();
			}
		}	
	}
}
