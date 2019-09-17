local function tEXt(file, chunk)
	local data = chunk.Data
	local key, value = "", ""
	
	for byte in data:IterateBytes() do
		local char = string.char(byte)
		
		if char == '\0' then
			key = value
			value = ""
		else
			value = value .. char
		end
	end
	
	file.Metadata[key] = value
end

return tEXt