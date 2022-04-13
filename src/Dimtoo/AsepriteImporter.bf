using Pile;
using System.IO;
using System.Collections;
using System;
using System.Diagnostics;
using Bon;

namespace Dimtoo
{
	[RegisterImporter]
	class AsepriteSpriteImporter : Importer
	{
		public override String Name => "aseprite";

		static StringView[?] ext = .("ase");
		public override Span<StringView> TargetExtensions => ext;

		public override Result<void> Load(StringView name, Span<uint8> data)
		{
			let mem = scope MemoryStream();
			Try!(mem.TryWrite(data));
			mem.Position = 0;

			let ase = scope Aseprite();
			Try!(ase.Parse(mem));

			let frames = scope List<Frame>();
			let frameName = scope String();
			int i = 0;
			for (let frame in ase.Frames)
			{
				// Frame texture name
				frameName.Set(name);
				i.ToString(frameName);
				let subTex = Importer.SubmitLoadedTextureAsset(frameName, frame.Bitmap);

				// Add frame
				frames.Add(Frame(subTex, frame.Duration));
				i++;
			}

			let animations = scope List<(String name, Animation anim)>();
			for (let tag in ase.Tags)
				animations.Add((new String(tag.Name), Animation(tag.From, tag.To)));

			Point2 origin = .Zero;
			for (let slice in ase.Slices)
				if (slice.Name == "origin" && slice.Pivot != null)
				{
					origin = slice.Pivot.Value;
				}

			let asset = new Sprite(frames, animations, origin);
			if (Importer.SubmitLoadedAsset(name, asset) case .Ok)
				return .Ok;
			else
			{
				delete asset;
				return .Err;
			}
		}
	}
}
