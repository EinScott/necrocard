using System;
using Pile;

namespace NecroCard
{
	class Card
	{
		public const UPoint2 Size = .(36, 56);
		const Point2 activeOffset = .(5, 44);
		const Point2 energyOffset = .(23, 44);
		//const int titleBoxLength = 20;

		public String Name;
		public int Active;
		public int Energy;
		public int SpriteFrame;

		public this(String name, int active, int energy, int spriteFrame)
		{
			Name = name;
			Active = active;
			Energy = energy;
			SpriteFrame = spriteFrame;
		}

		public void Draw(Batch2D batch, Point2 position)
		{
			Draw.cards.Asset.Draw(batch, SpriteFrame, position);
			Draw.smallNumbers.Asset.Draw(batch, Math.Clamp(Active, 0, 9), position + activeOffset);
			Draw.smallNumbers.Asset.Draw(batch, Math.Clamp(Energy, 0, 9), position + energyOffset);
		}

		/*public void DrawHiRes(Batch2D batch, Point2 position)
		{
			// Text
			let font = Draw.font;
			let pixelTitlePos = position + .(8, 3);
			let titleBoxWidth = NecroCard.Instance.FrameToWindow(.(titleBoxLength)).X;
			
			let scale = Vector2(((float)NecroCard.Instance.FrameScale / font.Size)) * 8;
			let widthNeeded = font.WidthOf(Name) * scale.X;
			let drawOffset = (int)Math.Floor((titleBoxWidth - widthNeeded) / 2); // Center

			batch.Text(font, Name, NecroCard.Instance.FrameToWindow(pixelTitlePos) + .(drawOffset, 0), scale, .Zero, 0, .DarkText);
		}*/
	}
}
