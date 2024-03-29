using System;
using Pile;

namespace NecroCard
{
	class Enemy
	{
		const float AttackWait = 0.1f;

		readonly Stats Stats;
		readonly CardLayout Layout;

		int attackingCard;
		int attackedCard;
		float attackWaitCounter;
		Vector2 attackDest;
		Vector2 attackCurr;
		float waitCounter = 0.8f;
		bool attacking;
		public bool hard;

		public this(Stats stats, CardLayout layout, bool first)
		{
			Stats = stats;
			Layout = layout;
			hard = (!first && Board.wins > 2 && rand.Next(0, 2) == 0 || Input.Keyboard.Shift);
			Log.Debug(hard);
		}

		public void MakeMove()
		{
			// So that the ai doesnt just intimidate you with its speed...
			if (waitCounter > 0)
			{
				waitCounter -= Time.Delta;
				return;
			}

			if (!attacking)
				ActuallyMakeMove();
			else
			{
				if (Vector2.Distance(attackCurr, attackDest) >= 12)
				{
					// Attack animation card lerp
					attackCurr = Vector2.Lerp(attackCurr, attackDest, Time.Delta * 8);
					Layout.dragPosition = attackCurr.ToRounded();
				}
				else
					attackWaitCounter += Time.Delta;

				if (attackWaitCounter >= AttackWait)
				{
					// On end, actually call the attack and reset
					Layout.EnemyEndDrag();
					Layout.Attack(attackingCard, attackedCard, Layout.dragPosition + Card.Size / 2); // This will finally end the turn

					attackWaitCounter = 0;
					attacking = false;
				}
			}

			if (!attacking)
				waitCounter = (float)rand.Next(5, 11) / 10;
		}

