# Umami Analytics for Defold

This [Defold](http://www.defold.com) library allows sending analytics events to [Umami](https://umami.is). It is heavily inspired by [Google Analytics for Defold](https://github.com/britzl/defold-googleanalytics).

## Installation

You can use this library in your own project by adding it as a [Defold library dependency](http://www.defold.com/manuals/libraries/). Open your `game.project` file and in the dependencies field under project add:

```
https://github.com/unindented/defold-umami/archive/master.zip
```

Or point to the ZIP file of a [specific release](https://github.com/unindented/defold-umami/releases).

## Configuration

Before you can use this library in your project, you need to specify your host and website ID in `game.project`. Open `game.project` as a text file, and create a new section:

```ini
[umami]
dsn = https://my-umami.vercel.app
website_id = ace8426d-8e00-4a2f-bf62-e28d8d5d68cf
```

Additional optional values are:

```ini
[umami]
dispatch_interval = 1
save_interval = 30
verbose = 1
```

- `dispatch_interval` is the interval, in seconds, at which analytics data is sent to the server.
- `save_interval` is the minimum interval, in seconds, at which analytics data is saved to disk.
- `verbose` set to `1` will print some additional data. Set to `0` or omit the value to not print anything.

## Usage

Once you have added your host and website ID in `game.project` you're all set to start sending analytics data:

```lua
local umami = require "umami.umami"

function init(self)
  umami.get_default_reporter().screen("my_cool_screen")
end

function update(self, dt)
  umami.update(dt)
end

function on_input(self, action_id, action)
  if gui.pick_node(node1, action.x, action.y) and action.pressed then
    umami.get_default_reporter().event("button_press", { name = "Play" })
  end
end
```

## Automatic error/crash reporting

You can let Umami automatically send analytics data when your app throws errors or crashes. The library can handle Lua errors using [`sys.set_error_handler`](http://www.defold.com/ref/sys/#sys.set_error_handler:error_handler), and hard crashes using [the `crash` API](http://www.defold.com/ref/crash/). Enable automatic error/crash reporting like this:

```lua
local umami = require "umami.umami"

function init(self)
  umami.get_default_reporter().enable_error_crash_reporting(true)
end
```

## Running unit tests

You can run unit tests for this project with `make test-<platform>`. For example:

```
make test-macos
```

If you want to run unit tests as you change files, try [`entr`](https://github.com/eradman/entr):

```
find umami -type f | entr sh -c 'make test-macos'
```

## License

Copyright (c) 2022 Daniel Perez Alvarez ([unindented.org](https://www.unindented.org/)). This is free software, and may be redistributed under the terms specified in the LICENSE file.
