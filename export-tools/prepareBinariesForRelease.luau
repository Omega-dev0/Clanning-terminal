local roblox = require("@lune/roblox")
local fs = require("@lune/fs")
local constants = require("./constants")

local function resolveReplaceToken(token)
	local variableName = token:match("^%{([%w_]+)%}$")
	if variableName ~= nil then
		if type(constants) == "table" and constants[variableName] ~= nil then
			return tostring(constants[variableName])
		end

		return ""
	end

	return token
end

local function transformDevBlocks(text)
	local cursor = 1
	local output = {}

	while true do
		local tagStart, _ = text:find("--[DEV](", cursor, true)
		if tagStart == nil then
			table.insert(output, text:sub(cursor))
			break
		end

		table.insert(output, text:sub(cursor, tagStart - 1))

		local lineEnd = text:find("\n", tagStart, true)
		if lineEnd == nil then
			table.insert(output, text:sub(tagStart))
			break
		end

		local header = text:sub(tagStart, lineEnd - 1)
		local closingStart, closingEnd = text:find("\n--}", lineEnd, true)
		if closingStart == nil then
			table.insert(output, text:sub(tagStart))
			break
		end

		local nextCursor = closingEnd + 1
		local consumedTrailingNewline = false
		if text:sub(nextCursor, nextCursor) == "\n" then
			nextCursor += 1
			consumedTrailingNewline = true
		end

		if header:match("^%-%-%[DEV%]%(%s*DELETE%s*%)%{$") then
			cursor = nextCursor
		else
			local replaceToken = header:match("^%-%-%[DEV%]%(%s*REPLACE:(.-):%s*%)%{$")
			if replaceToken ~= nil then
				table.insert(output, resolveReplaceToken(replaceToken))
				if consumedTrailingNewline then
					table.insert(output, "\n")
				end
				cursor = nextCursor
			else
				table.insert(output, text:sub(tagStart, nextCursor - 1))
				cursor = nextCursor
			end
		end
	end

	return table.concat(output)
end

local function transformSourcesInModel(model)
	local visited = {}
	local queue = { model }

	while #queue > 0 do
		local current = table.remove(queue)
		if type(current) == "table" and not visited[current] then
			visited[current] = true

			for key, value in pairs(current) do
				if type(value) == "string" and (key == "Source" or key == "Contents") then
					current[key] = transformDevBlocks(value)
				elseif type(value) == "table" and not visited[value] then
					table.insert(queue, value)
				end
			end
		end
	end
end

for fileName, fileType in fs.walk("./input") do
	local content = fs.readFile(`./input/{fileName}`)
	local model = roblox.deserializeModel(content)

	transformSourcesInModel(model)

	local result = roblox.serializeModel(model)
	fs.writeFile(`./output/{fileName}`, result)
end
