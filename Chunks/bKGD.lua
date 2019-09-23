local function bKGD(file, chunk)
	local data = chunk.Data
	
	local bitDepth = file.BitDepth
	local colorType = file.ColorType
	
	bitDepth = (2 ^ bitDepth) - 1
	
	if colorType == 3 then
		local index = data:ReadByte()
		file.BackgroundColor = file.Palette[index]
	elseif colorType == 0 or colorType == 4 then
		local gray = data:ReadUInt16() / bitDepth
		file.BackgroundColor = Color3.fromHSV(0, 0, gray)
	elseif colorType == 2 or colorType == 6 then
		local r = data:ReadUInt16() / bitDepth
		local g = data:ReadUInt16() / bitDepth
		local b = data:ReadUInt16() / bitDepth
		file.BackgroundColor = Color3.new(r, g, b)
	end
end

return bKGD