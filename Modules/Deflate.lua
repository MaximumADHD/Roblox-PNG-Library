--[[

LUA MODULE

compress.deflatelua - deflate (and zlib) implemented in Lua.

DESCRIPTION

This is a pure Lua implementation of decompressing the DEFLATE format,
including the related zlib format.

Note: This library only supports decompression.
Compression is not currently implemented.

REFERENCES

[1] DEFLATE Compressed Data Format Specification version 1.3
http://tools.ietf.org/html/rfc1951
[2] GZIP file format specification version 4.3
http://tools.ietf.org/html/rfc1952
[3] http://en.wikipedia.org/wiki/DEFLATE
[4] pyflate, by Paul Sladen
http://www.paul.sladen.org/projects/pyflate/
[5] Compress::Zlib::Perl - partial pure Perl implementation of
Compress::Zlib
http://search.cpan.org/~nwclark/Compress-Zlib-Perl/Perl.pm

LICENSE

(c) 2008-2011 David Manura.  Licensed under the same terms as Lua (MIT).
    Heavily modified by Max G. (2019)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
(end license)
--]]

local Deflate = {}

local band = bit32.band
local lshift = bit32.lshift
local rshift = bit32.rshift

local BTYPE_NO_COMPRESSION = 0
local BTYPE_FIXED_HUFFMAN = 1
local BTYPE_DYNAMIC_HUFFMAN = 2

local lens = -- Size base for length codes 257..285
{
	[0] = 3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 15, 17, 19, 23, 27, 31,
	35, 43, 51, 59, 67, 83, 99, 115, 131, 163, 195, 227, 258
}

local lext = -- Extra bits for length codes 257..285
{
	[0] = 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2,
	3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 0
}

local dists = -- Offset base for distance codes 0..29
{
	[0] = 1, 2, 3, 4, 5, 7, 9, 13, 17, 25, 33, 49, 65, 97, 129, 193,
	257, 385, 513, 769, 1025, 1537, 2049, 3073, 4097, 6145,
	8193, 12289, 16385, 24577
}

local dext = -- Extra bits for distance codes 0..29
{
	[0] = 0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6,
	7, 7, 8, 8, 9, 9, 10, 10, 11, 11,
	12, 12, 13, 13
}

local order = -- Permutation of code length codes
{
	16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 
	11, 4, 12, 3, 13, 2, 14, 1, 15
}

-- Fixed literal table for BTYPE_FIXED_HUFFMAN
local fixedLit = {0, 8, 144, 9, 256, 7, 280, 8, 288}

 -- Fixed distance table for BTYPE_FIXED_HUFFMAN
local fixedDist = {0, 5, 32}

local function createState(bitStream)
	local state = 
	{
		Output = bitStream;
		Window = {};
		Pos = 1;
	}
	
	return state
end

local function write(state, byte)
	local pos = state.Pos
	state.Output(byte)
	state.Window[pos] = byte
	state.Pos = pos % 32768 + 1  -- 32K
end

local function memoize(fn)
	local meta = {}
	local memoizer = setmetatable({}, meta)
	
	function meta:__index(k)
		local v = fn(k)
		memoizer[k] = v
		
		return v
	end
	
	return memoizer
end

-- small optimization (lookup table for powers of 2)
local pow2 = memoize(function (n) 
	return 2 ^ n 
end)

-- weak metatable marking objects as bitstream type
local isBitStream = setmetatable({}, { __mode = 'k' })

local function createBitStream(reader)
	local buffer = 0
	local bitsLeft = 0
	
	local stream = {}
	isBitStream[stream] = true
	
	function stream:GetBitsLeft()
		return bitsLeft
	end
	
	function stream:Read(count)
		count = count or 1
		
		while bitsLeft < count do
			local byte = reader:ReadByte()
			
			if not byte then 
				return 
			end
			
			buffer = buffer + lshift(byte, bitsLeft)
			bitsLeft = bitsLeft + 8
		end
		
		local bits
		
		if count == 0 then
			bits = 0
		elseif count == 32 then
			bits = buffer
			buffer = 0
		else
			bits = band(buffer, rshift(2^32 - 1, 32 - count))
			buffer = rshift(buffer, count)
		end
		
		bitsLeft = bitsLeft - count
		return bits
	end
	
	return stream
