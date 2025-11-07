# k8s-proxy

A command-line tool to manage kubectl port-forwards to Kubernetes services. Uses kubectl v1.22 to work around the SSL/TLS connection reset bug introduced in kubectl v1.23+.

## Background

kubectl v1.23+ has a regression ([kubernetes/kubernetes#103526](https://github.com/kubernetes/kubernetes/pull/103526)) that causes port-forward to terminate when PostgreSQL (and other databases) send TCP RST packets during normal SSL operations. kubectl v1.22 and earlier auto-reconnect on errors, effectively working around this issue.

This tool uses kubectl v1.22 for port-forwarding to provide reliable database connections without the need for workarounds like disabling SSL or using SSH bastion pods.

## Features

- **Reliable Port-Forwarding**: Uses kubectl v1.22 to avoid the v1.23+ SSL bug
- **Direct Service Access**: No SSH bastion or NodePort required
- **State Management**: Tracks active tunnels with metadata (service, ports, PIDs)
- **Smart Completion**: Bash completion for services, ports, and tunnel identifiers
- **Random Ports**: Optionally use random local ports to avoid conflicts
- **Easy Management**: List and kill tunnels by service name, port, or PID

## Requirements

- Bash 4.0+
- kubectl v1.22.0 (see installation instructions below)
- `python3` (for random port generation)
- Standard Unix tools: `grep`, `cut`, `awk`, `sort`, `tr`, `ss`
- Access to a Kubernetes cluster

## Installation

### Quick Install

```bash
# 1. Download and install kubectl v1.22
curl -LO "https://dl.k8s.io/release/v1.22.0/bin/linux/amd64/kubectl"
chmod +x kubectl
mkdir -p ~/.local/bin
mv kubectl ~/.local/bin/kubectl-1.22

# 2. Copy the main script
cp k8s-proxy ~/.local/bin/k8s-proxy
chmod +x ~/.local/bin/k8s-proxy

# 3. Copy the completion script
mkdir -p ~/.local/share/bash-completion/completions
cp k8s-proxy-completion.bash ~/.local/share/bash-completion/completions/k8s-proxy

# 4. Add to your ~/.bashrc (if not already present)
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc

# Source completion for user scripts
cat >> ~/.bashrc << 'EOF'

# Load user completions
if [ -d "$HOME/.local/share/bash-completion/completions" ]; then
  for completion in "$HOME/.local/share/bash-completion/completions"/*; do
    [ -r "$completion" ] && . "$completion"
  done
fi
EOF

# 5. Reload your shell
source ~/.bashrc
```

### Manual Installation

1. **Install kubectl v1.22:**
   ```bash
   mkdir -p ~/.local/bin
   curl -LO "https://dl.k8s.io/release/v1.22.0/bin/linux/amd64/kubectl"
   chmod +x kubectl
   mv kubectl ~/.local/bin/kubectl-1.22
   ```

2. **Install the main script:**
   ```bash
   cp k8s-proxy ~/.local/bin/
   chmod +x ~/.local/bin/k8s-proxy
   ```

3. **Install bash completion:**
   ```bash
   mkdir -p ~/.local/share/bash-completion/completions
   cp k8s-proxy-completion.bash ~/.local/share/bash-completion/completions/k8s-proxy
   ```

4. **Update your PATH** (add to `~/.bashrc` if not present):
   ```bash
   export PATH="$HOME/.local/bin:$PATH"
   ```

5. **Enable user completions** (add to `~/.bashrc`):
   ```bash
   if [ -d "$HOME/.local/share/bash-completion/completions" ]; then
     for completion in "$HOME/.local/share/bash-completion/completions"/*; do
       [ -r "$completion" ] && . "$completion"
     done
   fi
   ```

6. **Reload your shell:**
   ```bash
   source ~/.bashrc
   ```

## Configuration

The script uses the following defaults that can be modified in the script itself:

- **KUBECTL**: `~/.local/bin/kubectl-1.22` - Path to kubectl v1.22
- **STATE_DIR**: `~/.local/share/k8s-proxy` - Directory for tunnel state files
- **CACHE_TTL**: 300 seconds (5 minutes) - How long to cache Kubernetes service list

## Usage

### Start a Tunnel

```bash
# Same port as remote (default)
k8s-proxy start <service.namespace> <port>

# Custom local port
k8s-proxy start <service.namespace> <remote-port> <local-port>

# Random local port
k8s-proxy start <service.namespace> <remote-port> random
```

**Examples:**
```bash
# Connect to service1 postgres on same port locally
k8s-proxy start service1-postgres-rw.service1 5432

# Connect to service2 postgres on different local port
k8s-proxy start service2-postgres-rw.service2 5432 15432

# Connect to postgres on random local port
k8s-proxy start service1-postgres-rw.service1 5432 random
```

### List Active Tunnels

```bash
k8s-proxy list
```

**Output:**
```
Active k8s-proxy tunnels:
----------------------------
PID: 1234567
  Service: service1-postgres-rw.service1
  Local:   localhost:5432
  Remote:  service1-postgres-rw.service1:5432
```

### Kill a Tunnel

```bash
# By service name
k8s-proxy kill service1-postgres-rw.service1

# By local port
k8s-proxy kill 5432

# By PID
k8s-proxy kill 1234567
```

## Bash Completion

The completion system provides intelligent suggestions:

1. **Command completion**: `k8s-proxy <TAB>` → shows `start`, `list`, `kill`

2. **Service completion**: `k8s-proxy start <TAB>` → shows Kubernetes services
   - Format: `service-name.namespace`
   - First use may be empty (cache is being built in background)
   - Wait 2-3 seconds and try again
   - Cache is refreshed every 5 minutes

3. **Port completion**: `k8s-proxy start service1-postgres-rw.service1 <TAB>`
   - Queries Kubernetes service for actual exposed ports
   - Shows real ports like `5432` instead of generic suggestions
   - Falls back to common database ports if query fails

4. **Local port completion**: After entering remote port, suggests:
   - Same port as remote
   - `random` for random port selection

5. **Kill completion**: `k8s-proxy kill <TAB>`
   - Shows service names of active tunnels only

## How It Works

1. **Port-Forward Creation**: Uses kubectl v1.22 with `kubectl port-forward -n <namespace> service/<service> <local>:<remote>`

2. **Auto-Reconnect**: kubectl v1.22 automatically reconnects when connections are reset (unlike v1.23+)

3. **State Tracking**: Saves tunnel metadata to `~/.local/share/k8s-proxy/<pid>.tunnel`
   - Service name (service.namespace)
   - Local and remote ports
   - Namespace
   - Creation timestamp

4. **Cleanup**: Automatically removes stale tunnel files when processes are no longer running

5. **Service Discovery**: Queries Kubernetes API for all services across all namespaces for completion

## Why kubectl v1.22?

kubectl v1.23.0 introduced a regression that breaks port-forwarding to databases:

- **The Bug**: PR #103526 made kubectl immediately terminate on ANY error
- **Impact**: PostgreSQL's SSL connection close (TCP RST) is treated as fatal
- **Affected**: All CloudNativePG databases (SSL enabled by default)
- **Status**: Unfixed as of 2025 ([kubernetes/kubectl#1169](https://github.com/kubernetes/kubectl/issues/1169))

kubectl v1.22 and earlier don't have this issue - they auto-reconnect on errors, providing a stable tunnel.

## State Files

Tunnel state is stored in `~/.local/share/k8s-proxy/`:
- `*.tunnel` - Active tunnel metadata files (named by PID)
- `services.cache` - Cached list of Kubernetes services (refreshed every 5 minutes)

## Troubleshooting

### Completion not working

```bash
# Reload completion
source ~/.local/share/bash-completion/completions/k8s-proxy

# Or reload entire shell
source ~/.bashrc
```

### Service completion is empty

The first time you use completion, it triggers a background cache build. Wait 2-3 seconds and try again.

### kubectl-1.22 not found

```bash
# Verify kubectl-1.22 is installed
kubectl-1.22 version --client

# If not, download it
cd ~/.local/bin
curl -LO "https://dl.k8s.io/release/v1.22.0/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl kubectl-1.22
```

### Port already in use

Either:
- Use a different local port: `k8s-proxy start <service.namespace> <port> <different-port>`
- Use random port: `k8s-proxy start <service.namespace> <port> random`
- Kill the existing tunnel: `k8s-proxy kill <port>`

### Connection still fails

Check if you're using the right kubectl version:
```bash
# k8s-proxy should show this
k8s-proxy start service1-postgres-rw.service1 5432
# Output should say: "Using kubectl v1.22 (workaround for v1.23+ SSL bug)"
```

## Examples

### Connect to PostgreSQL database

```bash
# Start tunnel
k8s-proxy start service1-postgres-rw.service1 5432

# Use with psql
PGPASSWORD=<password> psql -h localhost -p 5432 -U postgres -d service1

# Use with DataGrip
# Host: localhost
# Port: 5432
# Database: service1
# User: postgres

# Kill when done
k8s-proxy kill service1-postgres-rw.service1
```

### Connect to multiple databases

```bash
# Different services on same port (use different local ports)
k8s-proxy start service1-postgres-rw.service1 5432 5432
k8s-proxy start service2-postgres-rw.service2 5432 5433

# List all
k8s-proxy list

# Kill all by service name
k8s-proxy kill service1-postgres-rw.service1
k8s-proxy kill service2-postgres-rw.service2
```

### Using with DataGrip

```bash
# Start tunnel
k8s-proxy start service1-postgres-rw.service1 5432

# Configure DataGrip:
# - Host: localhost
# - Port: 5432
# - Database: service1
# - User: postgres
# - Password: <from kubernetes secret>

# Keep tunnel running in background
# DataGrip will automatically reconnect if connection drops
```

## Known Issues

- **kubectl v1.23+ bug**: This tool exists because of this bug - use k8s-proxy instead of kubectl directly
- **First connection may show error**: kubectl v1.22 auto-reconnects, so first attempt may fail but subsequent ones succeed
- **Requires cluster access**: Your kubeconfig must have valid credentials

## Related Issues

- [kubernetes/kubernetes#103526](https://github.com/kubernetes/kubernetes/pull/103526) - The regression that broke port-forward
- [kubernetes/kubectl#1169](https://github.com/kubernetes/kubectl/issues/1169) - Port-forward drops after first connection
- [kubernetes/kubernetes#111825](https://github.com/kubernetes/kubernetes/issues/111825) - PostgreSQL connection resets
- [kubernetes/kubectl#1620](https://github.com/kubernetes/kubectl/issues/1620) - Cancelled TCP request bug

## Uninstallation

```bash
# Remove scripts
rm ~/.local/bin/k8s-proxy
rm ~/.local/bin/kubectl-1.22
rm ~/.local/share/bash-completion/completions/k8s-proxy

# Remove state files
rm -rf ~/.local/share/k8s-proxy

# Remove shell configuration (manual - edit ~/.bashrc)
# Remove the PATH and completion lines added during installation
```

## License

Free to use and modify.
