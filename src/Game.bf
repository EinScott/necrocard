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

		[Inline]
		public static GlobalSource SoundSource => NecroCard.Instance.sounds;
	}

	static class Sound
	{
		// these could also be assets, but we wont reload them so...
		public static Asset<AudioClip> buttonClick;
		public static Asset<AudioClip> buttonHover;
		public static Asset<AudioClip> cardAttack;
		public static Asset<AudioClip> cardBlock;
		public static Asset<AudioClip> cardHeal;
		public static Asset<AudioClip> cardHover;
		public static Asset<AudioClip> cardPlay;
		public static Asset<AudioClip> cardShuffle;
		public static Asset<AudioClip> cardClick;
		public static Asset<AudioClip> win;

		internal static void Create()
		{
			buttonClick = new Asset<AudioClip>("button_click");
			buttonHover = new Asset<AudioClip>("button_hover");
			cardAttack = new Asset<AudioClip>("card_attack");
			cardBlock = new Asset<AudioClip>("card_block");
			cardHeal = new Asset<AudioClip>("card_heal");
			cardHover = new Asset<AudioClip>("card_hover");
			cardPlay = new Asset<AudioClip>("card_play");
			cardShuffle = new Asset<AudioClip>("card_shuffle");
			cardClick = new Asset<AudioClip>("card_click");
			win = new Asset<AudioClip>("win");
		}

		internal static void Delete()
		{
			delete buttonClick;
			delete buttonHover;
			delete cardAttack;
			delete cardBlock;
			delete cardHeal;
			delete cardHover;
			delete cardPlay;
			delete cardShuffle;
			delete cardClick;
			delete win;
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

	// "a magician's / necromancer's card game?"
	// @do add interactive tutorial "magic rulebook"
	// @do add different ai enemy "personalities"
	// @do add more cards?
	// @do find a way to increase strategic depth
	// @do cleanup some code!
	// @do fool around with multiplayer at some point?
	// @do sound when you leave the board empty
	// @do try drawing 2 cards
	// @do show enemy card count
	// @do draw button sound bug?
	// @do opening animation/sequence, some lore!
	// @do story mode? where there are a row of challengers to beat.

	// @do default ai currently too aggressive
	// @do the option to surrender

	// @do put player behaviour in one player class just like enemy

	/** @do
	(boards) randome effects? - on interval
	number of stuff that was relevant in a move should be made more prominant
	(maybe fly towards the display it changes)
	enemy abilities (commander like)
	card "mode"
	cheaten?
	make start of rounds better "opening"
	fog of war cards
	synergies of cards
	-> activaten takes a turn
	-> or combine cards?
	- maybe tradoff (get less energy back)

	different decks or unique cards per person

	deck building?
	-> if commander style abilities - maybe tie deck to commander

	kek 0 0

	maybe limit decks in some way, (when we have more cards)
	each game should have a limited deck, maybe even the same one
	they could be random, or rely on the commander or something

	Problem: no insentive for more than two cards on the board, also the ai mostly starts trading if you dont
	-> can be solved by some of the stuff here, probably

	have button class? they should probably only focus and play sounds when the window is actually focused!
	*/

	[AlwaysInclude]
	public class NecroCard : PixelGame<NecroCard>
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
			EntryPoint.OnStart.Add(new => OnStart);
		}

		static Result<void> OnStart()
		{
			// This, notably also influences the Assets atlas
			// @do -> that should maybe change in future?
			Texture.DefaultTextureFilter = .Nearest;
			Texture.DefaultTextureGenMipmaps = false;

			EntryPoint.Config = .()
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
				Assets.LoadPackage("fonts");

				let fnt = Assets.Get<Font>("nunito_semibold");
				font = new SpriteFont(fnt, 24, Charsets.ASCII);

				Assets.UnloadPackage("fonts");
			}

			// LOAD CONTENT PACKAGE
			Assets.LoadPackage("content");

			// Music
			theme = Assets.Get<AudioClip>("theme");
			music = new GlobalSource(null, true);
			music.Looping = true;
			music.Play(theme);

			// Sounds
			Sound.Create();
			sounds = new GlobalSource();

			// SETUP RENDERING STUFF
			batch = new Batch2D();

			System.Window.Resizable = true;
			System.Window.OnFocusChanged.Add(new => FocusChanged);
			//Core.Window.SetTitle("Necro Card");

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

			Draw.Delete();
			Sound.Delete();
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
				Perf.Render(batch, font);

				//batch.Rect(.(FrameToWindow(pixelMousePos), .One * 4), .Red);
			}

			//batch.Image(Assets.[Friend]atlas[0]);

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
				debugRender = !debugRender;
			if (Input.Keyboard.Pressed(.F3)) // Full reset
			{
				LoadGame();
			}
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
