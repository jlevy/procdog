# procdog

## Lightweight command-line process control

Procdog (as in "**proc**ess watch**dog**"... get it?)
is a simple command-line tool to start, stop, and check the health of
processes. It works with any kind of process you can invoke from the command
line (be it native, Java, Node, Python, or anything) on MacOS or Linux.

Why would you want another tool for this?

- For basic interactive situations, you can just run a process in a terminal
  or use job management in your shell (`jobs`, `kill`, etc.).
- But you rapidly realize this won't work well once you have longer-lived processes
  or are `ssh`ing to remote servers. Then you could use `nohup` and manually
  checking with `ps`, or using [screen](http://en.wikipedia.org/wiki/GNU_Screen).
  But these don't script easily.
- You also might want to script starting and stopping.
  With a little effort you might write a custom Bash script (writing a PID file,
  using `pgrep` and `pkill`, etc.), but it's a hassle and gets messy quickly.
- Of course, you can just "do it right." Traditionally, in the Unix world, the way to
  control services are
  [System V service scripts](http://manpages.ubuntu.com/manpages/trusty/man8/service.8.html),
  [start-stop-daemon](http://manpages.ubuntu.com/manpages/karmic/man8/start-stop-daemon.8.html),
  [Upstart](http://upstart.ubuntu.com/), or
  [systemd](http://www.freedesktop.org/wiki/Software/systemd/).
  Using these is essential for production deployment, but they tend to be a bit arcane
  and highly OS-dependent, so aren't as convenient for casual use, and you can't easily
  develop and test on both MacOS and Linux (as many of us try to do).

Procdog is an alternative for developers that attempts to be easy to install,
simple and obvious to use, and cross-platform. Processes are independent of the
shell used to invoke them (i.e., detatched as with `nohup`) and you can also check
status or kill them at any time (as with a Unix service).

Probably the most simlar tool to Procdog is [Supervisor](https://github.com/Supervisor/supervisor).
Although it has similar goals, Supervisor is a more complex, production-oriented tool with a
long-lived, centrailized XML-RPC server that monitors processes. Procdog is intended
to be a single, simple, easy-to-use command that needn't be set up and managed itself
or run as root. Each use of Procdog is independent and monitors just one process. It
does not require a configuration file unless you want to save typing. You can even
check the Procdog script into your own project so developers can immediately use it
locally, since it has no dependencies (besides Python 2.7).

You'll find it useful if you have servers, databases, or other processes you want
to manage on your personal machine when developing, in build systems and test
harnesses, test deployments, etc. Currently, it *doesn't* have restart
logic, log file rotation, or some other features you may want for a production
environments; for this consider Supervisor, Upstart, systemd, & co. Procdog is
also *way* less mature than these alternatives.

## Installation

No dependencies except Python 2.7+. It's easiest to install with pip:

    sudo pip install procdog

Or, since it's just one file, you can copy the single
[`procdog`](https://github.com/jlevy/procdog/blob/master/procdog)
script somewhere (perhaps within your own project) and make it executable.

## Quick start

Now you can start and monitor any process (here let's pick "sleep" -- not all that
useful, but you already have it):

```
$ procdog start myprocess --command "sleep 100"
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

Run `procdog -h` for help on all options.

## A better example

Now, with a real server we'd like to know if it's actually up and doing something,
like listening on a port. Procdog supports an arbitrary command to test health
(e.g. running `curl` to see if it returns a result) and can wait until a server
is running and tell you.

```
$ procdog start backend --command="java -classpath my-backend.jar com.example.BackendServer server config.yml" \
  --health-command="curl http://localhost:8080/ping" \
  --health-count=10 --health-delay=2 \
  --dir=$HOME/backend \
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
- The `--ensure-healthy` option means the command will block until the process is healthy,
  or until the daemon gives up and kills the process (if necessary). In this example,
  it will try 10 times, sleeping 2 seconds each time, before giving up.
- The `--dir` option means process will run from that directory.
- We ask the client to be `--strict`, so that it returns non-zero status code when we try to
  start a process that's already running or or stop one that is already stopped.

## Configuration files

It's possible to avoid typing by putting most options in a configuration file:

```
# Procdog config file. Each section is a process name.
[backend]
command=java -classpath my-backend.jar com.example.BackendServer server config.yml
health_command=curl http://localhost:8080/ping
health_count=10
health_delay=2.
dir=$HOME/backend
stdout=backend.log
stderr=backend.log
append=False
ensure_healthy=True
strict=True
```

You have any number of sections, one section per process. Procdog reads options
from `~/.procdog.cfg` or `procdog.cfg` (in the same directory the `procdog`
script resides). Any options given on the command line override those in the
configuration file. Note that environment variables (like `$HOME`) are
allowed and expanded. Once you have the above section in your config file,
you can run:

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
health checks. You can see these sockets at `/var/tmp/procdog.*.sock` (where the * is the
id of the process). For simplicity, there is a single Procdog daemon for each monitored
process, so each process is handled compeltely separately.

We use Unix domain sockets so that we don't have the headaches of pid files or
choosing and binding to TCP ports. They're also available on most platforms.

Daemon logs are sent to `/var/tmp/procdog.*.log`. Usually you'll want to redirect your
process stdout and stderr using the `--stdout` and `--stderr` options.

Procdog is quite new so probably not stable. Bug reports and contributions are welcome!

## Tests

All basic features are covered with a simple Bash-based regression test.

To run it, clone this repo, invoke `tests/run.sh` then follow the directions to diff
the output using `git`.

## License

[Apache 2](https://github.com/jlevy/procdog/blob/master/LICENSE).
