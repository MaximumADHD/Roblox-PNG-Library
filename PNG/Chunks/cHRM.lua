local colors = {"White", "Red", "Green", "Blue"}

local function cHRM(file, chunk)
	local chrome = {}
	local data = chunk.Data
	
	for i = 1, 4 do
		local color = colors[i]
		
		chrome[color] =
		{
			[1] = data:ReadUInt32() / 10e4;
			[2] = data:ReadUInt32() / 10e4;
		}
	end
	
	file.Chromaticity = chrome
end

return cHRM