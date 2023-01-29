export type BinaryReaderImpl = {
	__index: BinaryReaderImpl,
	new: (buffer: string) -> BinaryReader,
	ReadByte: (BinaryReader) -> number?,
	ReadBytes: (BinaryReader, count: number) -> { number },
	ReadAllBytes: (BinaryReader) -> { number },
	IterateBytes: (BinaryReader) -> () -> number?,
	TwosComplementOf: (BinaryReader, value: number, numBits: number) -> number,
	ReadUInt16: (BinaryReader) -> number,
	ReadInt16: (BinaryReader) -> number,
	ReadUInt32: (BinaryReader) -> number,
	ReadInt32: (BinaryReader) -> number,
	ReadString: (BinaryReader, length: number) -> string,
	ForkReader: (BinaryReader, length: number) -> BinaryReader
}

export type BinaryReaderProto = {
	Position: number,
	Buffer: string,
	Length: number
}

export type BinaryReader = typeof(setmetatable({} :: BinaryReaderProto, {} :: BinaryReaderImpl))

----------------

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

return {}