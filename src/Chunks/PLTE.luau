local modules = script.Parent.Parent.Modules

local Types = require(modules.Types)

local c3FromRGB = Color3.fromRGB

local function PLTE(file: Types.File, chunk: Types.Chunk, state: Types.ChunkReaderState)
	assert(table.find(state.FoundChunkType, "IHDR"), "Missing IHDR chunk")
	assert(not table.find(state.FoundChunkType, "PLTE"), "There can only be one PLTE chunk in a PNG file")
	assert(not table.find(state.FoundChunkType, "IDAT"), "PLTE chunk must be before IDAT chunks")
	assert(not table.find(state.FoundChunkType, "bKGD"), "PLTE chunk must be before bKGD chunk")
	assert(not table.find(state.FoundChunkType, "hIST"), "PLTE chunk must be before hIST chunk")
	assert(not table.find(state.FoundChunkType, "tRNS"), "PLTE chunk must be before tRNS chunk")

	file.Palette = file.Palette or {}

	local data = chunk.Data
	local palette = data:ReadAllBytes()

	if #palette % 3 ~= 0 then
		error("PNG - Invalid PLTE chunk.")
	end

	for i = 1, #palette, 3 do
		local r = palette[i]
		local g = palette[i + 1]
		local b = palette[i + 2]

		local color = c3FromRGB(r, g, b)
		local index = #(file.Palette :: { Color3 }) + 1;

		(file.Palette :: { Color3 })[index] = color
	end
end

return PLTE
