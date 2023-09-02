--!native

local modules = script.Parent.Parent.Modules

local Types = require(modules.Types)

local colors = { "White", "Red", "Green", "Blue" }

local function cHRM(file: Types.File, chunk: Types.Chunk, state: Types.ChunkReaderState)
	assert(table.find(state.FoundChunkType, "IHDR"), "Missing IHDR chunk")
	assert(not table.find(state.FoundChunkType, "IDAT"), "cHRM chunk must be before IDAT chunks")
	assert(not table.find(state.FoundChunkType, "cHRM"), "There can only be one cHRM chunk in a PNG file")

	local chrome: { [Types.ChromaticityColor]: { number } } = {}
	local data = chunk.Data

	for i = 1, 4 do
		local color = colors[i]

		chrome[color] = {
			[1] = data:ReadUInt32() / 10e4,
			[2] = data:ReadUInt32() / 10e4,
		}
	end

	file.Chromaticity = chrome
end

return cHRM
