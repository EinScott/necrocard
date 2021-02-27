using System;
using Pile;

namespace NecroCard
{
	class Card
	{
		public const UPoint2 Size = .(36, 56);
		const Point2 activeOffset = .(5, 44);
		const Point2 energyOffset = .(23, 44);

		public String Name;
		public int Active;
		public int Energy;
		public int SpriteFrame;

		public String ActiveString = new .() ~ delete _;
		public String PassiveString = new .() ~ delete _;

		public this(String name, int active, int energy, int spriteFrame)
		{
			Name = name;
			Active = active;
			Energy = energy;
			SpriteFrame = spriteFrame;

			Active.ToString(ActiveString);
			Energy.ToString(PassiveString);
		}

		public void Draw(Batch2D batch, Point2 position)
		{
			Draw.cards.Asset.Draw(batch, SpriteFrame, position);
			Draw.smallNumbers.Asset.Draw(batch, Math.Clamp(Active, 0, 9), position + activeOffset);
			Draw.smallNumbers.Asset.Draw(batch, Math.Clamp(Energy, 0, 9), position + energyOffset);
		}

		public void DrawHiRes(Batch2D batch, Point2 position)
		{
			// Text
			let font = Draw.font;
			let pixelTitlePos = position + .(9, 3); // @polish center properly
			
			let baseScale = Vector2(((float)NecroCard.Instance.FrameScale / font.Size));

			batch.Text(font, Name, NecroCard.Instance.FrameToWindow(pixelTitlePos), baseScale * 8, .Zero, 0, .DarkText);
		}
	}
}
