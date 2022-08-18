local queue = require("umami.internal.queue")

local M = {}

local function noop() end

--- Create a reporter instance.
--- @param dsn string Umami DSN
--- @param website_id string Website ID from the Umami admin dashboard
--- @return table
function M.create(dsn, website_id)
  local project_title = sys.get_config("project.title")
  local project_version = sys.get_config("project.version")
  local engine_version = sys.get_engine_info().version
  local appname = project_title .. " " .. project_version
  local hostname = appname:lower():gsub("%W+", "-") .. ".com"
  local language = sys.get_sys_info().device_language
  local screen_size = sys.get_config("display.width") .. "x" .. sys.get_config("display.height")

  local reporter = {}

  --- Report screen view.
  --- @param screen_name string Screen name
  function reporter.screen(screen_name)
    queue.add(dsn, "pageview", {
      hostname = hostname,
      language = language,
      screen = screen_size,
      url = "/"
        .. (screen_name or "")
        .. "?project_version="
        .. project_version
        .. "&engine_version="
        .. engine_version,
      website = website_id,
    })
  end

  --- Report event.
  --- @param event_name string Event name
  --- @param event_data table Event data
  --- @param screen_name string? Screen name
  function reporter.event(event_name, event_data, screen_name)
    queue.add(dsn, "event", {
      event_name = event_name,
      event_data = event_data,
      hostname = hostname,
      language = language,
      screen = screen_size,
      url = "/"
        .. (screen_name or "")
        .. "?project_version="
        .. project_version
        .. "&engine_version="
        .. engine_version,
      website = website_id,
    })
  end

  --- Report error.
  --- @param message string Error message
  function reporter.error(message)
    reporter.event("error", { message = message })
  end

  --- Report crash.
  --- @param data string Crash data
  function reporter.crash(data)
    reporter.event("crash", { data = data })
  end

  --- Toggle error/crash reporting.
  --- @param enabled boolean Set to true to enable automatic error/crash reporting
  --- @param on_error function? Callback to invoke when an error is detected
  --- @param on_crash function? Callback to invoke when a crash is detected
  function reporter.toggle_error_crash_reporting(enabled, on_error, on_crash)
    if not enabled then
      sys.set_error_handler(noop)
      return
    end

    sys.set_error_handler(function(source, message, traceback)
      reporter.error(message)
      if on_error then
        on_error(source, message, traceback)
      end
    end)

    local handle = crash and crash.load_previous()
    if handle ~= nil then
      reporter.crash(crash.get_extra_data(handle))
      if on_crash then
        on_crash(handle)
      end
      crash.release(handle)
    end
  end

  return reporter
end

return M
