--!native
--!optimize 2
--!strict

local MODULO = 2 ^ 32
local BYTE, DWORD = 1, 4

local CONSTANTS = buffer.create(64 * DWORD)
do -- CONSTANTS = k
	local RoundConstants = {
		0x428a2f98,
		0x71374491,
		0xb5c0fbcf,
		0xe9b5dba5,
		0x3956c25b,
		0x59f111f1,
		0x923f82a4,
		0xab1c5ed5,
		0xd807aa98,
		0x12835b01,
		0x243185be,
		0x550c7dc3,
		0x72be5d74,
		0x80deb1fe,
		0x9bdc06a7,
		0xc19bf174,
		0xe49b69c1,
		0xefbe4786,
		0x0fc19dc6,
		0x240ca1cc,
		0x2de92c6f,
		0x4a7484aa,
		0x5cb0a9dc,
		0x76f988da,
		0x983e5152,
		0xa831c66d,
		0xb00327c8,
		0xbf597fc7,
		0xc6e00bf3,
		0xd5a79147,
		0x06ca6351,
		0x14292967,
		0x27b70a85,
		0x2e1b2138,
		0x4d2c6dfc,
		0x53380d13,
		0x650a7354,
		0x766a0abb,
		0x81c2c92e,
		0x92722c85,
		0xa2bfe8a1,
		0xa81a664b,
		0xc24b8b70,
		0xc76c51a3,
		0xd192e819,
		0xd6990624,
		0xf40e3585,
		0x106aa070,
		0x19a4c116,
		0x1e376c08,
		0x2748774c,
		0x34b0bcb5,
		0x391c0cb3,
		0x4ed8aa4a,
		0x5b9cca4f,
		0x682e6ff3,
		0x748f82ee,
		0x78a5636f,
		0x84c87814,
		0x8cc70208,
		0x90befffa,
		0xa4506ceb,
		0xbef9a3f7,
		0xc67178f2,
	}

	for Index, Constant in ipairs(RoundConstants) do
		local BufferOffset = (Index - 1) * DWORD
		buffer.writeu32(CONSTANTS, BufferOffset, Constant)
	end
end

local HASH_VALUES = buffer.create(8 * DWORD)
do -- HASH_VALUES = h0-h7
	buffer.writeu32(HASH_VALUES, 0, 0x6a09e667)
	buffer.writeu32(HASH_VALUES, 4, 0xbb67ae85)
	buffer.writeu32(HASH_VALUES, 8, 0x3c6ef372)
	buffer.writeu32(HASH_VALUES, 12, 0xa54ff53a)
	buffer.writeu32(HASH_VALUES, 16, 0x510e527f)
	buffer.writeu32(HASH_VALUES, 20, 0x9b05688c)
	buffer.writeu32(HASH_VALUES, 24, 0x1f83d9ab)
	buffer.writeu32(HASH_VALUES, 28, 0x5be0cd19)
end

local function ProcessNumber(Input: number, Length: number): buffer
	local OutputBuffer = buffer.create(Length)

	for Index = Length - 1, 0, -1 do
		local Remainder = Input % 256
		buffer.writeu8(OutputBuffer, Index, Remainder)
		Input = bit32.rshift(Input, 8)
	end

	return OutputBuffer
end

local function PreProcess(Content: buffer): (buffer, number)
	local ContentLength = buffer.len(Content)
	local Padding = (64 - ((ContentLength + 9) % 64)) % 64

	local NewContentLength = ContentLength + 1 + Padding + 8
	local NewContent = buffer.create(NewContentLength)
	buffer.copy(NewContent, 0, Content)
	buffer.writeu8(NewContent, ContentLength, 128)
	local Length8 = ContentLength * 8
	for Index = 7, 0, -1 do
		local Remainder = Length8 % 256
		buffer.writeu8(NewContent, Index + ContentLength + 1 + Padding, Remainder)
		Length8 = (Length8 - Remainder) / 256
	end

	return NewContent, NewContentLength
end

