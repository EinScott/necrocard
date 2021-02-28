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
		[Inline]
		public static bool DebugRender => NecroCard.Instance.debugRender;
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
		public Board board ~ delete _;
		public Point2 pixelMousePos;

		public enum GameState
		{
			Playing,
			GameEnd,
			Menu // includes tutorial, credits, options & play & exit
		}

		public GameState gameState = .Playing; // @do change when menu is done, also check for this in update and render

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
				font = new SpriteFont(fnt, 50, Charsets.ASCII);

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
			Core.Window.VSync = false;

			Draw.Create();
			board = new Board();
		}

		protected override void Shutdown()
		{
			Draw.Delete();
			Core.Assets.UnloadPackage("content");
		}

		protected override void Update()
		{
			pixelMousePos = WindowToFrame(Core.Input.MousePosition);

			board.Update();

#if DEBUG
			if (Core.Input.Keyboard.Pressed(.F1))
				debugRender = !debugRender;
			if (Core.Input.Keyboard.Pressed(.F3)) // Full reset
			{
				delete board;
				board = new Board();
			}
#endif
		}

		protected override void Render()
		{
			batch.Clear();
			Core.Graphics.Clear(Frame, .Color | .Depth | .Stencil, .Black, 0, 0, Rect(0, 0, Core.Window.RenderSize.X, Core.Window.RenderSize.Y));

			// RENDER TO FRAME
			board.Render(batch);

			if (DebugRender)
				batch.Rect(.(pixelMousePos, .One), .White);

			batch.Render(Frame);
			batch.Clear();

			// RENDER TO SCREEN
			RenderFrame(batch);
			board.RenderHiRes(batch);

			if (debugRender)
				Performance.Render(batch, font);

			batch.Render(Core.Window, .Black);
		}

		public void RestartBoard()
		{
			// Works for now
			delete board;
			board = new Board();
			gameState = .Playing;
		}

		public void LoadMenu()
		{
			Log.Debug("MENU");
		}

		public Point2 Center => FrameSize / 2;
	}
}
