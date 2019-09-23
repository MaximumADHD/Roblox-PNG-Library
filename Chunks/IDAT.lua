local function IDAT(file, chunk)
	local crc = chunk.CRC
	local hash = file.Hash or 0
	
	local data = chunk.Data
	local buffer = data.Buffer
	
	file.Hash = bit32.bxor(hash, crc)
	file.ZlibStream = file.ZlibStream .. buffer
end

return IDAT