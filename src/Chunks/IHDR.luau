local modules = script.Parent.Parent.Modules

local Types = require(modules.Types)

local function IHDR(file: Types.File, chunk: Types.Chunk)
	local data = chunk.Data
	
	file.Width = data:ReadInt32();
	file.Height = data:ReadInt32();
	
	file.BitDepth = data:ReadByte();
	file.ColorType = data:ReadByte();
	
	file.Methods =
	{
		Compression = data:ReadByte();
		Filtering   = data:ReadByte();
		Interlace   = data:ReadByte();
	}
end

return IHDR