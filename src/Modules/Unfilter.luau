--!strict
--!native

local Unfilter = {}

local band, rshift = bit32.band, bit32.rshift
local mabs = math.abs

function Unfilter.None(scanline: { number }, pixels: { { number } }, _, row: number)
	for i = 1, #scanline do
		pixels[row][i] = scanline[i]
	end
end

function Unfilter.Sub(scanline: { number }, pixels: { { number } }, bpp: number, row: number)
	for i = 1, bpp do
		pixels[row][i] = scanline[i]
	end

	for i = bpp + 1, #scanline do
		local x = scanline[i]
		local a = pixels[row][i - bpp]
		pixels[row][i] = band(x + a, 0xFF)
	end
end

function Unfilter.Up(scanline: { number }, pixels: { { number } }, bpp: number, row: number)
	if row > 1 then
		local upperRow = pixels[row - 1]

		for i = 1, #scanline do
			local x = scanline[i]
			local b = upperRow[i]
			pixels[row][i] = band(x + b, 0xFF)
		end
	else
		Unfilter.None(scanline, pixels, bpp, row)
	end
end

function Unfilter.Average(scanline: { number }, pixels: { { number } }, bpp: number, row: number)
	if row > 1 then
		for i = 1, bpp do
			local x = scanline[i]
			local b = pixels[row - 1][i]

			b = rshift(b, 1)
			pixels[row][i] = band(x + b, 0xFF)
		end

		for i = bpp + 1, #scanline do
			local x = scanline[i]
			local b = pixels[row - 1][i]

			local a = pixels[row][i - bpp]
			local ab = rshift(a + b, 1)

			pixels[row][i] = band(x + ab, 0xFF)
		end
	else
		for i = 1, bpp do
			pixels[row][i] = scanline[i]
		end

		for i = bpp + 1, #scanline do
			local x = scanline[i]
			local b = pixels[row - 1][i]

			b = rshift(b, 1)
			pixels[row][i] = band(x + b, 0xFF)
		end
	end
end

function Unfilter.Paeth(scanline: { number }, pixels: { { number } }, bpp: number, row: number)
	if row > 1 then
		local pr

		for i = 1, bpp do
			local x = scanline[i]
			local b = pixels[row - 1][i]
			pixels[row][i] = band(x + b, 0xFF)
		end

		for i = bpp + 1, #scanline do
			local a = pixels[row][i - bpp]
			local b = pixels[row - 1][i]
			local c = pixels[row - 1][i - bpp]

			local x = scanline[i]
			local p = a + b - c

			local pa = mabs(p - a)
			local pb = mabs(p - b)
			local pc = mabs(p - c)

			if pa <= pb and pa <= pc then
				pr = a
			elseif pb <= pc then
				pr = b
			else
				pr = c
			end

			pixels[row][i] = band(x + pr, 0xFF)
		end
	else
		Unfilter.Sub(scanline, pixels, bpp, row)
	end
end

return Unfilter
