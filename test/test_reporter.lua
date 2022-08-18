return function()
  local mock = require("deftest.mock.mock")
  local mock_fs = require("deftest.mock.fs")

  describe("reporter", function()
    local dsn = "https://my-umami.vercel.app"
    local hostname = "my-awesome-project-1-0-0.com"
    local language = "sr-Cyrl"
    local screen_size = "1280x720"
    local website_id = "123"

    local queue
    local reporter

    local mocked_queue_items

    before(function()
      queue = require("umami.internal.queue")
      reporter = require("umami.reporter")

      mock.mock(sys)
      mock.mock(queue)

      mock_fs.mock()

      mocked_queue_items = {}
      queue.add.replace(function(dsn, type, payload)
        table.insert(mocked_queue_items, {
          dsn = dsn,
          type = type,
          payload = payload,
        })
      end)

      sys.get_config.replace(function(key)
        if key == "project.title" then
          return "My Awesome Project!"
        elseif key == "project.version" then
          return "1.0.0"
        elseif key == "display.width" then
          return "1280"
        elseif key == "display.height" then
          return "720"
        end
      end)

      sys.get_engine_info.always_returns({
        version = "1.3.5",
      })

      sys.get_sys_info.always_returns({
        language = "sr",
        device_language = "sr-Cyrl",
      })
    end)

    after(function()
      package.loaded["umami.internal.queue"] = nil
      package.loaded["umami.reporter"] = nil

      mock.unmock(queue)
      mock.unmock(sys)

      mock_fs.unmock()
    end)

    describe("create", function()
      it("creates new instances", function()
        local t1 = reporter.create(dsn, website_id)
        local t2 = reporter.create(dsn, website_id .. website_id)
        assert_not_equal(t1, t2)
      end)
    end)

    describe("screen", function()
      it("tracks screen views", function()
        local t = reporter.create(dsn, website_id)
        t.screen("title")
        t.screen("character_selection")

        assert_equal(2, #mocked_queue_items)
        assert_same({
          dsn = dsn,
          type = "pageview",
          payload = {
            hostname = hostname,
            language = language,
            screen = screen_size,
            url = "/title?project_version=1.0.0&engine_version=1.3.5",
            website = website_id,
          },
        }, mocked_queue_items[1])
        assert_same({
          dsn = dsn,
          type = "pageview",
          payload = {
            hostname = hostname,
            language = language,
            screen = screen_size,
            url = "/character_selection?project_version=1.0.0&engine_version=1.3.5",
            website = website_id,
          },
        }, mocked_queue_items[2])
      end)
    end)

    describe("event", function()
      it("tracks events", function()
        local t = reporter.create(dsn, website_id)
        t.event("button_press", { name = "Play" })
        t.event("button_press", { name = "Settings" })
        t.event("checkbox_press", { name = "Disable shaders" }, "settings")

        assert_equal(3, #mocked_queue_items)
        assert_same({
          dsn = dsn,
          type = "event",
          payload = {
            event_name = "button_press",
            event_data = { name = "Play" },
            hostname = hostname,
            language = language,
            screen = screen_size,
            url = "/?project_version=1.0.0&engine_version=1.3.5",
            website = website_id,
          },
        }, mocked_queue_items[1])
        assert_same({
          dsn = dsn,
          type = "event",
          payload = {
            event_name = "button_press",
            event_data = { name = "Settings" },
            hostname = hostname,
            language = language,
            screen = screen_size,
            url = "/?project_version=1.0.0&engine_version=1.3.5",
            website = website_id,
          },
        }, mocked_queue_items[2])
        assert_same({
          dsn = dsn,
          type = "event",
          payload = {
            event_name = "checkbox_press",
            event_data = { name = "Disable shaders" },
            hostname = hostname,
            language = language,
            screen = screen_size,
            url = "/settings?project_version=1.0.0&engine_version=1.3.5",
            website = website_id,
          },
        }, mocked_queue_items[3])
      end)
    end)

    describe("error", function()
      it("tracks errors", function()
        local t = reporter.create(dsn, website_id)
        t.error("error 1")
        t.error("error 2")

        assert_equal(2, #mocked_queue_items)
        assert_same({
          dsn = dsn,
          type = "event",
          payload = {
            event_name = "error",
            event_data = { message = "error 1" },
            hostname = hostname,
            language = language,
            screen = screen_size,
            url = "/?project_version=1.0.0&engine_version=1.3.5",
            website = website_id,
          },
        }, mocked_queue_items[1])
        assert_same({
          dsn = dsn,
          type = "event",
          payload = {
            event_name = "error",
            event_data = { message = "error 2" },
            hostname = hostname,
            language = language,
            screen = screen_size,
            url = "/?project_version=1.0.0&engine_version=1.3.5",
            website = website_id,
          },
        }, mocked_queue_items[2])
      end)
    end)

    describe("crash", function()
      it("tracks crashes", function()
        local t = reporter.create(dsn, website_id)
        t.crash("crash 1")
        t.crash("crash 2")

        assert_equal(2, #mocked_queue_items)
        assert_same({
          dsn = dsn,
          type = "event",
          payload = {
            event_name = "crash",
            event_data = { data = "crash 1" },
            hostname = hostname,
            language = language,
            screen = screen_size,
            url = "/?project_version=1.0.0&engine_version=1.3.5",
            website = website_id,
          },
        }, mocked_queue_items[1])
        assert_same({
          dsn = dsn,
          type = "event",
          payload = {
            event_name = "crash",
            event_data = { data = "crash 2" },
            hostname = hostname,
            language = language,
            screen = screen_size,
            url = "/?project_version=1.0.0&engine_version=1.3.5",
            website = website_id,
          },
        }, mocked_queue_items[2])
      end)
    end)

    describe("toggle_error_crash_reporting", function()
      it("enables automatic error reporting", function()
        local error_handler
        sys.set_error_handler.replace(function(handler)
          error_handler = handler
        end)

        local t = reporter.create(dsn, website_id)
        t.toggle_error_crash_reporting(true)
        error_handler("lua", "message", "traceback")

        assert_equal(1, #mocked_queue_items)
      end)

      it("forwards errors when automatic error reporting is enabled", function()
        local on_error_invoked = false
        local function on_error()
          on_error_invoked = true
        end

        local error_handler
        sys.set_error_handler.replace(function(handler)
          error_handler = handler
        end)

        local t = reporter.create(dsn, website_id)
        t.toggle_error_crash_reporting(true, on_error, nil)
        error_handler("lua", "message", "traceback")

        assert_equal(1, #mocked_queue_items)
        assert_true(on_error_invoked)
      end)

      it("enables automatic crash reporting", function()
        if crash == nil then
          return
        end

        local t = reporter.create(dsn, website_id)
        crash.write_dump()
        t.toggle_error_crash_reporting(true)

        assert_equal(1, #mocked_queue_items)
      end)

      it("forwards crashes when automatic crash reporting is enabled", function()
        if crash == nil then
          return
        end

        local on_crash_invoked = false
        local function on_crash()
          on_crash_invoked = true
        end

        local t = reporter.create(dsn, website_id)
        crash.write_dump()
        t.toggle_error_crash_reporting(true, nil, on_crash)

        assert_equal(1, #mocked_queue_items)
        assert_true(on_crash_invoked)
      end)
    end)
  end)
end
