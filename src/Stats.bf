using System;
using System.Collections;
using Pile;

namespace NecroCard
{
	public class Stats
	{
		// @do this should just be one base class and enemy and player inheritors!
		// generally, move these classes out of this file

		public struct HandCard
		{
			public readonly Card Card;

			public Point2 Position { get; private set mut; }
			Vector2 easePos;
			public Vector2 EasePos
			{
				[Inline]
				get => easePos;
				set mut
				{
					easePos = value;
					Position = value.Round();
				}
			}

			public this(Card card)
			{
				Card = card;
				easePos = .(0, 64); // Below screen
				Position = easePos.Round();
			}
		}

		const int MaxHandCards = 4;
		const int PlayOffset = -6;
		const int CardSpacing = 4;
		readonly Point2 Top = NecroCard.Instance.Center + .(0, Card.Size.Y / 2 + 8);
		readonly Rect DrawButton = .(Top + .(-134, -5), .(31, 16));
		readonly Board Board;
		readonly CardLayout Layout;
		readonly bool IsPlayer;

		public List<HandCard> hand = new List<HandCard>(MaxHandCards) ~ delete _;
		int drawStartXOffset = 0;
		int selected = -1;
		bool firstTurn = true;

		public int health = 20;

		public bool buttonDown;

		public this(Board board, CardLayout layout, bool player)
		{
			Board = board;
			Layout = layout;
			IsPlayer = player;
		}

		// not called on enemy because its not visible
		public void Update()
		{
			// Card position ease
			for (let i < hand.Count)
			{
				if (i == selected)
				{
					hand[[Unchecked]i].EasePos = .(
						0, // @do easing when playing/ drawing cards
						Math.Lerp(hand[[Unchecked]i].EasePos.Y, PlayOffset, Time.Delta * 10)
					);
				}
				else
				{
					hand[[Unchecked]i].EasePos = .(
						0,
						Math.Lerp(hand[[Unchecked]i].EasePos.Y, 0, Time.Delta * 16)
					);
				}
			}
		}

		// only called if its the player turn
		public void RunPlayerControls()
		{
			// Card hovering
			{
				var Xoffset = drawStartXOffset;
				bool somethingSelected = false;
				for (let i < hand.Count)
				{
					if (Rect(Top + .(Xoffset, 0), Card.Size).Contains(PixelMouse))
					{
						selected = i;
						somethingSelected = true;
						break;
					}

					Xoffset += Card.Size.X + CardSpacing;
				}

				if (!somethingSelected)
					selected = -1;
			}

			// Click events
			if (Core.Input.Mouse.Pressed(.Left))
			{
				// note: turn will be consumed by the called functions if the action is valid

				// Play cards
				if (selected >= 0)
				{
					PlayCard(selected);
					selected = -1;
				}
				// Draw cards
				else if (DrawButton.Contains(PixelMouse))
				{
					DrawCard();
				}
			}

			buttonDown = Core.Input.Mouse.Down(.Left) && DrawButton.Contains(PixelMouse);
		}

		public void Render(Batch2D batch)
		{
			var xOffset = drawStartXOffset;
			for (int i < hand.Count)
			{
				let handCard = hand[[Unchecked]i];
				handCard.Card.Draw(batch, Top + .(xOffset, handCard.Position.Y)); // @do later easing to xOffset should be in update, this should just be .Position

				if (DebugRender)
					batch.HollowRect(.(Top + .(xOffset, handCard.Position.Y), Card.Size), 1, .Red);

				xOffset += Card.Size.X + CardSpacing;
			}

			if (DebugRender)
				batch.HollowRect(DrawButton, 1, .Green);
		}

		public void RenderHiRes(Batch2D batch)
		{
			var xOffset = drawStartXOffset;
			for (int i < hand.Count)
			{
				let handCard = hand[[Unchecked]i];
				handCard.Card.DrawHiRes(batch, Top + .(xOffset, handCard.Position.Y));

				xOffset += Card.Size.X + CardSpacing;
			}
		}

		[Inline]
		public bool IsFull()
		{
			return hand.Count >= MaxHandCards;
		}

		public bool CanDrawCard() => !IsFull() && !firstTurn; // YOU HAVE TO PLAY ON YOUR FIRST TURN

		public void DrawCard(bool force = false)
		{
			if (!force && !CanDrawCard())
				return;

			hand.Add(.(Board.DrawCard()));

			drawStartXOffset = -(hand.Count * (CardSpacing + Card.Size.X)) / 2;

			if (!force)
				EndTurn();
		}
		
		public void PlayCard(int index)
		{
			if (Layout.IsFull())
			{
				// @do color ease as indicator
				return;
			}

			// update drawStartXOffset & deck
			let card = hand[index];
			hand.RemoveAt(index);
			drawStartXOffset = -(hand.Count * (CardSpacing + Card.Size.X)) / 2;

			Layout.PlayCard(card.Card);
			EndTurn();
		}

		[Inline]
		void EndTurn()
		{
			Board.playerTurn = IsPlayer ? false : true;
			firstTurn = false;
		}
	}
}
