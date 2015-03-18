# procdog

## Lightweight command-line process control

Procdog is a simple command-line tool to start, stop, and check the health of
processes. It works with any kind of process you can invoke from the command
line (be it Java, Node, Python, or anything) on MacOS or Linux. It's useful if
you have servers, databases, or other processes you want to manage on your
personal machine, when developing, in build systems and test harnesses, etc.

Why would you want this tool?

Traditionally, in the Unix world, the answers to controlling services and daemons
are Bash `/etc/rc.d` scripts,
[start-stop-daemon](http://manpages.ubuntu.com/manpages/karmic/man8/start-stop-daemon.8.html),
[Upstart](http://upstart.ubuntu.com/)), or
[systemd](http://www.freedesktop.org/wiki/Software/systemd/).
These are great for production deployment, but tend to be a bit arcane and highly
OS-dependent, so you can't easily develop and test on both MacOS and Linux
(as many of us try to do).
Another alternative is custom Bash scripts (writing PID files, using `pgrep` and `pkill`,
etc.), but this also gets platform-dependent and messy pretty quickly.

Procdog is an alternative for developers that tries to be easy to install, obvious
to use, and cross-platform.

## Installation

Copy the single [`procdog`](https://github.com/jlevy/procdog/blob/master/procdog)
file into your path. Requires Python 2.7.

## Quick start

Now you can start and monitor any process (here let's pick "sleep", since you already have
this). 

```
$ procdog start myprocess --command "sleep 20"
running, pid=14969
$ procdog status myprocess
running, pid=14969
$ procdog stop myprocess
stopped
$
```

Note you have to give your process an arbitrary name (`myprocess` here), like a Unix
service name, so you can refer to it. Once the process is done, the monitor daemon
also exits.

## Usage

Run `procdog -h` for all options.

Now, with a real server we'd like to know if it's actually up and doing something,
like listening on a port. Procdog supports an arbitrary command to test health
(e.g. running `curl` to see if it returns a result) and can wait until a server
is running and tell you.

### A better example

```
$ procdog start backend --command="java -classpath my-backend.jar com.example.BackendServer server config.yml" \
  --health-command="curl http://localhost:8080/ping" \
  --health-count=10 --health-delay=2 \
  --stdout=backend.log --stderr=backend.log --append \
  --ensure-healthy --strict
running, health=0, pid=15240
$ procdog status backend
running, health=0, pid=15240
$ procdog stop backend --strict
stopped
$ procdog stop backend --strict
procdog: error: process 'backend' is not running
$
```

Some notes on this:

- We can specify where to write stdout and stderr. They can be the same or different.
  Existing log files are appended to if you use `--append`.
- The health command simply calls a shell command to see if the server is healthy.
  The return code of the health check command must be `0` for the server to be considered
  healthy. In this case, we're callin `curl` on a known health-check URL, which will have
  return code 0 on an HTTP 200 
- The ``--ensure-healthy`` option means the command will block until the process is healthy,
  or until the daemon gives up and kills the process (if necessary). In this example,
  it will try 10 times, sleeping 2 seconds each time, before giving up.
- We ask the client to be strict, so that it returns non-zero status code when we try to
  start a process that's already running or or stop one that is already stopped.

### Configuration files

It's possible to avoid typing by putting most options in a configuration file:

```
# Procdog config file. Each section is a process identifier.
[backend]
command=java -classpath my-backend.jar com.example.BackendServer server config.yml
health_command=curl http://localhost:8080/ping
health_count=10
health_delay=2.
stdout=backend.log
stderr=backend.log
append=False
ensure_healthy=True
strict=True
```

Procdog reads options from `~/.procdog.cfg` or `procdog.cfg` (in the same directory the `procdog` script resides).
Any options given on the command line override those in the configuration file. Once you have the above
section in your config file, you can run:

```
$ procdog start backend
running, health=0, pid=15396
$ procdog stop backend
stopped
$
```

## How it works

Procdog starts a small daemon that `popen()`s and monitors the process.
The daemon listens and accepts commands on a local
[Unix domain socket](http://en.wikipedia.org/wiki/Unix_domain_socket),
making it possible to check the process is running or terminate it, and to do simple
health checks. You can see these sockets at `/var/tmp/procdog.*.sock`. For simplicity,
there is a single Procdog daemon for each monitored process, so each process is handled
compeltely separately.

We use Unix domain sockets so that we don't have the headaches of pid files or
choosing and binding to TCP ports. They're also available on most platforms.

Procdog is quite new so probably not stable. Bug reports and contributions are welcome.

## Tests

All basic features are covered with a simple Bash-based regression test.

To run it, clone this repo, invoke `tests/run.sh` then follow the directions to diff
the output using `git`.

## License

[Apache 2](https://github.com/jlevy/procdog/blob/master/LICENSE).


