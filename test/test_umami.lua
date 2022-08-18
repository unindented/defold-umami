return function()
  local mock = require("deftest.mock.mock")
  local mock_fs = require("deftest.mock.fs")

  describe("umami", function()
    local umami
    local queue
    local reporter

    local mocked_sys_config_values

    before(function()
      umami = require("umami.umami")
      queue = require("umami.internal.queue")
      reporter = require("umami.reporter")

      mock.mock(sys)
      mock.mock(queue)
      mock.mock(reporter)

      mock_fs.mock()

      mocked_sys_config_values = {}
      sys.get_config.replace(function(key, default)
        local value = mocked_sys_config_values[key]
        if value and type(value) == "string" then
          return value
        elseif value ~= nil and type(value) ~= "string" then
          return default
        else
          return sys.get_config.original(key, default)
        end
      end)
    end)

    after(function()
      package.loaded["umami.internal.queue"] = nil
      package.loaded["umami.umami"] = nil
      package.loaded["umami.reporter"] = nil

      mock.unmock(sys)
      mock.unmock(queue)
      mock.unmock(reporter)

      mock_fs.unmock()
    end)

    describe("get_default_reporter", function()
      it("returns a default reporter instance", function()
        local t = umami.get_default_reporter()
        assert_not_nil(t)
        assert_equal(t, umami.get_default_reporter())
      end)

      it("reads DSN from `game.project`", function()
        mocked_sys_config_values["umami.dsn"] = "https://my-umami.vercel.app"
        local t = umami.get_default_reporter()
        assert_not_nil(t)
        assert_equal("https://my-umami.vercel.app", reporter.create.params[1])
      end)

      it("reads website ID from `game.project`", function()
        mocked_sys_config_values["umami.website_id"] = "ace8426d-8e00-4a2f-bf62-e28d8d5d68cf"
        local t = umami.get_default_reporter()
        assert_not_nil(t)
        assert_equal("ace8426d-8e00-4a2f-bf62-e28d8d5d68cf", reporter.create.params[2])
      end)

      it("reads dispatch interval from `game.project`", function()
        mocked_sys_config_values["umami.dispatch_interval"] = "12345"
        package.loaded["umami.umami"] = nil
        umami = require("umami.umami")
        assert_equal(12345, umami.dispatch_interval)
      end)

      it("uses a default dispatch interval if none is provided in `game.project`", function()
        mocked_sys_config_values["umami.dispatch_interval"] = false
        package.loaded["umami.umami"] = nil
        umami = require("umami.umami")
        assert_equal(1, umami.dispatch_interval)
      end)

      it("reads save interval from `game.project`", function()
        mocked_sys_config_values["umami.save_interval"] = "12345"
        package.loaded["umami.umami"] = nil
        umami = require("umami.umami")
        assert_equal(12345, umami.save_interval)
      end)

      it("uses a default save interval if none is provided in `game.project`", function()
        mocked_sys_config_values["umami.save_interval"] = false
        package.loaded["umami.umami"] = nil
        umami = require("umami.umami")
        assert_equal(30, umami.save_interval)
      end)
    end)

    describe("dispatch", function()
      it("dispatches items", function()
        umami.dispatch()
        assert_equal(1, queue.dispatch.calls)
      end)
    end)

    describe("save", function()
      it("saves items", function()
        umami.save()
        assert_equal(1, queue.save.calls)
      end)
    end)

    describe("update", function()
      it("dispatches items at regular intervals", function()
        mocked_sys_config_values["umami.dispatch_interval"] = "3"
        package.loaded["umami.umami"] = nil
        umami = require("umami.umami")

        umami.update(2)
        assert_equal(0, queue.dispatch.calls)
        umami.update(1)
        assert_equal(1, queue.dispatch.calls)
        umami.update(3)
        assert_equal(2, queue.dispatch.calls)
      end)

      it("doesn't dispatch items if set to manually dispatch them", function()
        mocked_sys_config_values["umami.dispatch_interval"] = "0"
        package.loaded["umami.umami"] = nil
        umami = require("umami.umami")

        umami.update(1)
        assert(queue.dispatch.calls == 0)
      end)
    end)
  end)
end