end

local function getBitStream(obj)
	if isBitStream[obj] then
		return obj
	end
	
	return createBitStream(obj)
end

local function sortHuffman(a, b)
	return a.NumBits == b.NumBits and a.Value < b.Value or a.NumBits < b.NumBits
end

local function msb(bits, numBits)
	local res = 0
		
	for i = 1, numBits do
		res = lshift(res, 1) + band(bits, 1)
		bits = rshift(bits, 1)
	end
		
	return res
end

local function createHuffmanTable(init, isFull)
	local hTable = {}
	
	if isFull then
		for val, numBits in pairs(init) do
			if numBits ~= 0 then
				hTable[#hTable + 1] = 
				{
					Value = val;
					NumBits = numBits;
				}
			end
		end
	else
		for i = 1, #init - 2, 2 do
			local firstVal = init[i]
			
			local numBits = init[i + 1]
			local nextVal = init[i + 2]
			
			if numBits ~= 0 then
				for val = firstVal, nextVal - 1 do
					hTable[#hTable + 1] = 
					{
						Value = val;
						NumBits = numBits;
					}
				end
			end
		end
	end
	
	table.sort(hTable, sortHuffman)
	
	local code = 1
	local numBits = 0
	
	for i, slide in ipairs(hTable) do
		if slide.NumBits ~= numBits then
			code = code * pow2[slide.NumBits - numBits]
			numBits = slide.NumBits
		end
		
		slide.Code = code
		code = code + 1
	end
	
	local minBits = math.huge
	local look = {}
	
	for i, slide in ipairs(hTable) do
		minBits = math.min(minBits, slide.NumBits)
		look[slide.Code] = slide.Value
	end

	local firstCode = memoize(function (bits) 
		return pow2[minBits] + msb(bits, minBits) 
	end)
	
	function hTable:Read(bitStream)
		local code = 1 -- leading 1 marker
		local numBits = 0
		
		while true do
			if numBits == 0 then  -- small optimization (optional)
				local index = bitStream:Read(minBits)
				numBits = numBits + minBits
				code = firstCode[index]
			else
				local bit = bitStream:Read()
				numBits = numBits + 1
				code = code * 2 + bit -- MSB first
			end
			
			local val = look[code]
			
			if val then
				return val
			end
		end
	end
	
	return hTable
end

local function parseZlibHeader(bitStream)
	-- Compression Method
	local cm = bitStream:Read(4)
	
	-- Compression info
	local cinfo = bitStream:Read(4)  
	
	-- FLaGs: FCHECK (check bits for CMF and FLG)   
	local fcheck = bitStream:Read(5)
	
	-- FLaGs: FDICT (present dictionary)
	local fdict = bitStream:Read(1)
	
	-- FLaGs: FLEVEL (compression level)
	local flevel = bitStream:Read(2)
	
	-- CMF (Compresion Method and flags)
	local cmf = cinfo * 16  + cm
	
	-- FLaGs
	local flg = fcheck + fdict * 32 + flevel * 64 
	
	if cm ~= 8 then -- not "deflate"
		error("unrecognized zlib compression method: " .. cm)
	end
	
	if cinfo > 7 then
		error("invalid zlib window size: cinfo=" .. cinfo)
	end
	
	local windowSize = 2 ^ (cinfo + 8)
	
	if (cmf * 256 + flg) % 31 ~= 0 then
		error("invalid zlib header (bad fcheck sum)")
	end
	
	if fdict == 1 then
		error("FIX:TODO - FDICT not currently implemented")
	end
	
	return windowSize
end

local function parseHuffmanTables(bitStream)
	local numLits  = bitStream:Read(5) -- # of literal/length codes - 257
	local numDists = bitStream:Read(5) -- # of distance codes - 1
	local numCodes = bitStream:Read(4) -- # of code length codes - 4
	
	local codeLens = {}
	
	for i = 1, numCodes + 4 do
		local index = order[i]
		codeLens[index] = bitStream:Read(3)
	end
	
	codeLens = createHuffmanTable(codeLens, true)

	local function decode(numCodes)
		local init = {}
		local numBits
		local val = 0
		
		while val < numCodes do
			local codeLen = codeLens:Read(bitStream)
			local numRepeats
			
			if codeLen <= 15 then
				numRepeats = 1
				numBits = codeLen
			elseif codeLen == 16 then
				numRepeats = 3 + bitStream:Read(2)
			elseif codeLen == 17 then
				numRepeats = 3 + bitStream:Read(3)
				numBits = 0
			elseif codeLen == 18 then
				numRepeats = 11 + bitStream:Read(7)
				numBits = 0
			end
			
			for i = 1, numRepeats do
				init[val] = numBits
				val = val + 1
			end
		end
		
		return createHuffmanTable(init, true)
	end

	local numLitCodes = numLits + 257
	local numDistCodes = numDists + 1
	
	local litTable = decode(numLitCodes)
	local distTable = decode(numDistCodes)
	
	return litTable, distTable
end

local function parseCompressedItem(bitStream, state, litTable, distTable)
	local val = litTable:Read(bitStream)
	
	if val < 256 then -- literal
		write(state, val)
	elseif val == 256 then -- end of block
		return true
	else
		local lenBase = lens[val - 257]
		local numExtraBits = lext[val - 257]
		
		local extraBits = bitStream:Read(numExtraBits)
		local len = lenBase + extraBits
		
		local distVal = distTable:Read(bitStream)
		local distBase = dists[distVal]
		
		local distNumExtraBits = dext[distVal]
		local distExtraBits = bitStream:Read(distNumExtraBits)
		
		local dist = distBase + distExtraBits
		
		for i = 1, len do
			local pos = (state.Pos - 1 - dist) % 32768 + 1
			local byte = assert(state.Window[pos], "invalid distance")
			write(state, byte)
		end
	end
	
	return false
end

local function parseBlock(bitStream, state)
	local bFinal = bitStream:Read(1)
	local bType = bitStream:Read(2)
	
	if bType == BTYPE_NO_COMPRESSION then
		local left = bitStream:GetBitsLeft()
		bitStream:Read(left)
		
		local len = bitStream:Read(16)
		local nlen = bitStream:Read(16)

		for i = 1, len do
			local byte = bitStream:Read(8)
			write(state, byte)
		end
	elseif bType == BTYPE_FIXED_HUFFMAN or bType == BTYPE_DYNAMIC_HUFFMAN then
		local litTable, distTable

		if bType == BTYPE_DYNAMIC_HUFFMAN then
			litTable, distTable = parseHuffmanTables(bitStream)
		else
			litTable = createHuffmanTable(fixedLit)
			distTable = createHuffmanTable(fixedDist)
		end
		
		repeat until parseCompressedItem(bitStream, state, litTable, distTable)
	else
		error("unrecognized compression type")
	end

	return bFinal ~= 0
end

function Deflate:Inflate(io)
	local state = createState(io.Output)
	local bitStream = getBitStream(io.Input)
	
	repeat until parseBlock(bitStream, state)
end

function Deflate:InflateZlib(io)
	local bitStream = getBitStream(io.Input)
	local windowSize = parseZlibHeader(bitStream)
	
	self:Inflate
	{
		Input = bitStream;
		Output = io.Output;
	}
	
	local bitsLeft = bitStream:GetBitsLeft()
	bitStream:Read(bitsLeft)
end

return Deflate