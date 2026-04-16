local ModuleLoader = {}
ModuleLoader.__index = ModuleLoader

local function defaultHttpGet(url)
    return game:HttpGet(url)
end

local function defaultCompile(source, chunkName)
    return loadstring(source, chunkName)
end

local function trimTrailingSlash(value)
    return (tostring(value):gsub("/+$", ""))
end

function ModuleLoader.new(httpGetFn, compileFn)
    local self = setmetatable({}, ModuleLoader)

    self._httpGet = httpGetFn or defaultHttpGet
    self._compile = compileFn or defaultCompile
    self._sourceCache = {}
    self._moduleCache = {}

    return self
end

function ModuleLoader:FetchSource(url, bypassCache)
    if type(url) ~= "string" or url == "" then
        error("[ModuleLoader] Invalid URL passed to FetchSource.")
    end

    if not bypassCache then
        local cached = self._sourceCache[url]
        if cached ~= nil then
            return cached
        end
    end

    local ok, result = pcall(self._httpGet, url)
    if not ok then
        error(string.format("[ModuleLoader] Failed to fetch URL: %s\n%s", tostring(url), tostring(result)))
    end

    if type(result) ~= "string" or result == "" then
        error(string.format("[ModuleLoader] Empty response from URL: %s", tostring(url)))
    end

    self._sourceCache[url] = result
    return result
end

function ModuleLoader:Compile(source, chunkName)
    local compiled, err = self._compile(source, chunkName)

    if not compiled then
        error(string.format(
            "[ModuleLoader] Failed to compile %s: %s",
            tostring(chunkName),
            tostring(err)
        ))
    end

    return compiled
end

function ModuleLoader:LoadModule(url, bypassCache)
    if type(url) ~= "string" or url == "" then
        error("[ModuleLoader] Invalid URL passed to LoadModule.")
    end

    if not bypassCache then
        local cached = self._moduleCache[url]
        if cached ~= nil then
            return cached
        end
    end

    local source = self:FetchSource(url, bypassCache)
    local chunk = self:Compile(source, "@" .. tostring(url))

    local ok, result = pcall(chunk)
    if not ok then
        error(string.format(
            "[ModuleLoader] Failed to execute module: %s\n%s",
            tostring(url),
            tostring(result)
        ))
    end

    self._moduleCache[url] = result
    return result
end

function ModuleLoader:BuildUrl(baseUrl, relativePath)
    if type(baseUrl) ~= "string" or baseUrl == "" then
        error("[ModuleLoader] Invalid baseUrl.")
    end

    if type(relativePath) ~= "string" or relativePath == "" then
        error("[ModuleLoader] Invalid relativePath.")
    end

    baseUrl = trimTrailingSlash(baseUrl)
    relativePath = relativePath:gsub("^/+", "")

    return baseUrl .. "/" .. relativePath
end

function ModuleLoader:ClearSourceCache(url)
    if url then
        self._sourceCache[url] = nil
        return
    end

    table.clear(self._sourceCache)
end

function ModuleLoader:ClearModuleCache(url)
    if url then
        self._moduleCache[url] = nil
        return
    end

    table.clear(self._moduleCache)
end

function ModuleLoader:ClearAllCache()
    table.clear(self._sourceCache)
    table.clear(self._moduleCache)
end

return ModuleLoader