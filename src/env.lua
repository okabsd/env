local error, io, loadfile, next, package, setfenv, setmetatable, type =
      error, io, loadfile, next, package, setfenv, setmetatable, type

local function nop () end

local DEFAULT_SEARCH_PATHS = {}

for str in package.path:gmatch('([^;]+)') do
	DEFAULT_SEARCH_PATHS[#DEFAULT_SEARCH_PATHS + 1] = str
end

local function clone (target)
	local new = {}

	for key, value in next, target do
		new[key] = value
	end

	return new
end

local function find_mod (modname, paths)
	for index = 1, #paths do
		local path = paths[index]:gsub('?', modname)
		local fd = io.open(path, 'rb')

		if fd then
			local readable = fd:read(0)

			fd:close()

			if readable then
				return path
			end
		end
	end

	error(('Could not find module: %s'):format(modname), 0)
end

local function load_mod (path, env)
	local chunk, err = loadfile(path, nil, env)

	if err then
		error(('Error loading %s\n\t%s'):format(path, err), 0)
	end

	if setfenv then -- Lua 5.1 compat
		setfenv(chunk, env)
	end

	return chunk()
end

return function (target)
	local env = clone(target or _G or {})

	env.import = {
		paths = clone(DEFAULT_SEARCH_PATHS),
		cache = {}
	}

	local function import (self, modname)
		local force_import = false

		do
			local len = #modname

			if modname:sub(len) == '!' then
				modname = modname:sub(1, len - 1)
				force_import = true
			end
		end

		local cached = self.cache[modname]
		local path, mod

		if cached then
			path, mod = cached.path, cached.mod
		else
			path = find_mod(modname, self.paths or DEFAULT_SEARCH_PATHS)
			mod = load_mod(path, env)
			self.cache[modname] = { path = path, mod = mod }
		end

		local last_namespace = modname
		local namespaced = false

		if force_import or env[modname] == nil then
			env[modname] = mod
		end

		local inbound = {}

		function inbound:as (namespace)
			local namespace_t = type(namespace)

			if namespace_t ~= 'string' then
				error(('Invalid namespace for: %s @ %s\n\t<%s> %s')
					:format(modname, path, namespace_t, namespace), 0)
			end

			if env[last_namespace] == mod then
				env[last_namespace] = nil
			end

			last_namespace = namespace
			namespaced = true
			env[namespace] = mod

			return self
		end

		function inbound:use (subspaces)
			if not force_import and not namespaced and env[modname] == mod then
				env[modname] = nil
			end

			if subspaces == '*' then
				for id, value in next, mod do
					env[id] = value
				end
			else
				for named, lookup in next, subspaces do
					local value = mod[lookup]

					if value == nil then
						error(('Cannot import { %s } from: %s @ %s')
							:format(lookup, modname, path), 0)
					end

					env[type(named) == 'number' and lookup or named] = value
				end
			end

			return self
		end

		return inbound
	end

	setmetatable(env.import, {
		__call = import,
		__metatable = false,
		__newindex = nop
	})

	return env
end
