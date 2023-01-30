local modules = script.Parent.Parent.Modules

local Types = require(modules.Types)

local function hIST(_: Types.File, _: Types.Chunk, state: Types.ChunkReaderState)
	assert(table.find(state.FoundChunkType, "IHDR"), "Missing IHDR chunk")
	assert(not table.find(state.FoundChunkType, "IDAT"), "hIST chunk must be before IDAT chunks")
	assert(not table.find(state.FoundChunkType, "hIST"), "There can only be one hIST chunk in a PNG file")

	-- TODO: Implement hIST
	warn("Chunk type 'hIST' is not implemented yet")
end

return hIST
