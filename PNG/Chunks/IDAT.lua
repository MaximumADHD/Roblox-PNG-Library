local function IDAT(file, chunk)
	local data = chunk.Data
	local buffer = data.Buffer
	file.ZlibStream = file.ZlibStream .. buffer
end

return IDAT