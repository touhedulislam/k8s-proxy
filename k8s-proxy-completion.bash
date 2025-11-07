#!/bin/bash
# Bash completion for k8s-proxy

_k8s_proxy_completions()
{
    local cur prev words cword
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    words=("${COMP_WORDS[@]}")
    cword=$COMP_CWORD

    local STATE_DIR="$HOME/.local/share/k8s-proxy"
    local KUBECTL="$HOME/.local/bin/kubectl-1.22"
    local CACHE_FILE="$STATE_DIR/services.cache"
    local CACHE_TTL=300  # 5 minutes

    # Get active tunnel identifiers for kill command
    _get_tunnel_identifiers() {
        local identifiers=()
        local file pid service local_port

        # Cleanup stale tunnels
        shopt -s nullglob
        for file in "$STATE_DIR"/*.tunnel; do
            pid=$(basename "$file" .tunnel)
            if ! kill -0 "$pid" 2>/dev/null; then
                rm -f "$file"
            fi
        done

        # Collect identifiers
        for file in "$STATE_DIR"/*.tunnel; do
            pid=$(basename "$file" .tunnel)
            service=$(grep "^SERVICE=" "$file" 2>/dev/null | cut -d= -f2)
            local_port=$(grep "^LOCAL_PORT=" "$file" 2>/dev/null | cut -d= -f2)

            [ -n "$pid" ] && identifiers+=("$pid")
            [ -n "$service" ] && identifiers+=("$service")
            [ -n "$local_port" ] && identifiers+=("$local_port")
        done
        shopt -u nullglob

        printf '%s\n' "${identifiers[@]}"
    }

    # Get Kubernetes services from cache or query
    _get_k8s_services() {
        mkdir -p "$STATE_DIR" 2>/dev/null

        # Check cache validity
        if [ -f "$CACHE_FILE" ]; then
            local cache_age=$(($(date +%s) - $(stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0)))
            if [ $cache_age -lt $CACHE_TTL ]; then
                cat "$CACHE_FILE" 2>/dev/null
                return
            fi
        fi

        # Try to update cache in background (non-blocking)
        (
            local services
            services=$("$KUBECTL" get svc -A -o custom-columns=NAME:.metadata.name,NAMESPACE:.metadata.namespace --no-headers 2>/dev/null | \
                awk '{print $1"."$2}' | sort -u)

            if [ -n "$services" ]; then
                echo "$services" > "$CACHE_FILE.tmp" 2>/dev/null
                mv "$CACHE_FILE.tmp" "$CACHE_FILE" 2>/dev/null
            fi
        ) &>/dev/null &

        # Return cached data if available
        [ -f "$CACHE_FILE" ] && cat "$CACHE_FILE" 2>/dev/null
    }

    # Get port from service
    _get_service_port() {
        local service="$1"
        local namespace="${service##*.}"
        local svc_name="${service%.*}"

        if [ -n "$namespace" ] && [ -n "$svc_name" ]; then
            "$KUBECTL" get svc -n "$namespace" "$svc_name" -o jsonpath='{.spec.ports[*].port}' 2>/dev/null | tr ' ' '\n' | sort -u | tr '\n' ' '
        fi
    }

    # Main completion logic
    case $cword in
        1)
            # First argument: only subcommands
            local subcommands="start list kill"
            COMPREPLY=( $(compgen -W "$subcommands" -- "$cur") )
            ;;
        2)
            case ${words[1]} in
                start)
                    # Complete with service.namespace names
                    local services
                    services=$(_get_k8s_services)
                    COMPREPLY=( $(compgen -W "$services" -- "$cur") )
                    ;;
                kill)
                    # Complete with service names only
                    local services=""
                    shopt -s nullglob
                    for file in "$STATE_DIR"/*.tunnel; do
                        local pid=$(basename "$file" .tunnel)
                        if kill -0 "$pid" 2>/dev/null; then
                            local service=$(grep "^SERVICE=" "$file" 2>/dev/null | cut -d= -f2)
                            [ -n "$service" ] && services="$services $service"
                        fi
                    done
                    shopt -u nullglob
                    COMPREPLY=( $(compgen -W "$services" -- "$cur") )
                    ;;
                list)
                    # No completion for list
                    ;;
            esac
            ;;
        3)
            # Third argument: depends on first command
            case ${words[1]} in
                start)
                    # Get actual ports from Kubernetes service
                    local service="${words[2]}"
                    local ports=""

                    if [ -n "$service" ]; then
                        ports=$(_get_service_port "$service")
                    fi

                    # Fallback to common database ports if query fails
                    if [ -z "$ports" ]; then
                        ports="5432 5433 3306 27017 6379 8080 8443 9000 3000 5000"
                    fi

                    COMPREPLY=( $(compgen -W "$ports" -- "$cur") )
                    ;;
            esac
            ;;
        4)
            # Fourth argument: local port for start command
            case ${words[1]} in
                start)
                    if [[ ${words[3]} =~ ^[0-9]+$ ]]; then
                        # Suggest same port as remote, random, or empty
                        local suggestions="${words[3]} random"
                        COMPREPLY=( $(compgen -W "$suggestions" -- "$cur") )
                    fi
                    ;;
            esac
            ;;
    esac
}

complete -F _k8s_proxy_completions k8s-proxy
