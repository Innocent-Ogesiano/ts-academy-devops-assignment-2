# ts-academy-devops-assignment-2

A Dockerized diagnostic CLI. `diagnostic.sh` reports basic Linux system, disk,
and network information from inside a lightweight Alpine-based container.

## Project structure

```
.
├── README.md
├── app/
│   ├── diagnostic.sh      # the CLI
│   └── health-check.sh    # Docker HEALTHCHECK script
├── Dockerfile
├── compose.yaml
├── .dockerignore
├── test.sh                # integration tests against the built image
└── grade.sh
```

## Installation / Setup

Requires Docker (and Docker Compose, bundled with modern Docker Desktop/CLI).

Build the image:

```bash
docker build -t diagnostic-tool .
```

Or build it via Compose:

```bash
docker compose build
```

## Usage

### Commands

| Command                | Description                                   |
|-------------------------|-----------------------------------------------|
| `system`                | Display OS, kernel, CPU, and memory info      |
| `network <host>`        | Ping the given host and report reachability   |
| `disk`                  | Display disk usage (`df -h`)                  |
| `help`                  | Show usage information                        |

### Exit codes

| Code | Meaning                        |
|------|---------------------------------|
| `0`  | Success                        |
| `1`  | Operational/runtime failure (e.g. host unreachable) |
| `2`  | Invalid command or missing/invalid input |

### Run with `docker run`

```bash
docker run --rm diagnostic-tool system
docker run --rm diagnostic-tool disk
docker run --rm diagnostic-tool network 8.8.8.8
docker run --rm diagnostic-tool help
```

Running the image with no arguments defaults to `help`.

### Run with Docker Compose

```bash
docker compose run --rm diagnostic system
docker compose run --rm diagnostic disk
docker compose run --rm diagnostic network 8.8.8.8
docker compose run --rm diagnostic help
```

### Run the script directly (without Docker)

`diagnostic.sh` and `health-check.sh` are plain Bash scripts and can be run
on any Linux host without Docker:

```bash
chmod +x app/diagnostic.sh
./app/diagnostic.sh system
```

## Testing

`test.sh` builds the image and exercises it via `docker run`, asserting on
exit codes and output for `help`, `system`, `disk`, invalid commands,
missing arguments, and both reachable/unreachable `network` targets.

```bash
./test.sh
```

Set `SKIP_BUILD=1` to reuse an already-built `diagnostic-tool` image instead
of rebuilding:

```bash
SKIP_BUILD=1 ./test.sh
```

The script prints a `PASS`/`FAIL` line per assertion, a summary count, and
exits `0` only if every assertion passed.

## Assumptions

- **Target platform is Linux.** The scripts are written for and tested
  against Linux (Debian and Alpine, both under Docker); they are not
  expected to run correctly on macOS/BSD `ping`/`df` variants outside of a
  container.
- **The container image is Alpine-based** (`alpine:3.20`) for a small
  footprint. `bash` is installed explicitly since Alpine does not ship it
  by default; all other functionality relies on BusyBox utilities already
  present in the base image (`ping`, `df`, `hostname`, etc.), so no other
  packages are installed.
- **`network <host>` uses ICMP ping** (`ping -c 3`) as the sole
  connectivity check. A host that blocks ICMP but is otherwise reachable
  (e.g. over HTTP) will be reported as unreachable (exit code `1`). Running
  the container without `NET_RAW`/ICMP permissions in restrictive
  environments may also affect this check.
- **No persistent state or volumes are required.** The CLI is a stateless,
  one-shot diagnostic tool — `compose.yaml` intentionally has no volumes,
  ports, or environment configuration beyond the build.
- **`system`/`disk` fields degrade gracefully** when optional tools are
  unavailable (e.g. `uptime`, `nproc`) rather than failing the whole
  command, since these are informational, not correctness-critical.
