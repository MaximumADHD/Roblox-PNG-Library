local Unfilter = {}

function Unfilter:None(scanline, pixels, bpp, row)
	for i = 1, #scanline do
		pixels[row][i] = scanline[i]
	end
end

function Unfilter:Sub(scanline, pixels, bpp, row)
	for i = 1, bpp do
		pixels[row][i] = scanline[i]
	end
	
	for i = bpp + 1, #scanline do
		local x = scanline[i]
		local a = pixels[row][i - bpp]
		pixels[row][i] = bit32.band(x + a, 0xFF)
	end
end

function Unfilter:Up(scanline, pixels, bpp, row)
	if row > 1 then
		local upperRow = pixels[row - 1]
		
		for i = 1, #scanline do
			local x = scanline[i]
			local b = upperRow[i]
			pixels[row][i] = bit32.band(x + b, 0xFF)
		end
	else
		return self:None(scanline, pixels, bpp, row)
	end
end

function Unfilter:Average(scanline, pixels, bpp, row)
	if row > 1 then
		for i = 1, bpp do
			local x = scanline[i]
			local b = pixels[row - 1][i]
			
			b = bit32.rshift(b, 1)
			pixels[row][i] = bit32.band(x + b, 0xFF)
		end
		
		for i = bpp + 1, #scanline do
			local x = scanline[i]
			local b = pixels[row - 1][i]
			
			local a = pixels[row][i - bpp]
			local ab = bit32.rshift(a + b, 1)
			
			pixels[row][i] = bit32.band(x + ab, 0xFF)
		end
	else
		for i = 1, bpp do
			pixels[row][i] = scanline[i]
		end
	
		for i = bpp + 1, #scanline do
			local x = scanline[i]
			local b = pixels[row - 1][i]
			
			b = bit32.rshift(b, 1)
			pixels[row][i] = bit32.band(x + b, 0xFF)
		end
		
		return self:Sub(scanline, pixels, bpp, row)
	end
end

function Unfilter:Paeth(scanline, pixels, bpp, row)
	if row > 1 then
		local pr
		
		for i = 1, bpp do
			local x = scanline[i]
			local b = pixels[row - 1][i]
			pixels[row][i] = bit32.band(x + b, 0xFF)
		end
		
		for i = bpp + 1, #scanline do
			local a = pixels[row][i - bpp]
			local b = pixels[row - 1][i]
			local c = pixels[row - 1][i - bpp]
			
			local x = scanline[i]
			local p = a + b - c
			
			local pa = math.abs(p - a)
			local pb = math.abs(p - b)
			local pc = math.abs(p - c)
			
			if pa <= pb and pa <= pc then
				pr = a
			elseif pb <= pc then
				pr = b
			else
				pr = c
			end
			
			pixels[row][i] = bit32.band(x + pr, 0xFF)
		end
	else
		return self:Sub(scanline, pixels, bpp, row)
	end
end

return Unfilter