		[Inline]
		void ActuallyMakeMove()
		{
			bool canAttack = true;
			CANATTACK:do
			{
				let otherLayout = Stats.[Friend]Board.playerLayout;
				if (Layout.count == 0 || otherLayout.count == 0)
				{
					canAttack = false;
					break;
				}

				int onlyAttack = 0;
				for (int i < Layout.cards.Count)
				{
					let myCard = ref Layout.cards[i];

					if (myCard.Card == null)
						continue;

					if (onlyAttack == 0)
						onlyAttack = myCard.Card.Active;
					else if (myCard.Card.Active != onlyAttack)
						break CANATTACK;
				}

				for (int j < otherLayout.cards.Count)
				{
					let otherCard = ref otherLayout.cards[j];

					if (otherCard.Card == null)
						continue;

					if (otherCard.Card.Active != onlyAttack)
						break CANATTACK;
				}

				canAttack = false;
			}
			
			// all these actions have chances so that this thing does dumb stuff!

			// if the board is even and i have less than normal health and can play the next turn, attack
			if (hard && canAttack && (Layout.count >= 2 || Layout.count == 1 && Stats.health > 6) && Layout.count == Stats.[Friend]Board.playerLayout.count && Stats.hand.Count >= 1 && rand.XinYChance(1, 4))
				Attack();

			else if (hard && canAttack && Stats.health > Stats.[Friend]Board.playerStats.health && Stats.hand.Count > 0 && rand.XinYChance(1, 3))
				Attack();

			// if i have more cards than the player, attack
			else if (hard && canAttack && Layout.count > Stats.[Friend]Board.playerLayout.count && rand.XinYChance(1, 4))
				Attack();

			// if my board is empty try to play card that is equal to the card played by the player
			else if (Layout.count <= 1 && Stats.hand.Count > 0 && rand.XinYChance(7, 8))
				PlayACard();

			// Chance of drawing cards
			else if (Stats.hand.Count < 2 && rand.XinYChance(2, Layout.count * 2 + 2))
				DrawCard();

			else if (Stats.hand.Count > 0 && rand.XinYChance(6 - Layout.count, 6))
				PlayACard();

			// Chance of attacking cards
			else if (canAttack && rand.XinYChance(3, 6 - Layout.count) && (!hard || (Stats.health > 2 && Layout.count == 1 || Layout.count > 1)))
				Attack();

			else if (rand.XinYChance(1, 2))
				DrawCard();

			if (attacking)
				return;

			if (!Stats.[Friend]Board.playerTurn) // If still nothing happened (maybe we cant draw or play)
			{
				if (canAttack)
					Attack(); // Try to attack, otherwise we will be called next loop...
				else PlayACard();
			}

			void DrawCard()
			{
				Log.Debug("DRAW CARD");
				Stats.DrawCard();
			}

			void PlayACard()
			{
				Log.Debug("PLAY CARD");

				let otherLayout = Stats.[Friend]Board.playerLayout;

				bool cardPlayed = false;
				if (Layout.count == 0 && rand.XinYChance(5, 6))
				{
					// We should play a card at best equal to the players card
					int highestActiveIndex = -1;
					int highestActive = 0;
					int bestIndex = -1;
					int bestActive = 0;
					for (int i < Stats.hand.Count)
					{
						let myCard = ref Stats.hand[i];

						// Collect these as plan b
						if (myCard.Card.Active > highestActive)
						{
							highestActiveIndex = i;
							highestActive = myCard.Card.Active;
						}

						if (myCard.Card.Active < bestActive)
							continue;

						for (int j < otherLayout.cards.Count)
						{
							let otherCard = ref otherLayout.cards[j];

							if (otherCard.Card == null)
								continue;

							if (myCard.Card.Active == otherCard.Card.Active)
							{
								bestIndex = i;
								bestActive = myCard.Card.Active;
							}
						}
					}

					if (bestIndex >= 0)
					{
						Stats.PlayCard(bestIndex);
						cardPlayed = true;
					}
					else if (highestActiveIndex >= 0)
					{
						Stats.PlayCard(highestActiveIndex);
						cardPlayed = true;
					}
				}

				if (!cardPlayed && Stats.hand.Count > 0)
				{
					// Play a random card
					Stats.PlayCard(rand.Next(0, Stats.hand.Count));
				}
			}

			void Attack()
			{
				Log.Debug("ATTACK");

				let otherLayout = Stats.[Friend]Board.playerLayout;
				let otherStats = Stats.[Friend]Board.playerStats;

				attackingCard = -1;

				if (otherLayout.count == 0)
					return;
				
				if (Stats.health < otherStats.health || rand.XinYChance(1, 6))
				{
					// We should get some health
					// attackingCard Has the highest energy and we can sacrifice it
					for (int i < Layout.cards.Count)
					{
						let myCard = ref Layout.cards[i];

						if (myCard.Card == null)
							continue;

						// Has this card better energy stats than previous
						if (attackingCard >= 0 && (Layout.cards[attackingCard].Card.Energy > myCard.Card.Energy
							|| Layout.cards[attackingCard].Card.Energy == myCard.Card.Energy && Layout.cards[attackingCard].Card.Active <= myCard.Card.Active))
							continue;

						if (rand.XinYChance(1, 6))
							continue; // Overlook this possibility

						// Can we sacrifice it?
						for (int j < otherLayout.cards.Count)
						{
							let otherCard = ref otherLayout.cards[j];

							if (otherCard.Card == null)
								continue;

							if (myCard.Card.Active < otherCard.Card.Active)
							{
								// This turn works
								attackingCard = i;
								attackedCard = j;
							}
						}
					}
				}

				if (attackingCard == -1 && (Layout.count >= Layout.cards.Count || rand.XinYChance(6, 7)))
				{
					// We should attack
					// attackingCard Has the highest active and we can attack something with it
					for (int i < Layout.cards.Count)
					{
						let myCard = ref Layout.cards[i];

						if (myCard.Card == null)
							continue;

						// Has this better attack than the previous
						if (attackingCard >= 0 && (Layout.cards[attackingCard].Card.Active > myCard.Card.Active
							|| Layout.cards[attackingCard].Card.Active == myCard.Card.Active && Layout.cards[attackingCard].Card.Energy <= myCard.Card.Energy))
							continue;

						if (rand.Next(0, 6) == 0)
							continue; // Overlook this possibility

						// Can we attack something with it?
						for (int j < otherLayout.cards.Count)
						{
							let otherCard = ref otherLayout.cards[j];

							if (otherCard.Card == null)
								continue;

							if (myCard.Card.Active > otherCard.Card.Active)
							{
								// This move works
								attackingCard = i;
								attackedCard = j;
							}
						}
					}
				}

				if (attackingCard == -1)
				{
					// If we end up here that means we're either stupid or can only trade, but were stupid/unlucky before
					// This may or may not be slightly crappy
					repeat
						for (let i < Layout.cards.Count)
							if (rand.XinYChance(1, 2) && Layout.cards[i].Card != null)
								attackingCard = i;
					while (attackingCard < 0 || Layout.cards[attackingCard].Card == null);

					repeat
						for (let i < otherLayout.cards.Count)
							if (rand.XinYChance(1, 2) && otherLayout.cards[i].Card != null)
								attackedCard = i;
					while (attackedCard < 0 || otherLayout.cards[attackedCard].Card == null);
				}

				// Set Layout up for dragging the card we want
				Layout.EnemySetSelectedDrag(attackingCard);
				attackCurr = Layout.dragPosition;
				attackDest = otherLayout.EnemyGetCardPos(attackedCard);

				attacking = true;
			}
		}	
	}
}
