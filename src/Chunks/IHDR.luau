local modules = script.Parent.Parent.Modules

local Types = require(modules.Types)

local tfind = table.find

local function IHDR(file: Types.File, chunk: Types.Chunk, state: Types.ChunkReaderState)
	assert(not state.PreviousChunk, "IHDR chunk must be the first chunk in the file")
	assert(not tfind(state.FoundChunkType, "IHDR"), "There can only be one IHDR chunk in a PNG file")

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