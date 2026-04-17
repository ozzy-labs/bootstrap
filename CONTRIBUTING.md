# Contributing

This is a personal project maintained by [ozzy-labs](https://github.com/ozzy-labs). External contributions are not currently accepted.

## Bug Reports & Feature Requests

If you find a bug or have an idea for improvement, please open an issue.

## Testing

### Non-interactive mode

Set either environment variable to skip interactive prompts (useful in CI / Docker):

```bash
WSL_DEV_SETUP_ASSUME_YES=1 ./install.sh local    # explicit opt-in
CI=true ./install.sh local                        # auto-enabled in most CI systems
```

Behavior:

- `[Y/n]` prompts → auto `Y` (install)
- `[y/N]` prompts (Azure CLI / Google Cloud CLI / non-Ubuntu confirmation) → auto `N` (skip / abort)
- Git username/email: pre-configure via `git config --global user.{name,email}` beforehand to land on the "already configured" code path

### Local test execution

```bash
# L0: Smoke tests (~500ms, no network)
./tests/smoke/run.sh

# L2: BATS unit tests
mise exec -- bats tests/unit/

# L3: Docker integration tests (~5-10 min per version)
./tests/integration/run.sh                 # default: ubuntu:24.04
./tests/integration/run.sh 22.04 24.04     # multiple versions
./tests/integration/run.sh devel           # canary (next Ubuntu)
```

`tests/integration/run.sh` picks up `GITHUB_TOKEN` from either your environment
or `gh auth token` (if `gh` is installed). Forwarding it to the container raises
mise's GitHub API rate limit from 60 to 5000 requests/hour, which matters when
running the full suite multiple times in short succession.

## License

By interacting with this project, you agree that any contributions you make will be licensed under the [MIT License](LICENSE).
