local function PLTE(file, chunk)
	if not file.Palette then
		file.Palette = {}
	end
	
	local data = chunk.Data
	local palette = data:ReadAllBytes()
	
	if #palette % 3 ~= 0 then
		error("PNG - Invalid PLTE chunk.")
	end
	
	for i = 1, #palette, 3 do
		local r = palette[i]
		local g = palette[i + 1]
		local b = palette[i + 2]
		
		local color = Color3.fromRGB(r, g, b)
		local index = #file.Palette + 1
		
		file.Palette[index] = color
	end
end

return PLTE