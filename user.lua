local function execute(...)
	local f = io.popen(...);
	local result = f:read"*a";
	f:close();
	return result;
end

local function write_line_to_file(filename, line_number, data)
	local file = io.open(filename, "r")
	print("file", filename, file)
	local file_content = {}
	for line in file:lines() do
		file_content[#file_content + 1] = line
		print(file_content[#file_content])
	end
	print("before: ", file_content[line_number])
	file:close()

	for i, v in ipairs(file_content) do print(i,v) end
	file_content[line_number] = data
	print("after: ", file_content[line_number])
	for i, v in ipairs(file_content) do print(i,v) end

	file = io.open(filename, "w")
	for _, line in ipairs(file_content) do
		file:write(line .. '\n')
	end
	file:close()
end

function User(name)
	local line = execute("cat /etc/passwd | grep -n " .. name .. ":");
	if #line == 0 then
		return nil;
	end
	local line_number, name, uid, gid, description, home, shell = line:match("(%d+):(%w+):x:(%d+):(%d+):([^:]+):([/%w]+):([/%w]+)");
	local line_number = tonumber(line_number);
	local object = {
		name = name,
		description = description,
		home = home,
		shell = shell
	};
	function object:setDescription(new_desc)
		if new_desc ~= self.description then
			write_line_to_file(
				"/etc/passwd",
				line_number,
				name .. ':x:' .. uid .. ':' .. gid .. ':' .. new_desc .. ':' .. home .. ':' .. shell
			);
			self.description = new_desc;
		end
	end
	return object;
end
