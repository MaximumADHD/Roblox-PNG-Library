--!native

local modules = script.Parent.Parent.Modules

local Types = require(modules.Types)

-- This one is undocumented...

local function sRGB(file: Types.File, chunk: Types.Chunk, state: Types.ChunkReaderState)
	assert(table.find(state.FoundChunkType, "IHDR"), "Missing IHDR chunk")
	assert(not table.find(state.FoundChunkType, "sRGB"), "There can only be one sRGB chunk in a PNG file")

	local data = chunk.Data
	file.RenderIntent = data:ReadByte()
end

return sRGB
