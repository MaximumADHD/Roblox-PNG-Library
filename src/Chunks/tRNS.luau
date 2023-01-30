local modules = script.Parent.Parent.Modules

local Types = require(modules.Types)

local tfind = table.find
local c3FromRGB = Color3.fromRGB

local function tRNS(file: Types.File, chunk: Types.Chunk, state: Types.ChunkReaderState)
	assert(tfind(state.FoundChunkType, "IHDR"), "Missing IHDR chunk")
	assert(not tfind(state.FoundChunkType, "IDAT"), "tRNS chunk must be before IDAT chunks")
	assert(not tfind(state.FoundChunkType, "tRNS"), "There can only be one tRNS chunk in a PNG file")

	local data = chunk.Data
	
	local bitDepth = file.BitDepth
	local colorType = file.ColorType
	
	bitDepth = (2 ^ bitDepth) - 1
	
	if colorType == 3 then
		local palette = file.Palette
		local alphaMap = {}
		
		for i = 1, #palette do
			local alpha = data:ReadByte()
			
			if not alpha then
				alpha = 255
			end
			
			alphaMap[i] = alpha
		end
		
		file.AlphaData = alphaMap
	elseif colorType == 0 then
		local grayAlpha = data:ReadUInt16()
		file.Alpha = grayAlpha / bitDepth
	elseif colorType == 2 then
		local r = data:ReadUInt16() / bitDepth
		local g = data:ReadUInt16() / bitDepth
		local b = data:ReadUInt16() / bitDepth
		file.Alpha = c3FromRGB(r, g, b)
	else
		error("Invalid tRNS chunk")
	end	
end

return tRNS