---------------------------------------------------------------------------------------------
-- @ CloneTrooper1019, 2019
---------------------------------------------------------------------------------------------
-- [PNG Library]
--
--  A module for opening PNG files into a readable bitmap.
--  This implementation works with most PNG files.
--
---------------------------------------------------------------------------------------------

local chunks = script.Chunks
local modules = script.Modules

local Types = require(modules.Types)
local Deflate = require(modules.Deflate)
local Unfilter = require(modules.Unfilter)
local BinaryReader = require(modules.BinaryReader)

local schar = string.char
local tconcat, tinsert = table.concat, table.insert
local c3FromHSV, c3FromRGB = Color3.fromHSV, Color3.fromRGB
local mmax, mfloor, mclamp = math.max, math.floor, math.clamp

local CachedChunkHandler: { [string]: (file: Types.File, chunk: Types.Chunk) -> () } = {}

for _, chunkHandler in ipairs(chunks:GetChildren()) do
	CachedChunkHandler[chunkHandler.Name] = require(chunkHandler)
end

local PNG = {}
PNG.__index = PNG

local function getBytesPerPixel(colorType: number): number
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

local function clampInt(value: number, min: number, max: number): number
	local num = tonumber(value) or 0
	num = mfloor(num + .5)
	
	return mclamp(num, min, max)
end

local function indexBitmap(file: Types.File, x: number, y: number)
	local width = file.Width or 0
	local height = file.Height or 0
	
	local x = clampInt(x, 1, width) 
	local y = clampInt(y, 1, height)
	
	local bitmap = file.Bitmap
	local bpp = file.BytesPerPixel or 1
	
	local i0 = ((x - 1) * bpp) + 1
	local i1 = i0 + bpp
	
	return bitmap[y], i0, i1
end

function PNG:GetPixel(x: number, y: number): (Color3, number)
	local row, i0, i1 = indexBitmap(self, x, y)
	local colorType = self.ColorType or -1
	
	local color, alpha
	
	do
		if colorType == 0 then
			local gray = unpack(row, i0, i1)
			color = c3FromHSV(0, 0, gray)
			alpha = 255
		elseif colorType == 2 then
			local r, g, b = unpack(row, i0, i1)
			color = c3FromRGB(r, g, b)
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
			color = c3FromHSV(0, 0, gray)
			alpha = a
		elseif colorType == 6 then
			local r, g, b, a = unpack(row, i0, i1)
			color = c3FromRGB(r, g, b, a)
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

function PNG.new(buffer): typeof(setmetatable({} :: Types.File, PNG))
	-- Create the reader.
	local reader = BinaryReader.new(buffer)
	
	-- Create the file object.
	local file: Types.File =
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
	
	while file.Reading do
		local length = reader:ReadInt32()
		local chunkType = reader:ReadString(4)
		
		local data, crc
		
		if length > 0 then
			data = reader:ForkReader(length)
			crc = reader:ReadUInt32()
		end
		
		local chunk: Types.Chunk = 
		{
			Length = length;
			Type = chunkType;
			
			Data = data;
			CRC = crc;
		}
		
		local handler = CachedChunkHandler[chunkType]
		
		if handler then
			handler(file, chunk)
		end
		
		tinsert(file.Chunks, chunk)
	end
	
	-- Decompress the zlib stream.
	local success, response = pcall(function()
		local result = {}
		local index = 0
		
		Deflate:InflateZlib
		{
			Input = BinaryReader.new(file.ZlibStream or "");
			
			Output = function (byte)
				index = index + 1
				result[index] = schar(byte)
			end
		}
		
		return tconcat(result)
	end)
	
	if not success then
		error("PNG - Unable to unpack PNG data. " .. tostring(response), 2)
	end

	file.ZlibStream = nil
	
	-- Grab expected info from the file.
	
	local width = file.Width
	local height = file.Height
	
	local bitDepth = file.BitDepth
	local colorType = file.ColorType
	
	local buffer = BinaryReader.new(response)
	
	local bitmap = file.Bitmap
	
	local channels = getBytesPerPixel(colorType)
	file.NumChannels = channels
	
	local bpp = mmax(1, channels * (bitDepth / 8))
	file.BytesPerPixel = bpp
	
	-- Unfilter the buffer and 
	-- load it into the bitmap.
	
	for row = 1, height do
		local filterType = buffer:ReadByte()
		local scanline = buffer:ReadBytes(width * bpp)
		
		bitmap[row] = {}
		
		if filterType == 0 then
			-- None
			Unfilter.None(scanline, bitmap, bpp, row)
		elseif filterType == 1 then
			-- Sub
			Unfilter.Sub(scanline, bitmap, bpp, row)
		elseif filterType == 2 then
			-- Up
			Unfilter.Up(scanline, bitmap, bpp, row)
		elseif filterType == 3 then
			-- Average
			Unfilter.Average(scanline, bitmap, bpp, row)
		elseif filterType == 4 then
			-- Paeth
			Unfilter.Paeth(scanline, bitmap, bpp, row)
		end
	end
	
	return setmetatable(file, PNG)
end

return PNG