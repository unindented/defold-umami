return function()
  local mock_fs = require("deftest.mock.fs")
  local file = require("umami.internal.file")

  describe("file", function()
    before(function()
      mock_fs.mock()
    end)

    after(function()
      mock_fs.unmock()
    end)

    describe("save_path", function()
      it("provides a full path to a save file", function()
        assert_match("foobar$", file.save_path("foobar"))
      end)
    end)

    describe("load", function()
      it("loads an existing file", function()
        local name1 = "foo"
        local name2 = "bar"
        file.save(name1, "some data")
        file.save(name2, "some other data")

        assert_equal("some data", file.load(name1))
        assert_equal("some other data", file.load(name2))
      end)

      it("doesn't crash when trying to load a file that doesn't exist", function()
        local data, err = file.load("foobar")

        assert_nil(data)
        assert_not_nil(err)
      end)
    end)

    describe("save", function()
      it("writes to a file", function()
        local name1 = "foo"
        local name2 = "bar"
        file.save(name1, "some data")
        file.save(name2, "some other data")

        assert_true(mock_fs.has_file(file.save_path(name1)))
        assert_true(mock_fs.has_file(file.save_path(name2)))
        assert_equal("some data", mock_fs.get_file(file.save_path(name1)))
        assert_equal("some other data", mock_fs.get_file(file.save_path(name2)))
      end)

      it("writes to a temporary file and then moves it if successful", function()
        file.save("foobar", "some data")

        assert_equal(1, os.rename.calls)
        assert_equal(1, os.remove.calls)
      end)

      it("doesn't write a partial file to disk", function()
        file.save("foobar", "some data")

        mock_fs.fail_writes(true)
        assert_error(function()
          file.save("foobar", "some other data")
        end)
        assert_equal("some data", mock_fs.get_file(file.save_path("foobar")))
      end)
    end)
  end)
end
