local file = require("umami.internal.file")
local json_encode = require("umami.internal.json_encode")
local user_agent = require("umami.internal.user_agent")

local M = {
  log = sys.get_config("umami.verbose") == "1" and print or function() end,
}

local QUEUE_FILENAME = "__umami_queue"

local queue = {}

--- Add item to queue.
--- @param type string Item type
--- @param payload table Item payload
function M.add(dsn, type, payload)
  table.insert(queue, {
    dsn = dsn,
    type = type,
    payload = payload,
    time = socket.gettime(),
  })
end

--- Dispatch all queued items to Umami.
function M.dispatch()
  if #queue == 0 then
    return
  end

  local item = table.remove(queue, 1)
  local headers = {
    ["Content-Type"] = "application/json",
    ["User-Agent"] = user_agent.get(),
  }
  local post_data = json_encode.encode({ type = item.type, payload = item.payload })

  local function callback(self, id, response)
    if response.status < 200 or response.status >= 300 then
      M.log("[umami] dispatch failed: " .. response.status)
      M.log("[umami] retrying item: " .. item.type)
      table.insert(queue, item)
    end
  end

  M.log("[umami] dispatching item: " .. item.type)
  http.request(item.dsn .. "/api/collect", "POST", callback, headers, post_data)
end

--- Save queued items to disk.
function M.save()
  M.log("[umami] saving queue")
  local ok, err = pcall(function()
    assert(file.save(QUEUE_FILENAME, json_encode.encode(queue)))
  end)

  if not ok then
    M.log("[umami] queue could not be saved: " .. err)
  end
end

--- Load queued items from disk.
function M.load()
  M.log("[umami] loading queue")
  local ok, loaded_queue_or_err = pcall(function()
    return json.decode(file.load(QUEUE_FILENAME))
  end)

  if ok then
    queue = loaded_queue_or_err
  else
    M.log("[umami] queue could not be loaded: " .. loaded_queue_or_err)
  end
end

M.load()

return M
