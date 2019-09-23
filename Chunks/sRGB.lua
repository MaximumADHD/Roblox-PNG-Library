local function sRGB(file, chunk)
	local data = chunk.Data
	file.RenderIntent = data:ReadByte()
end

return sRGB