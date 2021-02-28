using Pile;
using System;

namespace NecroCard
{
	class Menu
	{
		const Rect tutorialButton = .(132, 67, 56, 14);
		const Rect playButton = .(132, 84, 56, 14);
		const Rect quitButton = .(132, 101, 56, 14);
		const Point2 logoPos = .(127, 19);
		const Point2 tutorialBoxPos = .(122, 79);
		const String tutorialText = """
			- whoever reaches 0 energy first, looses

			- if you have no cards on the field at the
			  end of your turn, you loose 2 energy

			- click to play cards from you hand
			  onto the field (consumes your turn)

			- drag cards onto enemy cards to
			  let them fight (consumes your turn)

			- in a fight, both cards are destroyed

			- two cards with equal attack can't fight

			- in a fight, if your cards' attack is
			  greater, the enemy takes that amount of
			  damage
			  if it is smaller, you gain the energy
			  of your card
			""";
		const Point2 tutorialCardHandPos = .(244, 141);
		const Point2 tutorialEnemyCardHandPos = .(244, 13);
		const Rect tutorialBackButton = .(166, 64, 32, 13);

		float logoSin;
		uint8 focusedButton;
		bool tutorial;

		int tutorialStage = 0;

		public void Update()
		{
			logoSin = (float)Math.Sin(Time.Duration.TotalSeconds * 2) * 4;
			bool click = Core.Input.Mouse.Pressed(.Left);

			if (!tutorial)
			{
				if (tutorialButton.Contains(PixelMouse))
				{
					focusedButton = 1;
					if (click) tutorial = true;
				}
				else if (playButton.Contains(PixelMouse))
				{
					focusedButton = 2;
					if (click) NecroCard.Instance.LoadGame();
				}
				else if (quitButton.Contains(PixelMouse))
				{
					focusedButton = 3;
					if (click) Core.Exit();
				}
				else focusedButton = 0;
			}
			else
			{
				if (tutorialBackButton.Contains(PixelMouse))
				{
					focusedButton = 4;
					if (click) tutorial = false;
				}
				else focusedButton = 0;

				// Interactive tutorial
				if (tutorialStage == 0)
			}
		}

		public void Render(Batch2D batch)
		{
			Draw.menu.Asset.Draw(batch, tutorial ? 1 : 0, .Zero);

			Draw.logo.Asset.Draw(batch, 0, logoPos + .(0, (int)Math.Round(logoSin)));

			if (!tutorial)
			{
				Draw.tutorialButton.Asset.Draw(batch, focusedButton == 1 ? 1 : 0, tutorialButton.Position);
				Draw.playButton.Asset.Draw(batch, focusedButton == 2 ? 1 : 0, playButton.Position);
				Draw.quitButton.Asset.Draw(batch, focusedButton == 3 ? 1 : 0, quitButton.Position);
			}
			else
			{
				Draw.cards.Asset.Draw(batch, 5, tutorialCardHandPos);
				Draw.cards.Asset.Draw(batch, 5, tutorialEnemyCardHandPos);

				Draw.backButton.Asset.Draw(batch, focusedButton == 4 ? 1 : 0, tutorialBackButton.Position);
			}
		}

		public void RenderHiRes(Batch2D batch)
		{
			if (tutorial)
			{
				let scale = Vector2(((float)NecroCard.Instance.FrameScale / Draw.font.Size)) * 5;

				batch.Text(Draw.font, tutorialText, NecroCard.Instance.FrameToWindow(tutorialBoxPos), scale, .Zero, 0, .DarkText);
			}
		}
	}
}