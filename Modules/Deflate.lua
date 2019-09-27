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

local Deflate = 
{
	_TYPE = 'module', 
	_NAME = 'compress.deflatelua', 
	_VERSION = '0.3.20111128'
}

local math_max = math.max
local table_sort = table.sort
local string_char = string.char

local band = bit32.band
local lshift = bit32.lshift
local rshift = bit32.rshift

local BTYPE_NO_COMPRESSION = 0
local BTYPE_FIXED_HUFFMAN = 1
local BTYPE_DYNAMIC_HUFFMAN = 2
local BTYPE_RESERVED_ = 3

local codelen_vals = {16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15}

local function make_outstate(outbs)
	local outstate = 
	{
		outbs = outbs;
		window = {};
		window_pos = 1;
	}
	
	return outstate
end

local function output(outstate, byte)
	local window_pos = outstate.window_pos
	outstate.outbs(byte)
	outstate.window[window_pos] = byte
	outstate.window_pos = window_pos % 32768 + 1  -- 32K
end

local function noeof(val)
	return assert(val, 'unexpected end of file')
end

local function hasbit(bits, bit)
	return bits % (bit + bit) >= bit
end

local function memoize(f)
	local mt = {}
	local t = setmetatable({}, mt)
	
	function mt:__index(k)
		local v = f(k)
		t[k] = v
		
		return v
	end
	
	return t
end

-- small optimization (lookup table for powers of 2)
local pow2 = memoize(function (n) 
	return 2 ^ n 
end)

-- weak metatable marking objects as bitstream type
local is_bitstream = setmetatable({}, { __mode = 'k' })

local function bytestream_from_string(s)
	local i = 1
	local o = {}
	
	function o:read()
		local by
		
		if i <= #s then
			by = s:byte(i)
			i = i + 1
		end
		
		return by
	end
	
	return o
end

local function bytestream_from_function(f)
	local i = 0
	local buffer = ''
	local o = {}
	
	function o:read()
		i = i + 1
		
		if i > #buffer then
			buffer = f()
			
			if not buffer then 
				return
			end
			
			i = 1
		end
		
		return buffer:byte(i, i)
	end
	
	return o
end

local function bitstream_from_bytestream(bys)
	local buf_byte = 0
	local buf_nbit = 0
	
	local o = {}
	is_bitstream[o] = true
	
	function o:nbits_left_in_byte()
		return buf_nbit
	end
	
	function o:read(nbits)
		nbits = nbits or 1
		
		while buf_nbit < nbits do
			local byte = bys:read()
			
			if not byte then 
				return 
			end
			
			buf_byte = buf_byte + lshift(byte, buf_nbit)
			buf_nbit = buf_nbit + 8
		end
		
		local bits
		
		if nbits == 0 then
			bits = 0
		elseif nbits == 32 then
			bits = buf_byte
			buf_byte = 0
		else
			bits = band(buf_byte, rshift(0xffffffff, 32 - nbits))
			buf_byte = rshift(buf_byte, nbits)
		end
		
		buf_nbit = buf_nbit - nbits
		return bits
	end
	
	return o
end


local function get_bitstream(o)
	if is_bitstream[o] then
		return o
	end
	
	local byteStream
	
	if type(o) == "string" then
		byteStream = bytestream_from_string(o)
	elseif type(o) == "function" then
		byteStream = bytestream_from_function(o)
	end
	
	return bitstream_from_bytestream(byteStream)
end

