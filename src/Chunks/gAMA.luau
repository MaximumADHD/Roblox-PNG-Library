local modules = script.Parent.Parent.Modules

local Types = require(modules.Types)

local tfind = table.find

local function gAMA(file: Types.File, chunk: Types.Chunk, state: Types.ChunkReaderState)
	assert(not tfind(state.FoundChunkType, "IHDR"), "Missing IHDR chunk")
	assert(not tfind(state.FoundChunkType, "IDAT"), "gAMA chunk must be before IDAT chunks")
	assert(not tfind(state.FoundChunkType, "gAMA"), "There can only be one gAMA chunk in a PNG file")

	local data = chunk.Data
	local value = data:ReadUInt32()
	file.Gamma = value / 10e4
end

return gAMA