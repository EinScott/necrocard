using Pile;
using System;

using internal NecroCard;

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
			- whoever reaches 0 energy first, loses

			- if you have no cards on the field at the
			  end of your turn, you lose 2 energy

			- click to play cards from you hand
			  onto the field (consumes your turn)

			- drag cards onto enemy cards to
			  let them fight (consumes your turn)

			- in a fight, both cards are destroyed

			- two cards with equal attack can't fight

			- in a fight, if your card's attack is
			  greater, the enemy takes that amount of
			  damage
			  if it is smaller, you gain the energy
			  of your card
			""";
		const Point2 tutorialCardHandPos = .(244, 141);
		const Point2 tutorialCardLayoutPos = .(244, 73);
		const Point2 tutorialEnemyCardLayoutPos = .(244, 13);
		const Rect tutorialBackButton = .(166, 64, 32, 13);

		float logoSin;
		uint8 focusedButton;
		uint8 prevFocusedButton;
		bool tutorial;

		int tutorialStage = 0;
		float tutorialCardOffset;
		Point2 tutorialDragOffset;
		bool dragging;

		bool tutorialPrevHoveredCard;

		float sliderValue = 1;
		const float SliderScale = 2;
		const Rect SoundSliderBox = .(249, 185, 64, 5);
		const Rect SoundSlider = .(249, 187, 64, 1);
		const Rect SoundSliderControl = .(249, 185, 1, 5);
		const Color SliderColor = .(77, 39, 39);

		bool prevSliderFocused;

		public void Update()
		{
			prevFocusedButton = focusedButton;

			logoSin = (float)Math.Sin(Time.Duration.TotalSeconds * 2) * 4;
			bool click = Core.Input.Mouse.Pressed(.Left);

			if (!tutorial)
			{
				if (SoundSliderBox.Contains(PixelMouse))
				{
					if (!prevSliderFocused)
					{
						SoundSource.Play(Sound.buttonHover);
						prevSliderFocused = true;
					}

					// Slider controls
					if (Core.Input.Mouse.Down(.Left))
					{
						let diff = PixelMouse.X - SoundSliderBox.X;
						sliderValue = ((float)diff / SoundSliderBox.Width) * SliderScale;

						NecroCard.Instance.music.Volume = sliderValue;
						NecroCard.Instance.sounds.Volume = sliderValue;
					}
				}
				else prevSliderFocused = false;

				if (tutorialButton.Contains(PixelMouse))
				{
					focusedButton = 1;
					if (click)
					{
						tutorial = true;
						SoundSource.Play(Sound.buttonClick);
					}
					else if (prevFocusedButton != focusedButton)
					{
						SoundSource.Play(Sound.buttonHover);
					}
				}
				else if (playButton.Contains(PixelMouse))
				{
					focusedButton = 2;
					if (click)
					{
						NecroCard.Instance.LoadGame();
						SoundSource.Play(Sound.buttonClick);
					}
					else if (prevFocusedButton != focusedButton)
					{
						SoundSource.Play(Sound.buttonHover);
					}
				}
				else if (quitButton.Contains(PixelMouse))
				{
					focusedButton = 3;
					if (click) Core.Exit();
					else if (prevFocusedButton != focusedButton)
					{
						SoundSource.Play(Sound.buttonHover);
					}
				}
				else focusedButton = 0;
			}
			else
			{
				if (tutorialBackButton.Contains(PixelMouse))
				{
					focusedButton = 4;
					if (click)
					{
						tutorial = false;
						SoundSource.Play(Sound.buttonClick);
					}
					else if (prevFocusedButton != focusedButton)
					{
						SoundSource.Play(Sound.buttonHover);
					}
				}
				else focusedButton = 0;

				// Interactive tutorial
				if (tutorialStage == 0)
				{
					if (Rect(tutorialCardHandPos, Card.Size).Contains(PixelMouse))
					{
						tutorialCardOffset = Math.Lerp(tutorialCardOffset, Stats.PlayOffset, Time.Delta * 10);

						if (click)
						{
							tutorialStage = 1;
							SoundSource.Play(Sound.cardPlay);
						}

						if (!tutorialPrevHoveredCard)
						{
							SoundSource.Play(Sound.cardHover);
							tutorialPrevHoveredCard = true;
						}
					}
					else
					{
						tutorialPrevHoveredCard = false;
						tutorialCardOffset = Math.Lerp(tutorialCardOffset, 0, Time.Delta * 16);
					}
				}
				else if (tutorialStage == 1)
				{
					if (Rect(tutorialCardLayoutPos, Card.Size).Contains(PixelMouse))
					{
						tutorialCardOffset = -1;

						if (click)
						{
							dragging = true;
							tutorialDragOffset = tutorialCardLayoutPos + .(0, (int)tutorialCardOffset) - PixelMouse;
							SoundSource.Play(Sound.cardClick);
						}

						if (!tutorialPrevHoveredCard)
						{
							SoundSource.Play(Sound.cardHover);
							tutorialPrevHoveredCard = true;
						}
					}
					else
					{
						tutorialPrevHoveredCard = false;
						tutorialCardOffset = 0;
					}

					if (dragging && !Core.Input.Mouse.Down(.Left))
					{
						// Drag end
						if (Rect(tutorialEnemyCardLayoutPos, Card.Size).Overlaps(Rect(PixelMouse + tutorialDragOffset, Card.Size)))
						{
							tutorialStage = 2;
							SoundSource.Play(Sound.cardAttack);
						}
						else SoundSource.Play(Sound.cardClick);

						dragging = false;
					}
				}
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

				// Slider
				batch.Rect(SoundSlider, SliderColor);
				batch.Rect(.(SoundSliderControl.Position + .((int)Math.Round((sliderValue / SliderScale) * SoundSlider.Size.X), 0), SoundSliderControl.Size), SliderColor);
			}
			else
			{
				Draw.backButton.Asset.Draw(batch, focusedButton == 4 ? 1 : 0, tutorialBackButton.Position);

				// Tutorial
				if (tutorialStage < 2)
					Draw.cards.Asset.Draw(batch, 5, tutorialEnemyCardLayoutPos);

				if (tutorialStage == 0)
					Draw.cards.Asset.Draw(batch, 5, tutorialCardHandPos + .(0, (int)tutorialCardOffset));
				else if (tutorialStage == 1)
				{
					let pos = dragging ? PixelMouse + tutorialDragOffset : tutorialCardLayoutPos + .(0, (int)tutorialCardOffset); // @do report bug: having this integrate in call below will error codegen
					Draw.cards.Asset.Draw(batch, 5, pos);
				}
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
