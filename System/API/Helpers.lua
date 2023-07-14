LongestString = function(input, key, isKey)
	local length = 0
	if isKey then
		for k, v in pairs(input) do
			local titleLength = string.len(k)
			if titleLength > length then
				length = titleLength
			end
		end
	else
		for i = 1, #input do
			local value = input[i]
			if key then
				if value[key] then
					value = value[key]
				else
					value = ''
				end
			end
			local titleLength = string.len(value)
			if titleLength > length then
				length = titleLength
			end
		end
	end
	return length
end

OpenFile = function(path, args)
	args = args or {}
	if fs.exists(path) then
		local extension = Helpers.Extension(path)
		if extension == 'shortcut' then
			h = fs.open(path, 'r')
			local shortcutPointer = h.readLine()
			local sArgs = h.readLine()
			local tArgs = {}
			if sArgs then
				for match in string.gmatch( sArgs, "[^ \t]+" ) do
					table.insert(tArgs, match)
				end
			end
			h.close()

			Helpers.OpenFile(shortcutPointer, tArgs)
		elseif extension == 'program' then
			if fs.isDir(path) and fs.exists(path..'/startup') then
				LaunchProgram(path..'/startup', args, Helpers.RemoveExtension(fs.getName(path)))
			elseif not fs.isDir(path) then
				LaunchProgram(path, args, Helpers.RemoveExtension(fs.getName(path)))
			end
		elseif fs.isDir(path) then
			LaunchProgram('/System/Programs/Files.program/startup', {path}, 'Files')
		elseif extension then
			local _path = Indexer.FindFileInFolder(extension, 'Icons')
			if _path then
				Helpers.OpenFile(Helpers.ParentFolder(Helpers.ParentFolder(_path)), {path})
			else

			end
		else
			LaunchProgram('/Programs/LuaIDE.program/startup', {path}, 'LuaIDE')
		end
	end
end

ParentFolder = function(path)
	local folderName = fs.getName(path)
	return path:sub(1, #path-#folderName-1)
end

ListPrograms = function()
	local programs = {}

	for i, v in ipairs(fs.list('Programs/')) do
		if string.sub( v, 1, 1 ) ~= '.' then
			table.insert(programs, v)
		end
	end

	return programs
end

ReadIcon = function(path, cacheName)
	cacheName = cacheName or path
	if not Current.IconCache[cacheName] then
		Current.IconCache[cacheName] = Drawing.LoadImage(path, true)
	end
	return Current.IconCache[cacheName]
end

Split = function(str,sep)
    sep=sep or'/'
    return str:match("(.*"..sep..")")
end

Extension = function(path, addDot)
	if not path then
		return nil
	elseif not string.find(fs.getName(path), '%.') then
		if not addDot then
			return fs.getName(path)
		else
			return ''
		end
	else
		local _path = path
		if path:sub(#path) == '/' then
			_path = path:sub(1,#path-1)
		end
		local extension = _path:gmatch('%.[0-9a-z]+$')()
		if extension then
			extension = extension:sub(2)
		else
			--extension = nil
			return ''
		end
		if addDot then
			extension = '.'..extension
		end
		return extension:lower()
	end
end

RemoveExtension = function(path)
	if path:sub(1,1) == '.' then
		return path
	end
	local extension = Helpers.Extension(path)
	if extension == path then
		return fs.getName(path)
	end
	return string.gsub(path, extension, ''):sub(1, -2)
end

RemoveFileName = function(path)
	if string.sub(path, -1) == '/' then
		path = string.sub(path, 1, -2)
	end
	local v = string.match(path, "(.-)([^\\/]-%.?([^%.\\/]*))$")
	if type(v) == 'string' then
		return v
	end
	return v[1]
end

IconForFile = function(path)
	path = TidyPath(path)
	local extension = Helpers.Extension(path)
	if extension and Current.IconCache[extension] then
		return Current.IconCache[extension]
	elseif extension and extension == 'shortcut' then
		h = fs.open(path, 'r')
		if h then
			local shortcutPointer = h.readLine()
			h.close()
			return Helpers.IconForFile(shortcutPointer)
		end
		return ReadIcon('System/Images/Icons/unknown')
	elseif extension and extension == 'program' then
		if fs.isDir(path) and fs.exists(path..'/startup') and fs.exists(path..'/icon') then
			return ReadIcon(path..'/icon')
		elseif not fs.isDir(path) or (fs.isDir(path) and fs.exists(path..'/startup') and not fs.exists(path..'/icon')) then
			return ReadIcon('System/Images/Icons/program')
		else
			return ReadIcon('System/Images/Icons/folder')
		end
	elseif fs.isDir(path) then
		return ReadIcon('System/Images/Icons/folder')
	elseif extension and fs.exists('System/Images/Icons/'..extension) then
		return ReadIcon('System/Images/Icons/'..extension)
	elseif extension then
		local _path = Indexer.FindFileInFolder(extension, 'Icons')
		if _path then
			return ReadIcon(_path, extension)
		else
			return ReadIcon('System/Images/Icons/unknown')
		end
	else
		return ReadIcon('System/Images/Icons/unknown')
	end
end

TruncateString = function(sString, maxLength)
	if #sString > maxLength then
		sString = sString:sub(1,maxLength-3)
		if sString:sub(-1) == ' ' then
			sString = sString:sub(1,maxLength-4)
		end
		sString = sString  .. '...'
	end
	return sString
end

WrapText = function(text, maxWidth)
	local lines = {''}
    for word, space in text:gmatch('(%S+)(%s*)') do
            local temp = lines[#lines] .. word .. space:gsub('\n','')
            if #temp > maxWidth then
                    table.insert(lines, '')
            end
            if space:find('\n') then
                    lines[#lines] = lines[#lines] .. word
                    
                    space = space:gsub('\n', function()
                            table.insert(lines, '')
                            return ''
                    end)
            else
                    lines[#lines] = lines[#lines] .. word .. space
            end
    end
	return lines
end

MakeShortcut = function(path)
	path = TidyPath(path)
	local name = Helpers.RemoveExtension(fs.getName(path))
	local f = fs.open('Desktop/'..name..'.shortcut', 'w')
	f.write(path)
	f.close()
end

TidyPath = function(path)
	path = '/'..path
	if fs.exists(path) and fs.isDir(path) then
		path = path .. '/'
	end

	path, n = path:gsub("//", "/")
	while n > 0 do
		path, n = path:gsub("//", "/")
	end
	return path
end

Capitalise = function(str)
	return str:sub(1, 1):upper() .. str:sub(2, -1)
end