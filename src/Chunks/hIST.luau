local modules = script.Parent.Parent.Modules

local Types = require(modules.Types)

local tfind = table.find

local function hIST(_: Types.File, _: Types.Chunk, state: Types.ChunkReaderState)
	assert(tfind(state.FoundChunkType, "IHDR"), "Missing IHDR chunk")
	assert(not tfind(state.FoundChunkType, "IDAT"), "hIST chunk must be before IDAT chunks")
	assert(not tfind(state.FoundChunkType, "hIST"), "There can only be one hIST chunk in a PNG file")

    -- TODO: Implement hIST
	warn("Chunk type 'hIST' is not implemented yet")
end

return hIST