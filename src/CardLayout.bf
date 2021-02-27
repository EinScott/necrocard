using System;
using Pile;

namespace NecroCard
{
	public class CardLayout
	{
		public struct LayoutCard
		{
			public readonly Card Card;

			public int health;

			// position

			public this(Card card)
			{
				Card = card;

				health = 0;
			}
		}

		const int MaxCardCapacity = 5;
		const int XDrawOffsetDelta = (int)(float)Size.X / MaxCardCapacity;
		const int XDrawOffsetStart = -(XDrawOffsetDelta - Card.Size.Y - 4) / 2;
		readonly Point2 Top = NecroCard.Instance.Center + .(0, Card.Size.Y / 2 + 4);
		public const UPoint2 Size = .(240, Card.Size.Y);
		public const Point2 Offset = -Size / 2;

		int count;
		public LayoutCard[MaxCardCapacity] cards = .();
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

		public this(int yPos)
		{
			YOffset = yPos;
		}

		public void Render(Batch2D batch)
		{
			var currentXOffset = XDrawOffsetStart;
			for(let card in cards)
			{
				if (card.Card == null)
					continue;

				card.Card.Draw(batch, bounds.Position + .(currentXOffset, 0));
				currentXOffset += XDrawOffsetDelta;
			}

			// DEBUG
			if (DebugRender)
				batch.HollowRect(Bounds, 1, .Gray);
		}

		public void RenderHiRes(Batch2D batch)
		{
			var currentXOffset = XDrawOffsetStart;
			for(let card in cards)
			{
				if (card.Card == null)
					continue;

				card.Card.DrawHiRes(batch, bounds.Position + .(currentXOffset, 0));
				currentXOffset += XDrawOffsetDelta;
			}
		}

		public void Update()
		{

		}

		public void RunPlayerControls()
		{

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

		[Inline]
		public bool IsFull() => count >= MaxCardCapacity;
	}
}
