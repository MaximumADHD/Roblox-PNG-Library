local modules = script.Parent.Parent.Modules

local Types = require(modules.Types)

-- This one is undocumented...

local tfind = table.find

local function sRGB(file: Types.File, chunk: Types.Chunk, state: Types.ChunkReaderState)
	assert(tfind(state.FoundChunkType, "IHDR"), "Missing IHDR chunk")
	assert(not tfind(state.FoundChunkType, "sRGB"), "There can only be one sRGB chunk in a PNG file")

	local data = chunk.Data
	file.RenderIntent = data:ReadByte()
end

return sRGB
