return function()
  local mock = require("deftest.mock.mock")
  local mock_fs = require("deftest.mock.fs")
  local file = require("umami.internal.file")

  describe("queue", function()
    local dsn = "https://my-umami.vercel.app"

    local queue
    local http_history
    local http_status

    before(function()
      mock.mock(http)

      http_history = {}
      http_status = 200

      http.request.replace(function(url, method, callback, headers, post_data, options)
        table.insert(http_history, {
          url = url,
          method = method,
          callback = callback,
          headers = headers,
          post_data = post_data,
          options = options,
        })
        if callback then
          callback({}, "id", { status = http_status, response = "", headers = {} })
        end
      end)

      mock_fs.mock()

      queue = require("umami.internal.queue")
    end)

    after(function()
      package.loaded["umami.internal.queue"] = nil

      mock.unmock(http)

      mock_fs.unmock()
    end)

    describe("dispatch", function()
      it("sends requests to Umami", function()
        queue.add(dsn, "pageview", { url = "/title" })
        queue.add(dsn, "pageview", { url = "/settings" })
        queue.add(dsn, "event", {
          event_name = "checkbox_press",
          event_data = { name = "Disable shaders" },
          url = "/settings",
        })
        assert_equal(0, #http_history)

        queue.dispatch()
        queue.dispatch()
        queue.dispatch()
        assert_equal(3, #http_history)

        assert_equal(dsn .. "/api/collect", http_history[1].url)
        assert_same(
          json.decode('{"type":"pageview","payload":{"url":"/title"}}'),
          json.decode(http_history[1].post_data)
        )
        assert_equal(dsn .. "/api/collect", http_history[2].url)
        assert_same(
          json.decode('{"type":"pageview","payload":{"url":"/settings"}}'),
          json.decode(http_history[2].post_data)
        )
        assert_equal(dsn .. "/api/collect", http_history[3].url)
        assert_same(
          json.decode(
            '{"type":"event","payload":{"event_name":"checkbox_press","event_data":{"name":"Disable shaders"},"url":"/settings"}}'
          ),
          json.decode(http_history[3].post_data)
        )
      end)
    end)

    describe("save", function()
      it("saves items to disk", function()
        local path = file.save_path("__umami_queue")
        queue.add(dsn, "pageview", { url = "/title" })
        assert_false(mock_fs.has_file(path))
        queue.save()
        assert_true(mock_fs.has_file(path))
      end)
    end)
  end)
end
