---------------------------------------------------------------------------------------------
-- @ CloneTrooper1019, 2019
---------------------------------------------------------------------------------------------
-- [PNG Library]
--
--  A module for opening PNG files into a readable bitmap.
--  This implementation works with most PNG files.
--
---------------------------------------------------------------------------------------------

local PNG = {}
PNG.__index = PNG

local Unfilter = require(script:WaitForChild("Unfilter"))
local LibDeflate = require(script:WaitForChild("LibDeflate"))
local BinaryReader = require(script:WaitForChild("BinaryReader"))

local function getBytesPerPixel(colorType)
	if colorType == 0 or colorType == 3 then
		return 1
	elseif colorType == 4 then
		return 2
	elseif colorType == 2 then
		return 3
	elseif colorType == 6 then
		return 4
	else
		return 0
	end
end

local function clampInt(value, min, max)
	local num = tonumber(value) or 0
	num = math.floor(num + .5)
	
	return math.clamp(num, min, max)
end

local function indexBitmap(file, x, y)
	local width = file.Width
	local height = file.Height
	
	local x = clampInt(x, 1, width) 
	local y = clampInt(y, 1, height)
	
	local bitmap = file.Bitmap
	local bpp = file.BytesPerPixel
	
	local i0 = ((x - 1) * bpp) + 1
	local i1 = i0 + bpp
	
	return bitmap[y], i0, i1
end

function PNG:GetPixel(x, y)
	local row, i0, i1 = indexBitmap(self, x, y)
	local colorType = self.ColorType
	
	local color, alpha do
		if colorType == 0 then
			local gray = unpack(row, i0, i1)
			color = Color3.fromHSV(0, 0, gray)
			alpha = 255
		elseif colorType == 2 then
			local r, g, b = unpack(row, i0, i1)
			color = Color3.fromRGB(r, g, b)
			alpha = 255
		elseif colorType == 3 then
			local palette = self.Palette
			local alphaData = self.AlphaData
			
			local index = unpack(row, i0, i1)
			index = index + 1
			
			if palette then
				color = palette[index]
			end
			
			if alphaData then
				alpha = alphaData[index]
			end
		elseif colorType == 4 then
			local gray, a = unpack(row, i0, i1)
			color = Color3.fromHSV(0, 0, gray)
			alpha = a
		elseif colorType == 6 then
			local r, g, b, a = unpack(row, i0, i1)
			color = Color3.fromRGB(r, g, b, a)
			alpha = a
		end
	end
	
	if not color then
		color = Color3.new()
	end
	
	if not alpha then
		alpha = 255
	end
	
	return color, alpha
end

function PNG.new(buffer)
	-- Create the reader.
	local reader = BinaryReader.new(buffer)
	
	-- Create the file object.
	local file =
	{
		Chunks = {};
		Metadata = {};
		
		Reading = true;
		ZlibStream = "";
	}
	
	-- Verify the file header.
	local header = reader:ReadString(8)
	
	if header ~= "\137PNG\r\n\26\n" then
		error("PNG - Input data is not a PNG file.", 2)
	end
	
	-- Read the file chunks.
	local chunks = script:WaitForChild("Chunks")

	while file.Reading do
		local length = reader:ReadInt32()
		local chunkType = reader:ReadString(4)
		
		local data, crc
		
		if length > 0 then
			data = reader:ForkReader(length)
			crc = reader:ReadUInt32()
		end
		
		local chunk = 
		{
			Length = length;
			Type = chunkType;
			
			Data = data;
			CRC = crc;
		}
		
		local handler = chunks:FindFirstChild(chunkType)
		
		if handler then
			handler = require(handler)
			handler(file, chunk)
		end
		
		table.insert(file.Chunks, chunk)
	end
	
	-- Decompress the zlib stream.
	local compressed = file.ZlibStream
	local response, status = LibDeflate:DecompressZlib(compressed)
	
	if not response then
		error("PNG - Unable to unpack PNG data. Error Code: " .. tostring(status), 2)
	end
	
	-- Load some info about the data.
	local width = file.Width
	local height = file.Height
	
	local bitDepth = file.BitDepth
	local colorType = file.ColorType
	
	local buffer = BinaryReader.new(response)
	file.ZlibStream = nil
	
	local bitmap = {}
	file.Bitmap = bitmap
	
	local channels = getBytesPerPixel(colorType)
	file.NumChannels = channels
	
	local bpp = math.max(1, channels * (bitDepth / 8))
	file.BytesPerPixel = bpp
	
	-- Unfilter the buffer and 
	-- load it into the bitmap.
	
	for row = 1, height do	
		local filterType = buffer:ReadByte()
		local scanline = buffer:ReadBytes(width * bpp, true)
		
		bitmap[row] = {}
		
		if filterType == 0 then
			-- None
			Unfilter:None    (scanline, bitmap, bpp, row)
		elseif filterType == 1 then
			-- Sub
			Unfilter:Sub     (scanline, bitmap, bpp, row)
		elseif filterType == 2 then
			-- Up
			Unfilter:Up      (scanline, bitmap, bpp, row)
		elseif filterType == 3 then
			-- Average
			Unfilter:Average (scanline, bitmap, bpp, row)
		elseif filterType == 4 then
			-- Paeth
			Unfilter:Paeth   (scanline, bitmap, bpp, row)
		end
	end
	
	return setmetatable(file, PNG)
end

return PNG