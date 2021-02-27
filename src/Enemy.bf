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

			waitCounter = (float)rand.Next(0, 11) / 10;
		}

		[Inline]
		void ActuallyMakeMove()
		{
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
