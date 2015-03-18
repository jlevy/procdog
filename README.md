# procdog

## Lightweight command-line process control

Procdog is a simple command-line tool to start, stop, and check the health of
processes. It works with any kind of process you can invoke from the command
line (be it Java, Node, Python, or anything).

It is intended to be a very simple and easy-to-use alternative to more
full-featured deployment tools (such as [Monit](http://mmonit.com/monit/)),
and to be cross-platform, unlike traditional OS-specific tools
(such as [start-stop-daemon](http://manpages.ubuntu.com/manpages/karmic/man8/start-stop-daemon.8.html)
and [Upstart](http://upstart.ubuntu.com/)). The kind of thing needed when
developing locally, in build systems and test harnesses, etc.

It operates by starting a small daemon that `popen()`s and monitors the process.
The daemon listens and accepts commands on a local Unix domain socket, making
it possible to check the process is running or terminate it, and to do simple
health checks. For simplicity, there is a single Procdog daemon for each
monitored process, so each process is handled compeltely separately.

It supports an arbitrary command to test health, so for example, you can `curl`
a given URL to verify the process is running. It also has options for "strict"
usage, so you know if a process is unexpectedly started or unexpectedly stopped,
and allows you to ensure a process is healthy before proceeding -- for example,
if Procdog is used within a script or build file.

Procdog is quite new so probably not stable. Bug reports and contributions are welcome.

## Requirements and Installation

Requires Python 2.7. Tested on MacOS and Linux. Just copy the `procdog` file. 

## Usage

Run `procdog -h` for help.

### Quick example

```
$ ./procdog start myprocess --command "sleep 20"
running, pid=14969
$ ./procdog status myprocess
running, pid=14969
$ ./procdog stop myprocess
stopped
$
```

Here `myprocess` is an arbitrary identifier that you use for this process, like a Unix service name. Once the process is done, the monitor daemon also exits.

### A more useful example

```
$ procdog start backend --command "java -cp my-backend.jar com.example.BackendServer server dw-config.yml" \
  --health-command "curl http://localhost:8080/ping" \
  --health-count=10 --health-delay=2 \
  --stdout=backend.log --stderr=backend.log --append \
  --ensure-healthy --strict
running, health=0, pid=15240
[levy@spud5 Six5 (server-harness)]$ procdog status backend
running, health=0, pid=15240
$ procdog stop backend --strict
stopped
$ procdog stop backend --strict
procdog: error: process 'backend' is not running
```

Some notes on this:

- We can specify where to write stdout and stderr. (They can be the same or different.) Existing files are appended to (`--append`).
- The health command simply calls `curl` to see if the server is listening. The return code of this must be `0` (i.e. in the case of `curl`, an HTTP 200 status) for the server to be considered healthy.
- The ``--ensure-healthy`` option means the command will block until the process is healthy, or until the daemon gives up and kills the process (if necessary). In this example, it will try 10 times, sleeping 2 seconds each time, before giving up.
- We ask the client to be strict, so that it returns non-zero status code when we try to start a process that's already running or or stop one that is already stopped.

### Using a configuration file

It's possible to avoid typing by putting most options in a configuration file. Put a file named `procdog.cfg` in the same directory as `procdog`:

```
# Procdog config file. Each section is a process identifier.
[backend]
command=java -cp my-backend.jar com.example.BackendServer server dw-config.yml
health_command=curl http://localhost:8080/ping
health_count=10
health_delay=2.
stdout=backend.log
stderr=backend.log
append=False
ensure_healthy=True
strict=True
```

Now you can simply run:

```
$ procdog start backend
running, health=0, pid=15396
$ procdog stop backend
stopped
$
```

Procdog reads options from `~/.procdog.cfg` or `procdog.cfg` (in the same directory the `procdog` script resides). Any options given on the command line override those in the configuration file.

See `tests/tests.sh` for more examples.

## Tests

All basic features are covered with a simple Bash-based regression tests.

To run, git clone this repo, invoke `tests/run.sh` then follow the directions to diff the output using `git`.

## License

[Apache 2](https://github.com/jlevy/procdog/blob/master/LICENSE).


