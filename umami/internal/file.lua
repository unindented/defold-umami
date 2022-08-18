local M = {}

--- Get the full path to a save file.
--- @param filename string File name
--- @return string
function M.save_path(filename)
  local application_name = sys.get_config("project.title"):gsub("%W", "")
  return sys.get_save_file(application_name, filename)
end

--- Load a file from disk.
--- @param filename string File name
--- @return string|nil
--- @return string?
function M.load(filename)
  local path = M.save_path(filename)
  local file, err = io.open(path, "r")

  if file == nil or err then
    return nil, err
  end

  local contents = file:read("*a")

  if contents == nil then
    return nil, "Unable to read file"
  end

  return contents
end

--- Save a file to disk. Saves are atomic and first written to a temporary file. If the file already
--  exists it will be overwritten
--- @param filename string File name
--- @param data string Data to write
--- @return boolean|nil
--- @return string?
function M.save(filename, data)
  local tmppath = M.save_path("__umami_tmp")
  local file, open_err = io.open(tmppath, "w+")

  if not file then
    return nil, open_err
  end

  file:write(data)
  file:close()

  local path = M.save_path(filename)
  os.remove(path)
  return os.rename(tmppath, path)
end

return M
