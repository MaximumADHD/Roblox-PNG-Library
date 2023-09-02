--!native

-- zzlib - zlib decompression in Lua - Implementation-independent code

-- Copyright (c) 2016-2023 Francois Galea <fgalea at free.fr>
-- This program is free software. It comes without any warranty, to
-- the extent permitted by applicable law. You can redistribute it
-- and/or modify it under the terms of the Do What The Fuck You Want
-- To Public License, Version 2, as published by Sam Hocevar. See
-- the COPYING file or http://www.wtfpl.net/ for more details.

local unpack = table.unpack or unpack
local infl = require(script["inflate-bit32"])

local schar = string.char

local zzlib = {}

local function arraytostr(array: { number }): string
	local tmp = {}
	local size = #array
	local pos = 1
	local imax = 1
	while size > 0 do
		local bsize = size >= 2048 and 2048 or size
		local s = schar(unpack(array, pos, pos + bsize - 1))
		pos = pos + bsize
		size = size - bsize
		local i = 1
		while tmp[i] do
			s = tmp[i] .. s
			tmp[i] = nil
			i = i + 1
		end
		if i > imax then
			imax = i
		end
		tmp[i] = s
	end
	local str = ""
	for i = 1, imax do
		if tmp[i] then
			str = tmp[i] .. str
		end
	end
	return str
end

-- compute Adler-32 checksum
local function adler32(s: string): number
	local s1 = 1
	local s2 = 0
	for i = 1, #s do
		local c = s:byte(i)
		s1 = (s1 + c) % 65521
		s2 = (s2 + s1) % 65521
	end
	return s2 * 65536 + s1
end

local function inflate_zlib(bs): string
	local cmf = bs.buf:byte(1)
	local flg = bs.buf:byte(2)
	if (cmf * 256 + flg) % 31 ~= 0 then
		error("zlib header check bits are incorrect")
	end
	if infl.band(cmf, 15) ~= 8 then
		error("only deflate format is supported")
	end
	if infl.rshift(cmf, 4) ~= 7 then
		error("unsupported window size")
	end
	if infl.band(flg, 32) ~= 0 then
		error("preset dictionary not implemented")
	end
	bs.pos = 3
	local result = arraytostr(infl.main(bs))
	local adler = ((bs:getb(8) * 256 + bs:getb(8)) * 256 + bs:getb(8)) * 256 + bs:getb(8)
	if adler ~= adler32(result) then
		error("checksum verification failed")
	end
	return result
end

function zzlib.inflate(str: string): string
	return inflate_zlib(infl.bitstream_init(str))
end

return zzlib
