using Pile;
using System;
using System.IO;
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

		[Inline]
		public static GlobalSource SoundSource => NecroCard.Instance.sounds;
	}

	static class Sound
	{
		public static Asset<AudioClip> buttonClick = .("audio/button_click");
		public static Asset<AudioClip> buttonHover = .("audio/button_hover");
		public static Asset<AudioClip> cardAttack = .("audio/card_attack");
		public static Asset<AudioClip> cardBlock = .("audio/card_block");
		public static Asset<AudioClip> cardHeal = .("audio/card_heal");
		public static Asset<AudioClip> cardHover = .("audio/card_hover");
		public static Asset<AudioClip> cardPlay = .("audio/card_play");
		public static Asset<AudioClip> cardShuffle = .("audio/card_shuffle");
		public static Asset<AudioClip> cardClick = .("audio/card_click");
		public static Asset<AudioClip> win = .("audio/win");
	}

	static class Draw
	{
		public static Asset<Sprite> cards = .("sprites/cards");
		public static Asset<Sprite> background = .("sprites/background");
		public static Asset<Sprite> drawButton = .("sprites/button_draw");
		public static Asset<Sprite> turn = .("sprites/turn");
		public static Asset<Sprite> smallNumbers = .("sprites/small_numbers");
		public static Asset<Sprite> bigNumbers = .("sprites/big_numbers");
		public static Asset<Sprite> restartButton = .("sprites/button_restart");
		public static Asset<Sprite> menuButton = .("sprites/button_menu");
		public static Asset<Sprite> endscreen = .("sprites/endscreen");
		public static Asset<Sprite> hardAIIndicator = .("sprites/hard");
		public static Asset<Sprite> particles = .("sprites/particles");
		public static Asset<Sprite> warning = .("sprites/warning");
		public static Asset<Sprite> menu = .("sprites/menu");
		public static Asset<Sprite> tutorialButton = .("sprites/button_tutorial");
		public static Asset<Sprite> playButton = .("sprites/button_play");
		public static Asset<Sprite> quitButton = .("sprites/button_quit");
		public static Asset<Sprite> logo = .("sprites/logo");
		public static Asset<Sprite> backButton = .("sprites/button_back");
		public static SpriteFont font;

		internal static void Create()
		{
			font = NecroCard.Instance.font;
		}
	}

	// add interactive tutorial "magic rulebook"
	// add different ai enemy "personalities"
	// find a way to increase strategic depth
	// sound when you leave the board empty
	// try drawing 2 cards
	// draw button sound bug?

	// default ai currently too aggressive
	// the option to surrender

	// put player behaviour in one player class just like enemy

	/** maybe do...
	(boards) random effects? - on interval
	enemy abilities (commander like)
	card "mode"?
	option to try to cheat??
	make start of rounds better "opening"
	synergies of cards
	-> activaten takes a turn
	-> or combine cards?
	- maybe tradoff (get less energy back)

	"decks"?
	-> if commander style abilities - maybe tie deck to commander

	Problem: no incentive for more than two cards on the board, also the ai mostly starts trading if you dont
	-> can be solved by some of the stuff here, probably

	have button class? they should probably only focus and play sounds when the window is actually focused!
	*/

	[AlwaysInclude]
	class NecroCard : PixelGame<NecroCard>
	{
		public Batch2D batch ~ delete _;
		public bool debugRender;

		AudioClip theme;
		internal GlobalSource music ~ delete _;
		internal GlobalSource sounds ~ delete _;

		public SpriteFont font ~ delete _;
		public Board board ~ DeleteNotNull!(_);
		public Menu menu ~ delete _;
		public Point2 pixelMousePos;
		float actualVolume = 1;

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
			Runtime.Assert(Instance != null);
		}

		static this()
		{
			Core.OnStart.Add(new => OnStart);
		}

		static Result<void> OnStart()
		{
			Core.Defaults.SetupPixelPerfect();

			Core.Config = .()
				{
					createGame = () => new NecroCard(),
					gameTitle = "NecroCard",
					windowTitle = "Necro Card",
					windowHeight = 200 * 4,
					windowWidth = 320 * 4,
					windowState = .Windowed
				};

			return .Ok;
		}
		
		protected override void Startup()
		{
			base.Startup();

			// LOAD FONTS
			{
				// Provided by Dimtoo!
				Assets.LoadPackage("font");

				let fnt = Assets.Get<Font>("nunito_semibold");
				font = new SpriteFont(fnt, 24, Charsets.ASCII);

				Assets.UnloadPackage("font");
			}

			// LOAD CONTENT PACKAGE
			Assets.LoadPackage("content");

			// Music
			theme = Assets.Get<AudioClip>("audio/theme");
			music = new GlobalSource(null, true);
			music.Looping = true;
			music.Play(theme);

			// Sounds
			sounds = new GlobalSource();

			// SETUP RENDERING STUFF
			batch = new Batch2D();

			System.Window.Resizable = true;
			System.Window.OnFocusChanged.Add(new => FocusChanged);

			Draw.Create();
			menu = new Menu();

			Perf.Track = true;
		}

		void FocusChanged()
		{
			if (!System.Window.Focus)
			{
				actualVolume = music.Volume;
				music.Volume = 0;
			}
			else music.Volume = actualVolume;
		}

		protected override void Shutdown()
		{
			System.Window.OnFocusChanged.Remove(scope => FocusChanged, true);

			Assets.UnloadPackage("content");
		}

		[PerfTrack]
		protected override void Render()
		{
			batch.Clear();
			Graphics.Clear(Frame, .Color | .Depth | .Stencil, .Black, 0, 0, Rect(0, 0, System.Window.RenderSize.X, System.Window.RenderSize.Y));

			// RENDER TO FRAME
			if (gameState == .Menu)
				menu.Render(batch);
			else board.Render(batch);

			if (debugRender)
				batch.Rect(.(pixelMousePos, .One), .White);

			batch.Render(Frame);
			batch.Clear();

			// RENDER TO SCREEN
			RenderFrame(batch);

			if (gameState == .Menu)
				menu.RenderHiRes(batch);
			else
				board.RenderHiRes(batch);

			//batch.TextMixed(font, "Card: {0}{{", .Zero, .White, Draw.cards.Asset.Frames[0].Texture);

			if (debugRender)
			{
				batch.Image(Assets.[Friend]atlas[0]);
				DevConsole.Render(batch, font, .(.(0, (.)System.Window.RenderSize.Y / 2), .(System.Window.RenderSize.X, System.Window.RenderSize.Y / 2)));

				Perf.Render(batch, font);

				batch.Rect(.(FrameToWindow(pixelMousePos), .One * 4), .Red);
			}


			batch.Render(System.Window, .DarkText);
		}

		[PerfTrack]
		protected override void Update()
		{
			pixelMousePos = WindowToFrame(Input.MousePosition);

			if (gameState == .Menu)
				menu.Update();
			else board.Update();

			if (Input.Keyboard.Alt && Input.Keyboard.Pressed(.Enter))
			{
				System.Window.Fullscreen = !System.Window.Fullscreen;
			}	

#if DEBUG
			if (Input.Keyboard.Pressed(.F1))
			{
				DevConsole.ForceFocus();
				debugRender = !debugRender;
			}	
			if (Input.Keyboard.Pressed(.F3)) // Full reset
			{
				LoadGame();
			}
			if (Input.Keyboard.Pressed(.F4))
			{
				System.TakeScreenshot(); // This crashes right now... will need to fix
			}

			if (DebugRender)
				DevConsole.Update();
#endif
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