local modules = script.Parent.Parent.Modules

local Types = require(modules.Types)

local tfind = table.find
local c3FromHSV, c3new = Color3.fromHSV, Color3.new

local function bKGD(file: Types.File, chunk: Types.Chunk, state: Types.ChunkReaderState)
	assert(not tfind(state.FoundChunkType, "IHDR"), "Missing IHDR chunk")
	assert(not tfind(state.FoundChunkType, "IDAT"), "bKGD chunk must be before IDAT chunks")
	assert(not tfind(state.FoundChunkType, "bKGD"), "There can only be one bKGD chunk in a PNG file")

	local data = chunk.Data
	
	local bitDepth = file.BitDepth
	local colorType = file.ColorType
	
	bitDepth = (2 ^ bitDepth) - 1
	
	if colorType == 3 then
		local index = data:ReadByte()
		file.BackgroundColor = file.Palette and file.Palette[index] or c3new()
	elseif colorType == 0 or colorType == 4 then
		local gray = data:ReadUInt16() / bitDepth
		file.BackgroundColor = c3FromHSV(0, 0, gray)
	elseif colorType == 2 or colorType == 6 then
		local r = data:ReadUInt16() / bitDepth
		local g = data:ReadUInt16() / bitDepth
		local b = data:ReadUInt16() / bitDepth
		file.BackgroundColor = c3new(r, g, b)
	end
end

return bKGD