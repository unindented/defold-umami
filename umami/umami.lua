local reporter = require("umami.reporter")
local queue = require("umami.internal.queue")

local M = {
  dispatch_interval = tonumber(sys.get_config("umami.dispatch_interval", 1)),
  dispatch_timer = 0,
  save_interval = tonumber(sys.get_config("umami.save_interval", 30)),
  save_timer = 0,
}

local default_reporter = nil

--- Get the default reporter.
--- @return table
function M.get_default_reporter()
  if default_reporter == nil then
    local dsn = sys.get_config("umami.dsn")
    local website_id = sys.get_config("umami.website_id")
    default_reporter = reporter.create(dsn, website_id)
  end
  return default_reporter
end

--- Dispatch items to Umami.
function M.dispatch()
  queue.dispatch()
end

--- Saves items to disk.
function M.save()
  queue.save()
end

--- Dispatch items to Umami on an interval, if enabled.
function M.update(dt)
  if M.dispatch_interval > 0 then
    M.dispatch_timer = M.dispatch_timer + dt

    if M.dispatch_timer >= M.dispatch_interval then
      M.dispatch_timer = M.dispatch_timer - M.dispatch_interval
      M.dispatch()
    end
  end

  if M.save_interval > 0 then
    M.save_timer = M.save_timer + dt

    if M.save_timer >= M.save_interval then
      M.save_timer = M.save_timer - M.save_interval
      M.save()
    end
  end
end

return M
