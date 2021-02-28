using System;
using Pile;

namespace NecroCard
{
	public class CardLayout
	{
		const int selectYOffset = -1;
		const int MaxCardCapacity = 5;
		const int XDrawOffsetDelta = (int)(float)Size.X / MaxCardCapacity;
		const int XDrawOffsetStart = -(XDrawOffsetDelta - Card.Size.Y - 4) / 2;
		readonly Point2 Top = NecroCard.Instance.Center + .(0, Card.Size.Y / 2 + 4);
		public const UPoint2 Size = .(240, Card.Size.Y);
		public const Point2 Offset = -Size / 2;
		readonly Board Board;
		readonly bool IsPlayer;

		public int count;
		public CardInstance[MaxCardCapacity] cards = .();
		int yOffset;
		public int YOffset
		{
			get => yOffset;
			set
			{
				yOffset = value;
				bounds = .(NecroCard.Instance.Center + Offset + .(0, yOffset), Size);
			}
		}

		Rect bounds;
		public Rect Bounds => bounds;

		int selected = -1;
		bool dragging;
		Point2 dragOffset;
		public Point2 dragPosition;

		public this(Board board, int yPos, bool player)
		{
			YOffset = yPos;
			Board = board;
			IsPlayer = player;
		}

		public void Render(Batch2D batch)
		{
			var currentXOffset = XDrawOffsetStart;
			for(int i < cards.Count)
			{
				let card = ref cards[[Unchecked]i];
				if (card.Card == null)
				{
					currentXOffset += XDrawOffsetDelta;
					continue;
				}

				if (dragging && i == selected)
				{
					currentXOffset += XDrawOffsetDelta;
					continue;
				}

				let yOffset = i == selected ? selectYOffset : 0;
				card.Card.Draw(batch, bounds.Position + .(currentXOffset, yOffset));

				if (DebugRender)
					batch.HollowRect(.(bounds.Position + .(currentXOffset, 0), Card.Size), 1, .Red);

				currentXOffset += XDrawOffsetDelta;
			}

			// DEBUG
			if (DebugRender)
				batch.HollowRect(Bounds, 1, .Gray);
		}

		public void RenderTop(Batch2D batch)
		{
			if (dragging)
			{
				cards[[Unchecked]selected].Card.Draw(batch, dragPosition);
			}
		}

		public void RenderHiRes(Batch2D batch)
		{
			var currentXOffset = XDrawOffsetStart;
			for(int i < cards.Count)
			{
				let card = ref cards[[Unchecked]i];
				if (card.Card == null)
				{
					currentXOffset += XDrawOffsetDelta;
					continue;
				}

				if (dragging && i == selected)
				{
					currentXOffset += XDrawOffsetDelta;
					continue;
				}

				let yOffset = i == selected ? selectYOffset : 0;
				card.Card.DrawHiRes(batch, bounds.Position + .(currentXOffset, yOffset));
				currentXOffset += XDrawOffsetDelta;
			}
		}

		public void RenderTopHiRes(Batch2D batch)
		{
			if (dragging)
			{
				cards[[Unchecked]selected].Card.DrawHiRes(batch, dragPosition);
			}
		}

		public void EnemySetSelectedDrag(int index)
		{
			selected = index;
			dragging = true;

			// Find current drag start position
			dragPosition = EnemyGetCardPos(selected);
		}

		public void EnemyEndDrag()
		{
			selected = -1;
			dragging = false;
		}

		public Point2 EnemyGetCardPos(int index)
		{
			var currentXOffset = XDrawOffsetStart;
			for(int i < cards.Count)
			{
				if (i == index)
				{
					return bounds.Position + .(currentXOffset, yOffset);
				}
				currentXOffset += XDrawOffsetDelta;
			}

			return .Zero;
		}

		public void Update()
		{

		}

		public void RunPlayerControls()
		{
			// Selection
			if (!dragging)
			{
				var currentXOffset = XDrawOffsetStart;
				bool somethingSelected = false;
				for(int i < cards.Count)
				{
					let card = ref cards[i];
					if (card.Card == null)
					{
						currentXOffset += XDrawOffsetDelta;
						continue;
					}

					if (Rect(bounds.Position + .(currentXOffset, 0), Card.Size).Contains(PixelMouse))
					{
						selected = i;

						dragOffset = (bounds.Position + .(currentXOffset, selectYOffset)) - PixelMouse;
						somethingSelected = true;
						break;
					}
					currentXOffset += XDrawOffsetDelta;
				}

				if (!somethingSelected)
					selected = -1;
			}

			if (dragging)
			{
				dragPosition = PixelMouse + dragOffset;
			}

			if (Core.Input.Mouse.Pressed(.Left) && selected >= 0)
			{
				dragging = true;
			}
			else if (dragging && !Core.Input.Mouse.Down(.Left))
			{
				// Look for overlaps
				let enemyCards = ref Board.enemyLayout.cards;
				var currentXOffset = XDrawOffsetStart;
				int attacked = -1;
				int attackOverlap = 0;
				let draggingCardRect = Rect(PixelMouse + dragOffset, Card.Size);

				// Select the one we overlap the most
				for(int i < enemyCards.Count)
				{
					let card = ref enemyCards[i];
					if (card.Card == null)
					{
						currentXOffset += XDrawOffsetDelta;
						continue;
					}

					let currentCardRect = Rect(Board.enemyLayout.Bounds.Position + .(currentXOffset, 0), Card.Size);
					if (currentCardRect.Overlaps(draggingCardRect))
					{
						let overlapArea = currentCardRect.OverlapRect(draggingCardRect).Area;
						if (attackOverlap < overlapArea) // If we overlap this one more
						{
							attackOverlap = overlapArea;
							attacked = i;
						}
					}
					currentXOffset += XDrawOffsetDelta;
				}

				// Attack if target was chosen
				if (attacked >= 0)
					Attack(selected, attacked);

				dragging = false;
			}
		}

		public void PlayCard(Card card)
		{
			if (IsFull())
				return;

			for (int i < MaxCardCapacity)
				if (cards[[Unchecked]i].Card == null)
				{
					cards[[Unchecked]i] = .(card);
					break;
				}

			count++;
		}

		public void Attack(int attackerIndex, int attackedIndex)
		{
			let other = (IsPlayer ? Board.enemyLayout : Board.playerLayout);

			let attacker = ref cards[attackerIndex];
			let attacked = ref other.cards[attackedIndex];

			if (attacker.Card.Active > attacked.Card.Active)
			{
				let otherStats = (IsPlayer ? Board.enemyStats : Board.playerStats);
				otherStats.health -= attacker.Card.Active;
			}
			else if (attacker.Card.Active < attacked.Card.Active)
			{
				let myStats = (!IsPlayer ? Board.enemyStats : Board.playerStats);
				myStats.health += attacker.Card.Energy;
			}
			else
			{
				return; // @do @polish communicate this with particle. Indeed, add particles to attack actions, all of them
			}

			DestroyCard(attackerIndex);
			other.DestroyCard(attackedIndex);

			EndTurn();
		}

		public void DestroyCard(int index)
		{
			cards[index] = .(null);
			count --;
		}

		[Inline]
		public bool IsFull() => count >= MaxCardCapacity;

		[Inline]
		void EndTurn()
		{
			Board.playerTurn = IsPlayer ? false : true;
		}
	}
}
