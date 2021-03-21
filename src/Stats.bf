using System;
using System.Collections;
using Pile;

namespace NecroCard
{
	struct CardInstance
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
			easePos = .(0, 64); // Middle below screen
			Position = easePos.Round();
		}
	}

	public class Stats
	{
		// not the nicest code, is all over the place, but works

		const int MaxHandCards = 4;
		public const int PlayOffset = -6;
		const int CardSpacing = 4;
		readonly Point2 Top = NecroCard.Instance.Center + .(0, Card.Size.Y / 2 + 8);
		readonly Rect DrawButton = .(Top + .(-134, -5), .(31, 16));
		readonly Board Board;
		readonly CardLayout Layout;
		readonly bool IsPlayer;

		public List<CardInstance> hand = new List<CardInstance>(MaxHandCards) ~ delete _;
		int drawStartXOffset = 0;
		int selected = -1;
		bool firstTurn = true;
		int prevSelected = -1;

		public int health = 20;

		public bool buttonDown;
		bool prevButtonDown;

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
			var xOffset = drawStartXOffset;
			for (let i < hand.Count)
			{
				if (i == selected)
				{
					hand[[Unchecked]i].EasePos = .(
						Math.Lerp(hand[[Unchecked]i].EasePos.X, xOffset, Time.Delta * 12),
						Math.Lerp(hand[[Unchecked]i].EasePos.Y, PlayOffset, Time.Delta * 10)
					);
				}
				else
				{
					hand[[Unchecked]i].EasePos = .(
						Math.Lerp(hand[[Unchecked]i].EasePos.X, xOffset, Time.Delta * 12),
						Math.Lerp(hand[[Unchecked]i].EasePos.Y, 0, Time.Delta * 16)
					);
				}

				xOffset += Card.Size.X + CardSpacing;
			}
		}

		// only called if its the player turn
		public void RunPlayerControls()
		{
			// Card hovering
			{
				prevSelected = selected;

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
				{
					selected = -1;
				}
				else if (prevSelected != selected)
				{
					SoundSource.Play(Sound.cardHover);
				}
			}

			// Click events
			if (Input.Mouse.Pressed(.Left))
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
					if (CanDrawCard())
						SoundSource.Play(Sound.buttonClick);

					DrawCard(); // Can draw card is check in function
				}
			}

			prevButtonDown = buttonDown;
			buttonDown = Input.Mouse.Down(.Left) && DrawButton.Contains(PixelMouse);
			if (!prevButtonDown && buttonDown)
				SoundSource.Play(Sound.buttonHover);
		}

		public void Render(Batch2D batch)
		{
			for (int i < hand.Count)
			{
				let handCard = hand[[Unchecked]i];
				handCard.Card.Draw(batch, Top + handCard.Position);

				if (DebugRender)
				{
					batch.HollowRect(.(Top + handCard.Position, Card.Size), 1, .Red);
				}
			}

			if (DebugRender)
				batch.HollowRect(DrawButton, 1, .Green);
		}

		/*public void RenderHiRes(Batch2D batch)
		{
			for (int i < hand.Count)
			{
				let handCard = hand[[Unchecked]i];
				handCard.Card.DrawHiRes(batch, Top + handCard.Position);
			}
		}*/

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
			{
				SoundSource.Play(Sound.cardShuffle);
				EndTurn();
			}
		}
		
		public void PlayCard(int index)
		{
			if (Layout.IsFull())
			{
				return;
			}

			// update drawStartXOffset & deck
			let card = hand[index];
			hand.RemoveAt(index);
			drawStartXOffset = -(hand.Count * (CardSpacing + Card.Size.X)) / 2;

			SoundSource.Play(Sound.cardPlay);
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
