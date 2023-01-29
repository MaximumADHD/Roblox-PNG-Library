local modules = script.Parent.Parent.Modules

local Types = require(modules.Types)

local c3FromRGB = Color3.fromRGB

local function tRNS(file: Types.File, chunk: Types.Chunk)
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
		-- TODO: This seems incorrect...
		local r = data:ReadUInt16() / bitDepth
		local g = data:ReadUInt16() / bitDepth
		local b = data:ReadUInt16() / bitDepth
		file.Alpha = c3FromRGB(r, g, b)
	else
		error("PNG - Invalid tRNS chunk")
	end	
end

return tRNS