local modules = script.Parent.Parent.Modules

local Types = require(modules.Types)

local c3FromRGB = Color3.fromRGB

local function PLTE(file: Types.File, chunk: Types.Chunk)
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
		local index = #(file.Palette :: { Color3 }) + 1
		
		(file.Palette :: { Color3 })[index] = color
	end
end

return PLTE