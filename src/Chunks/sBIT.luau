local modules = script.Parent.Parent.Modules

local Types = require(modules.Types)

local tfind = table.find

local function sBIT(_: Types.File, _: Types.Chunk, state: Types.ChunkReaderState)
	assert(tfind(state.FoundChunkType, "IHDR"), "Missing IHDR chunk")
	assert(not tfind(state.FoundChunkType, "IDAT"), "sBIT chunk must be before IDAT chunks")

	-- TODO: Implement sBIT
	warn("Chunk type 'sBIT' is not implemented yet")
end

return sBIT
