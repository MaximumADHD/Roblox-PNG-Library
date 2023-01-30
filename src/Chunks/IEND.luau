local modules = script.Parent.Parent.Modules

local Types = require(modules.Types)

local tfind = table.find

local function IEND(file: Types.File, _, state: Types.ChunkReaderState)
	assert(tfind(state.FoundChunkType, "IHDR"), "IHDR chunk must be the first chunk in the file")
	assert(tfind(state.FoundChunkType, "IDAT"), "IDAT chunks does not exist")
	assert(not tfind(state.FoundChunkType, "IEND"), "There can only be one IEND chunk in a PNG file")

	file.Reading = false
end

return IEND