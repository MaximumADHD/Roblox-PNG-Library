export type BinaryReaderImpl = {
	__index: BinaryReaderImpl,
	new: (buffer: string) -> BinaryReader,
	ReadByte: (self: BinaryReader) -> number?,
	ReadBytes: (self: BinaryReader, count: number) -> { number },
	ReadAllBytes: (self: BinaryReader) -> { number },
	IterateBytes: (self: BinaryReader) -> () -> number?,
	TwosComplementOf: (self: BinaryReader, value: number, numBits: number) -> number,
	ReadUInt16: (self: BinaryReader) -> number,
	ReadInt16: (self: BinaryReader) -> number,
	ReadUInt32: (self: BinaryReader) -> number,
	ReadInt32: (self: BinaryReader) -> number,
	ReadString: (self: BinaryReader, length: number) -> string,
	ForkReader: (self: BinaryReader, length: number) -> BinaryReader
}

export type BinaryReaderProto = {
	Position: number,
	Buffer: string,
	Length: number
}

export type BinaryReader = typeof(setmetatable({} :: BinaryReaderProto, {} :: BinaryReaderImpl))

---------------------------------------------------------------------------------------------

export type TimeStamp = {
	Year: number;
	Month: number;
	Day: number;
	
	Hour: number;
	Minute: number;
	Second: number;
}

export type Chunk = {
	Length: number;
	Type: string;
	
	Data: BinaryReader;
	CRC: number;
}

export type ChromaticityColor = "White" | "Red" | "Green" | "Blue"

export type File = {
	Chunks: { Chunk };
	Metadata: { [string]: string };
	
	Reading: boolean;
	ZlibStream: string?;
	
	-- METADATA
	Bitmap: { { number } }?;
	Width: number?;
	Height: number?;
	BitDepth: number?;
	ColorType: number?;
	NumChannels: number?;
	BytesPerPixel: number?;
	Palette: { Color3 }?;
	Gamma: number?;
	TimeStamp: TimeStamp?;
	AlphaData: { number }?;
	Hash: number?;
	Alpha: (Color3 | number)?;
	Methods: {
		Compression: number;
		Filtering: number;
		Interlace: number;
	}?;
	BackgroundColor: (Color3 | number)?;
	Chromaticity: {
		[ChromaticityColor]: {
			number
		}
	}?;
	RenderIntent: number?
}

---------------------------------------------------------------------------------------------

export type PNGImpl = {
	__index: PNGImpl,
	new: (buffer: string) -> PNG,
	GetPixel: (self: PNG, x: number, y: number) -> (Color3, number)
}

export type PNG = typeof(setmetatable({} :: File, {} :: PNGImpl))

---------------------------------------------------------------------------------------------

export type ChunkReaderState = {
	PreviousChunk: Chunk?;
	FoundChunkType: { string };
}

return {}