local function HuffmanTable(init, isFull)
	local t = {}
	
	if isFull then
		for val, nbits in pairs(init) do
			if nbits ~= 0 then
				t[#t + 1] = 
				{
					val = val;
					nbits = nbits;
				}
			end
		end
	else
		for i = 1, #init - 2, 2 do
			local firstVal = init[i]
			local nbits = init[i + 1]
			local nextVal = init[i + 2]
			
			if nbits ~= 0 then
				for val = firstVal, nextVal - 1 do
					t[#t + 1] = 
					{
						val = val;
						nbits = nbits;
					}
				end
			end
		end
	end
	
	table_sort(t, function(a, b)
		return a.nbits == b.nbits and a.val < b.val or a.nbits < b.nbits
	end)
	
	local code = 1
	local nbits = 0
	
	for i, s in ipairs(t) do
		if s.nbits ~= nbits then
			code = code * pow2[s.nbits - nbits]
			nbits = s.nbits
		end
		
		s.code = code
		code = code + 1
	end
	
	local minbits = math.huge
	local look = {}
	
	for i, s in ipairs(t) do
		minbits = math.min(minbits, s.nbits)
		look[s.code] = s.val
	end
	
	local function msb(bits, nbits)
		local res = 0
		
		for i=1,nbits do
			res = lshift(res, 1) + band(bits, 1)
			bits = rshift(bits, 1)
		end
		
		return res
	end

	local tFirstCode = memoize(function (bits) 
		return pow2[minbits] + msb(bits, minbits) 
	end)

	function t:read(bs)
		local code = 1 -- leading 1 marker
		local nbits = 0
		
		while true do
			if nbits == 0 then  -- small optimization (optional)
				code = tFirstCode[noeof(bs:read(minbits))]
				nbits = nbits + minbits
			else
				local b = noeof(bs:read())
				nbits = nbits + 1
				code = code * 2 + b   -- MSB first
			end
			
			local val = look[code]
			
			if val then
				return val
			end
		end
	end
	
	return t
end

local function parse_zlib_header(bs)
	-- Compression Method
	local cm = bs:read(4)
	
	-- Compression info
	local cinfo = bs:read(4)  
	
	-- FLaGs: FCHECK (check bits for CMF and FLG)   
	local fcheck = bs:read(5)
	
	-- FLaGs: FDICT (present dictionary)
	local fdict = bs:read(1)
	
	-- FLaGs: FLEVEL (compression level)
	local flevel = bs:read(2)
	
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
	
	local window_size = 2^(cinfo + 8)
	
	if (cmf*256 + flg) %  31 ~= 0 then
		error("invalid zlib header (bad fcheck sum)")
	end
	
	if fdict == 1 then
		error("FIX:TODO - FDICT not currently implemented")
	end
	
	return window_size
end

local function parse_huffmantables(bs)
	local hlit = bs:read(5)  -- # of literal/length codes - 257
	local hdist = bs:read(5) -- # of distance codes - 1
	local hclen = noeof(bs:read(4)) -- # of code length codes - 4

	local ncodelen_codes = hclen + 4
	local codelen_init = {}
	
	for i = 1, ncodelen_codes do
		local nbits = bs:read(3)
		local val = codelen_vals[i]
		codelen_init[val] = nbits
	end
	
	local codeLenTable = HuffmanTable(codelen_init, true)

	local function decode(ncodes)
		local init = {}
		local nbits
		local val = 0
		
		while val < ncodes do
			local codelen = codeLenTable:read(bs)
			local nrepeat
			
			if codelen <= 15 then
				nrepeat = 1
				nbits = codelen
			elseif codelen == 16 then
				nrepeat = 3 + noeof(bs:read(2))
			elseif codelen == 17 then
				nrepeat = 3 + noeof(bs:read(3))
				nbits = 0
			elseif codelen == 18 then
				nrepeat = 11 + noeof(bs:read(7))
				nbits = 0
			end
			
			for i = 1, nrepeat do
				init[val] = nbits
				val = val + 1
			end
		end
		
		return HuffmanTable(init, true)
	end

	local nlit_codes = hlit + 257
	local ndist_codes = hdist + 1
	
	local litTable = decode(nlit_codes)
	local distTable = decode(ndist_codes)
	
	return litTable, distTable
end

local tdecode_len_base
local tdecode_len_nextrabits
local tdecode_dist_base
local tdecode_dist_nextrabits

local function parse_compressed_item(bs, outstate, littable, disttable)
	local val = littable:read(bs)
	
	if val < 256 then -- literal
		output(outstate, val)
	elseif val == 256 then -- end of block
		return true
	else
		if not tdecode_len_base then
			local t = { [257] = 3 }
			local skip = 1
			
			for i = 258, 285, 4 do
				for j = i, i + 3 do 
					t[j] = t[j - 1] + skip 
				end
				
				if i ~= 258 then 
					skip = skip * 2 
				end
			end
			
			t[285] = 258
			tdecode_len_base = t
		end
		
		if not tdecode_len_nextrabits then
			local t = {}
		
			for i = 257, 285 do
				local j = math_max(i - 261, 0)
				t[i] = rshift(j, 2)
			end
	
			t[285] = 0
			tdecode_len_nextrabits = t
		end
		
		local len_base = tdecode_len_base[val]
		local nextrabits = tdecode_len_nextrabits[val]
		local extrabits = bs:read(nextrabits)
		local len = len_base + extrabits
	
		if not tdecode_dist_base then
			local t = {[0] = 1}
			local skip = 1
			
			for i = 1, 29, 2 do
				for j = i, i + 1 do 
					t[j] = t[j - 1] + skip 
				end
				
				if i ~= 1 then 
					skip = skip * 2 
				end
			end
			
			tdecode_dist_base = t
		end
		
		if not tdecode_dist_nextrabits then
			local t = {}
	
			for i = 0, 29 do
				local j = math_max(i - 2, 0)
				t[i] = rshift(j, 1)
			end
	
			tdecode_dist_nextrabits = t
		end
		
		local dist_val = disttable:read(bs)
		local dist_base = tdecode_dist_base[dist_val]
		
		local dist_nextrabits = tdecode_dist_nextrabits[dist_val]
		local dist_extrabits = bs:read(dist_nextrabits)
		
		local dist = dist_base + dist_extrabits
		
		for i = 1, len do
			local pos = (outstate.window_pos - 1 - dist) % 32768 + 1  -- 32K
			output(outstate, assert(outstate.window[pos], 'invalid distance'))
		end
	end
	
	return false
end


local function parse_block(bs, outstate)
	local bfinal = bs:read(1)
	local btype = bs:read(2)
	
	if btype == BTYPE_NO_COMPRESSION then
		local left = bs:nbits_left_in_byte()
		bs:read(left)
		
		local len = bs:read(16)
		local nlen_ = noeof(bs:read(16))

		for i = 1, len do
			local by = noeof(bs:read(8))
			output(outstate, by)
		end
	elseif btype == BTYPE_FIXED_HUFFMAN or btype == BTYPE_DYNAMIC_HUFFMAN then
		local littable, disttable

		if btype == BTYPE_DYNAMIC_HUFFMAN then
			littable, disttable = parse_huffmantables(bs)
		else
			littable  = HuffmanTable {0, 8, 144, 9, 256, 7, 280, 8, 288, nil}
			disttable = HuffmanTable {0, 5, 32, nil}
		end
		
		repeat until parse_compressed_item(bs, outstate, littable, disttable)
	else
		error("unrecognized compression type")
	end

	return bfinal ~= 0
end


function Deflate:Inflate(t)
	local bs = get_bitstream(t.Input)
	local outbs = t.Output
	
	local outstate = make_outstate(outbs)
	repeat until parse_block(bs, outstate)
end

function Deflate:Inflate_zlib(t)
	local bs = get_bitstream(t.Input)
	local outbs = t.Output
	
	local window_size_ = parse_zlib_header(bs)

	self:Inflate
	{
		Input = bs;
		Output = outbs;
	}
	
	bs:read(bs:nbits_left_in_byte())
end

return Deflate