local Offsets = buffer.create(256)
local function DigestBlock(
	Blocks: buffer,
	Offset: number,
	A: number,
	B: number,
	C: number,
	D: number,
	E: number,
	F: number,
	G: number,
	H: number
)
	for BlockIndex = 0, 60, 4 do
		local BlockBufferIndex = Offset + BlockIndex
		local Word = bit32.byteswap(buffer.readu32(Blocks, BlockBufferIndex))

		buffer.writeu32(Offsets, BlockIndex, Word)
	end

	for Index = 16 * 4, 63 * 4, 4 do
		local Sub15 = buffer.readu32(Offsets, Index - (15 * 4))
		local Sub2 = buffer.readu32(Offsets, Index - (2 * 4))

		local Sub16 = buffer.readu32(Offsets, Index - (16 * 4))
		local Sub7 = buffer.readu32(Offsets, Index - (7 * 4))

		local S0 = bit32.bxor(bit32.rrotate(Sub15, 7), bit32.rrotate(Sub15, 18), bit32.rshift(Sub15, 3))
		local S1 = bit32.bxor(bit32.rrotate(Sub2, 17), bit32.rrotate(Sub2, 19), bit32.rshift(Sub2, 10))

		buffer.writeu32(Offsets, Index, (Sub16 + S0 + Sub7 + S1))
	end

	local OldA, OldB, OldC, OldD, OldE, OldF, OldG, OldH = A, B, C, D, E, F, G, H

	for BufferIndex = 0, 63 * 4, 4 do
		local S1 = bit32.bxor(bit32.rrotate(E, 6), bit32.rrotate(E, 11), bit32.rrotate(E, 25))
		local Ch = bit32.bxor(bit32.band(E, F), bit32.band(bit32.bnot(E), G))
		local Temp1 = H + S1 + Ch + buffer.readu32(CONSTANTS, BufferIndex) + buffer.readu32(Offsets, BufferIndex)
		local S0 = bit32.bxor(bit32.rrotate(A, 2), bit32.rrotate(A, 13), bit32.rrotate(A, 22))
		local Maj = bit32.bxor(bit32.band(A, B), bit32.band(A, C), bit32.band(B, C))
		local Temp2 = S0 + Maj

		H = G
		G = F
		F = E
		E = D + Temp1
		D = C
		C = B
		B = A
		A = Temp1 + Temp2
	end

	return (A + OldA) % MODULO,
		(B + OldB) % MODULO,
		(C + OldC) % MODULO,
		(D + OldD) % MODULO,
		(E + OldE) % MODULO,
		(F + OldF) % MODULO,
		(G + OldG) % MODULO,
		(H + OldH) % MODULO
end

local HashValues = buffer.create(32)
local FormatString = string.rep("%08x", 8)
local function SHA256(Message: buffer, Salt: buffer?): string
	if Salt and buffer.len(Salt) > 0 then
		local MessageWithSalt = buffer.create(buffer.len(Message) + buffer.len(Salt))

		buffer.copy(MessageWithSalt, 0, Message)
		buffer.copy(MessageWithSalt, buffer.len(Message), Salt)

		Message = MessageWithSalt
	end

	local A, B, C, D = 0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a
	local E, F, G, H = 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19

	local ProcessedMessage, Length = PreProcess(Message)
	for Index = 0, Length - 1, 64 do
		A, B, C, D, E, F, G, H = DigestBlock(ProcessedMessage, Index, A, B, C, D, E, F, G, H)
	end

	return string.format(FormatString, A, B, C, D, E, F, G, H)
end

type TestVector = {
	Description: string,
	ExpectedHash: string,
}

type TestVectors = { [string]: TestVector }

local TestVectors: TestVectors = {
	[""] = {
		Description = "Empty String",
		ExpectedHash = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
	},
	["The quick brown fox jumps over the lazy dog."] = {
		Description = "SHA256 Pangramm Example",
		ExpectedHash = "ef537f25c895bfa782526529a9b63d97aa631564d5d789c2b765448c8635fb6c",
	},
	["??????, ???!"] = {
		Description = "UTF-8 Example",
		ExpectedHash = "bd3e42b490abba3fdda948b4305f2610bf1f1516ae7db6bdfd24939a9de5ee71",
	},
	[string.rep("A", 1024)] = {
		Description = "Long String",
		ExpectedHash = "6ab72eeb9e77b07540897e0c8d6d23ec8eef0f8c3a47e1b3f4e93443d9536bed",
	},
	["\0"] = {
		Description = "Null Terminator",
		ExpectedHash = "6e340b9cffb37a989ca544e6bb780a2c78901d3fb33738768511a30617afa01d",
	},
	[string.rep("a", 55)] = {
		Description = "Block of Characters",
		ExpectedHash = "9f4390f8d30c2dd92ec9f095b65e2b9ae9b0a925a5258e241c9f1e910f734318",
	},
	[string.rep("a", 119)] = {
		Description = "119 Characters",
		ExpectedHash = "31eba51c313a5c08226adf18d4a359cfdfd8d2e816b13f4af952f7ea6584dcfb",
	},
	[string.rep("a", 111)] = {
		Description = "111 Characters",
		ExpectedHash = "6374f73208854473827f6f6a3f43b1f53eaa3b82c21c1a6d69a2110b2a79baad",
	},
	[string.rep("a", 239)] = {
		Description = "239 Characters",
		ExpectedHash = "064b3d122abe25c36265f79fc794b0adf28a6c5e4fe8ed3661f2287e8cecadcc",
	},
}

for TestString, Info: TestVector in TestVectors do
	local HashedString = SHA256(buffer.fromstring(TestString))

	local ErrorMessage = string.format(
		"Test String (%s) produced incorrect hash. Expected '%s', got '%s'",
		Info.Description,
		Info.ExpectedHash,
		HashedString
	)

	assert(HashedString == Info.ExpectedHash, ErrorMessage)
	--print(`Test '{Info.Description}' passed`)
end

--print("[SHA256] All test cases passed")

return SHA256
