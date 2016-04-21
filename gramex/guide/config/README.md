title: Configurations control Gramex

All features of Gramex are controlled by `gramex.yaml`. It has the following
optional sections:

    app: ...        # Main app configuration
    url: ...        # Map URLs to files or functions
    log: ...        # Logging configuration
    schedule: ...   # Scheduled tasks
    mime: ...       # Custom mime type definitions
    variables: ...  # Custom variable definition

Here's a simple `gramex.yaml` that serves the file `html.html` as the home page.

    url:                            # URL configuration section
        root:                       # Add a configuration called "root"
            pattern: /              # It maps the URL / (the home page)...
            handler: FileHandler    # ... to a Gramex FileHandler
            kwargs:                 # ... and passes it these arguments:
                path: home.html     # Use home.html as the path to serve

# Configuration syntax

This section is meant more as a **reference**. Skim through it, and return later
for additional information.

## App configuration

The `app:` section controls Gramex's startup. It has these sub-sections.

1. `browser:` is the URL to open when Gramex is launched. (default: `False`)
2. `listen:` holds keyword arguments for the HTTP server. The most important
   parameter is the `port:` (default: 9988.) The remaining parameters are passed
   to [HTTPServer()][http://www.tornadoweb.org/en/stable/_modules/tornado/httpse
   rver.html#HTTPServer].
3. `settings:` holds the Tornado
   [application settings](http://www.tornadoweb.org/en/stable/web.html#tornado.web.Application.settings).

These are the parameters you will use the most:

    app:
        browser: /                        # Open browser to "/" when app starts
        listen:
            port: 9999                    # Run on a different port
        settings:
            debug: True                   # Run in debug mode instead of production mode
            cookie_secret: your-secret    # A unique secret ID for your application

## Command line

The app section alone can be over-ridden from the command line. (Other sections
cannot.) For example:

    gramex --listen.port=8888 --browser=/

... will override the `gramex.yaml` parameters for the `port` and `browser`.

## URLs

The `url:` section maps URLs to content. Here is an example:

    url:
        homepage:                           # A unique name for this mapping
            pattern: /                      # Map the URL /
            handler: FileHandler            # using a built-in FileHandler
            kwargs:                         # Pass these options to FileHandler
                path: $YAMLPATH/index.html  # Show the index.html in the same directory as this YAML file

        hello:                              # A unique name for this mapping
            pattern: /hello                 # Map the URL /hello
            handler: FunctionHandler        # using the build-in FunctionHandler
            kwargs:                         # Pass these options to FunctionHandler
                function: str               # Run the str() function
                args: Hello                 # with the argument "Hello"

The `url:` section is a name - mapping dictionary. The names are just unique
identifiers. The mappings have these keys:

- `pattern`: a regular expression that matches the URL. For example,
  `/blog/(.*)` matches all pages starting with `/blog/`. Any parts of the URL in
  brackets are passed to the handler as arguments.
- `handler`: The name of the Tornado [RequestHandler][requesthandler] to run.
  Gramex provides these by default:
    - [FunctionHandler](../functionhandler/): runs any function and renders the output
    - [FileHandler](../filehandler/): transforms & displays files
    - [DataHandler](../datahandler/): renders data from databases or files
- `kwargs`: Keyword arguments to pass to the handler. The arguments varies by handler.
- `priority`: A number indicating the priority. By default, the mapping has a
  priority of 0. Use 1, 2, etc for higher priority, -1, -2, etc for lower
  priority. Mappings with a higher priority override those with lower priority.

You an write your own handler by extending [RequestHandler][requesthandler]. For
example, create a file called `hello.py` with the following content:

    from tornado.web import RequestHandler

    class Hello(RequestHandler):
        def get(self):
            self.write('hello world')

Now, you can use `handler: hello.Hello` to send the response `hello world`.




[requesthandler]: http://tornado.readthedocs.org/en/latest/web.html#request-handlers

## Logging

The `log:` section defines Gramex's logging behaviour. It uses the same
structure as the [Python logging schema][logging-schema]. This example only
displays warning messages on the console:

    log:
        root:
            level: WARN
            handlers:
                - console

Gramex offers a pre-defined handler called `console`. You can define your own
handlers under the `log:` section. Here is a handler that write information logs
into `info.log`, backing it up daily:

    handlers:
        info:
            class: logging.handlers.TimedRotatingFileHandler
            level: INFO
            formatter: file         # save it as a CSV file
            filename: info.log      # file name to save as
            encoding: utf-8         # encoded as UTF-8
            when: D                 # rotate the log file day-wise
            interval: 1             # every single day
            utc: False              # using local time zone, not UTC
            backupCount: 30         # keep only last 30 backups

This handler wrings warnings into warn.log, letting it grow up to 10 MB, then
archiving it into warn.log.1, etc.

    handlers:
        warnings:
            class: logging.handlers.RotatingFileHandler
            level: WARN
            formatter: file         # save it as a CSV file
            filename: warn.log      #
            encoding: utf-8         # encoded as UTF-8
            maxBytes: 10485760      # limit the file to up to 10MB
            backupCount: 3          # keep the last 3 backups

The `file` formatter is defined in Gramex, and saves the output as a CSV file.
Here is its definition:

    formatters:
        file:
            format: '%(levelname)1.1s,%(asctime)s,%(module)s,%(lineno)d,"%(message)s"'
            datefmt: '%Y-%m-%d %H:%M:%S'

You can create your own formatters in a similar way.

[logging-schema]: https://docs.python.org/3/library/logging.config.html#dictionary-schema-details

## Scheduling

The `schedule:` section schedules functions to run at specific times or on
startup. It has a name - schedule mapping. The names are unique identifiers. The
schedules have the following keys:

- `function:` name of the function to run
- `args:` positional arguments for the function. By default, nothing is passed
- `kwargs:` keyword arguments for the function. By default, nothing is passed
- `startup`: True to run the function on startup (default: False)

It also accepts a timing that is based on the [crontab format][crontab]. Here is
an example:

- `years`: 2016-2019            # From year 2016 - 2019
- `months`: 'jan, mar-may, 12'  # In Jan, Mar, Apr, May, Dec
- `dates`: '1, L'               # On the first and last days
- `weekdays`: '*'               # 0-6 or SUN-SAT
- `hours`: '*/3'                # Every 3rd hour
- `minutes`: '*/5, 59'          # Every 5th minute, and 59th minute

See the [scheduler](../scheduler/) documentation for examples.

[crontab]: https://en.wikipedia.org/wiki/Cron#Format

## MIME types

The `mime:` section lets you add custom MIME types for extensions. For example:

    mime:
        .yml: text/yaml

... maps the `.yml` extension to the `text/yaml` MIME type. This is used by
[FileHandler](../filehandler/) and other services to set the `Content-Type`
header.

## Imports

One config file can import another. For example:

    import:
        app1: 'app1/gramex.yaml'      # import this YAML file (relative path)
        app2: 'd:/temp/gramex.yaml'   # import this YAML file (absolute path)
        subapps: '*/gramex.yaml'      # import gramex.yaml in any subdirectory
        deepapps: '**/gramex.yaml'    # import gramex.yaml from any subtree

The keys `app1`, `app2`, etc. are just identifiers, not used for anything.
The values must be YAML files. These are loaded in order. After loading, the
`import:` section is removed.

If a file is missing, Gramex proceeds with a warning.

UNIX shell style wildcards work. `*` matches anything, and `**` matches all
subdirectories.

Imports work recursively. You can have imports within imports.

## Variables

Templates can use variables. Variables are written as `$VARIABLE` or
`${VARIABLE}`. All environment variables are available as variables by default.
For example:

    import:
      home_config: $HOME/gramex.yaml    # imports gramex.yaml from your home directory

You can define or override variables using the `variables:` section like this:

    variables:
      URLROOT: "/site"                  # Define $URLROOT
      HOME: {default: "/home"}          # Define $HOME if not defined earlier
      PATH: $URLROOT/path               # Define $PATH based on $URLROOT

`$URLROOT` is set to `/site`. If the variable was defined earlier in another
YAML file or the environment, that value is lost.

`$HOME` is set to `/home` *only if* it was not already defined. It *defaults* to
home, but does not override a previous value.

`$PATH` is set to `/site/path`. Its value is based on the previously defined
`$URLROOT`.

### Computed variables

Variables can also be computed. For example, this runs `utils.get_root` to
assign `$URLROOT`:

    variables:
      URLROOT:
        function: utils.get_root

By default, the function is called with the variable name as key, i.e.
`utils.get_root(key='URLROOT')`. But you can specify any arguments. For example,
this calls `utils.get_root('URLROOT', 'test', x=1)`:

    variables:
      URLROOT:
        function: utils.get_root
        args: [=key, 'test']
        kwargs: {x: 1}

Computed variables can also use defaults. For example, this assigns `get_home()`
to `$HOME` only if it's not already defined.

    variables:
      HOME:
        function: utils.get_home
        args: []

(Note: The function arguments cannot be variables as of now.)

Once the variables are assigned, the `variables` section is removed.

### Pre-defined variables

The following pre-defined variables are available in every YAML file:

- `YAMLFILE`: absolute path to the current YAML file
- `YAMLPATH`: absolute path to the current YAML file's directory
- `YAMLURL`: relative path to the current YAML file's directory from the
  current working directory. For example, `base/dir/gramex.yaml` has a
  `$YAMLURL` of `base/dir`.


## Inheritence

Configurations can be overwritten. For example:

    a: 1          # This is defined first
    a: 2          # ... but this overrides it

will only use the second line.

Imports over-write the entire key. For example, if `a.yaml` has:

    key:
      x: 1
      y: 2
    import:
      child: b.yaml

... and `b.yaml` has:

    key:
      z: 3

... the final `key` will only have `z: 3`.

Gramex uses 3 different configuration files. The first is Gramex's own
`gramex.yaml`. The second is the application's. The third is the command line.
These *update* keys, rather than overwriting them. For example, Gramex's
`gramex.yaml` has the following `url:` section:

    url:
        default:
            pattern: /(.*)
            ...

When your `gramex.yaml` uses a `url:` section like this:

    url:
        homepage:
            pattern: /
            ...

... the final URL section will have both the `default` and the `homepage` keys.
If the application uses the same key as Gramex's `gramex.yaml`, the latter will
be overwritten.

## Access

Configurations are available in `gramex.conf`. For example, this will print the
computed value of applications port:

    import gramex
    print(gramex.conf.app.listen.port)

`gramex.conf` is meant for reading. Do not change its value.

You can see this applications `gramex.conf` at [/config](../config)

If the underlying YAML files change, then `gramex.init()` is automatically
reloaded and all services are re-initialized.