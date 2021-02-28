using Pile;
using System;
using System.IO;
using FastNoiseLite;
using System.Collections;
using Dimtoo;

using internal NecroCard;

namespace Pile
{
	extension Color
	{
		public const Color DarkText = .(24, 20, 37);
	}
}

namespace NecroCard
{
	static
	{
#if DEBUG
		[Inline]
		public static bool DebugRender => NecroCard.Instance.debugRender;
#else
		[Inline]
		public static bool DebugRender => false;
#endif
		[Inline]
		public static Point2 PixelMouse => NecroCard.Instance.pixelMousePos;
		public static NecroCard.GameState GameState
		{
			[Inline]
			get => NecroCard.Instance.gameState;
			set => NecroCard.Instance.gameState = value;
		}
	}

	static class Draw
	{
		public static Asset<Sprite> cards;
		public static Asset<Sprite> background;
		public static Asset<Sprite> drawButton;
		public static Asset<Sprite> turn;
		public static Asset<Sprite> smallNumbers;
		public static Asset<Sprite> bigNumbers;
		public static Asset<Sprite> restartButton;
		public static Asset<Sprite> menuButton;
		public static Asset<Sprite> endscreen;
		public static Asset<Sprite> hardAIIndicator;
		public static Asset<Sprite> particles;
		public static Asset<Sprite> warning;
		public static Asset<Sprite> menu;
		public static Asset<Sprite> tutorialButton;
		public static Asset<Sprite> playButton;
		public static Asset<Sprite> quitButton;
		public static Asset<Sprite> logo;
		public static Asset<Sprite> backButton;
		public static SpriteFont font;

		internal static void Create()
		{
			cards = new Asset<Sprite>("cards");
			background = new Asset<Sprite>("background");
			drawButton = new Asset<Sprite>("button_draw");
			turn = new Asset<Sprite>("turn");
			smallNumbers = new Asset<Sprite>("small_numbers");
			bigNumbers = new Asset<Sprite>("big_numbers");
			menuButton = new Asset<Sprite>("button_menu");
			restartButton = new Asset<Sprite>("button_restart");
			endscreen = new Asset<Sprite>("endscreen");
			hardAIIndicator = new Asset<Sprite>("hard");
			particles = new Asset<Sprite>("particles");
			warning = new Asset<Sprite>("warning");
			menu = new Asset<Sprite>("menu");
			tutorialButton = new Asset<Sprite>("button_tutorial");
			playButton = new Asset<Sprite>("button_play");
			quitButton = new Asset<Sprite>("button_quit");
			logo = new Asset<Sprite>("logo");
			backButton = new Asset<Sprite>("button_back");

			// just reference
			font = NecroCard.Instance.font;
		}

		internal static void Delete()
		{
			delete cards;
			delete background;
			delete drawButton;
			delete turn;
			delete smallNumbers;
			delete bigNumbers;
			delete menuButton;
			delete restartButton;
			delete endscreen;
			delete hardAIIndicator;
			delete particles;
			delete warning;
			delete menu;
			delete tutorialButton;
			delete playButton;
			delete quitButton;
			delete logo;
			delete backButton;
		}
	}

	[AlwaysInclude]
	public class NecroCard : PixelGame<NecroCard>
	{
		Material material ~ delete _;
		Shader shader ~ delete _;
		public Batch2D batch ~ delete _;
		public bool debugRender;

		AudioClip theme;
		GlobalSource music ~ delete _;

		public SpriteFont font ~ delete _;
		public Board board ~ DeleteNotNull!(_);
		public Menu menu ~ delete _;
		public Point2 pixelMousePos;

		public enum GameState
		{
			Playing,
			GameEnd,
			Menu // includes tutorial, credits, options & play & exit
		}

		public GameState gameState = .Menu;

		public this() : base(.(320, 200))
		{
			Scaling = .FitFrame;
			Core.Assert(Instance != null);
		}

		static this()
		{
			Texture.DefaultTextureFilter = .Nearest;

			EntryPoint.Preferences.createGame = () => new NecroCard();
			EntryPoint.Preferences.gameTitle = "NecroCard";
			EntryPoint.Preferences.windowHeight = 200 * 4;
			EntryPoint.Preferences.windowWidth = 320 * 4;
		}
		
		protected override void Startup()
		{
			base.Startup();

			// LOAD SHADER PACKAGE
			{
				// Shaders are only created once in the beginning in this example, so the source can be release directly after
				Core.Assets.LoadPackage("shaders");
				
				var s = scope ShaderData(Core.Assets.Get<RawAsset>("s_batch2dVert").text, Core.Assets.Get<RawAsset>("s_batch2dFrag").text);

				shader = new Shader(s);

				Core.Assets.UnloadPackage("shaders");
			}

			// LOAD FONTS
			{
				Core.Assets.LoadPackage("fonts");

				let fnt = Core.Assets.Get<Font>("nunito_semibold");
				font = new SpriteFont(fnt, 24, Charsets.ASCII);

				Core.Assets.UnloadPackage("fonts");
			}

			// LOAD CONTENT PACKAGE
			Core.Assets.LoadPackage("content");

			// Music
			theme = Core.Assets.Get<AudioClip>("theme");
			music = new GlobalSource(null, true);
			music.Looping = true;
			if (theme != null) music.Play(theme);

			// SETUP RENDERING STUFF
			material = new Material(shader);
			batch = new Batch2D(material);

			Core.Window.Resizable = true;
			Core.Window.SetTitle("Necro Card");

			Draw.Create();
			menu = new Menu();
		}

		protected override void Shutdown()
		{
			Draw.Delete();
			Core.Assets.UnloadPackage("content");
		}

		protected override void Update()
		{
			pixelMousePos = WindowToFrame(Core.Input.MousePosition);

			if (gameState == .Menu)
				menu.Update();
			else board.Update();

			if (Core.Input.Keyboard.Alt && Core.Input.Keyboard.Pressed(.Enter))
			{
				Core.Window.Fullscreen = !Core.Window.Fullscreen;
			}	

#if DEBUG
			if (Core.Input.Keyboard.Pressed(.F1))
				debugRender = !debugRender;
			if (Core.Input.Keyboard.Pressed(.F3)) // Full reset
			{
				LoadGame();
			}
#endif
		}

		protected override void Render()
		{
			batch.Clear();
			Core.Graphics.Clear(Frame, .Color | .Depth | .Stencil, .Black, 0, 0, Rect(0, 0, Core.Window.RenderSize.X, Core.Window.RenderSize.Y));

			// RENDER TO FRAME
			if (gameState == .Menu)
				menu.Render(batch);
			else board.Render(batch);

			if (DebugRender)
				batch.Rect(.(pixelMousePos, .One), .White);

			batch.Render(Frame);
			batch.Clear();

			// RENDER TO SCREEN
			RenderFrame(batch);

			if (gameState == .Menu)
				menu.RenderHiRes(batch);
			else
				board.RenderHiRes(batch);

			if (debugRender)
				Performance.Render(batch, font);

			//batch.Image(Core.Assets.[Friend]atlas[0]);

			batch.Render(Core.Window, .DarkText);
		}

		public void RestartBoard()
		{
			// Works for now
			delete board;
			board = new Board();
			gameState = .Playing;
		}

		public void LoadGame()
		{
			if (board != null) delete board;
			board = new Board(true);
			gameState = .Playing;
		}

		public void LoadMenu()
		{
			gameState = .Menu;
		}

		public Point2 Center => FrameSize / 2;
	}
}
