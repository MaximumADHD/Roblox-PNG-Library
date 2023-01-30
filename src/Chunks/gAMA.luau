local modules = script.Parent.Parent.Modules

local Types = require(modules.Types)

local function gAMA(file: Types.File, chunk: Types.Chunk, state: Types.ChunkReaderState)
	assert(table.find(state.FoundChunkType, "IHDR"), "Missing IHDR chunk")
	assert(not table.find(state.FoundChunkType, "IDAT"), "gAMA chunk must be before IDAT chunks")
	assert(not table.find(state.FoundChunkType, "gAMA"), "There can only be one gAMA chunk in a PNG file")

	local data = chunk.Data
	local value = data:ReadUInt32()
	file.Gamma = value / 10e4
end

return gAMA
