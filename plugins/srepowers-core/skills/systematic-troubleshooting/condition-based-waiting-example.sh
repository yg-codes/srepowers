#!/usr/bin/env bash
# Complete implementation of condition-based waiting utilities for SRE operations.
# Recast from the superpowers test-infra example (waitForEvent/waitForEventCount)
# for eventual-consistency waits: rollouts, health endpoints, DNS propagation.
#
# Core principle: poll for the actual condition, never sleep(fixed).

set -euo pipefail

# ---------------------------------------------------------------------------
# wait_for <description> <command> [timeout_s] [interval_s]
#
# Polls <command> until it exits 0, or fails with a clear timeout error.
# <command> is eval'd, so quote it as a single argument.
#
# Example:
#   wait_for "api healthy" 'curl -fsS https://api.example.com/healthz' 120 5
# ---------------------------------------------------------------------------
wait_for() {
  local desc="$1" cmd="$2" timeout="${3:-120}" interval="${4:-5}"
  local start elapsed
  start=$(date +%s)

  while true; do
    if eval "$cmd" >/dev/null 2>&1; then
      return 0
    fi
    elapsed=$(( $(date +%s) - start ))
    if (( elapsed > timeout )); then
      echo "Timeout waiting for ${desc} after ${timeout}s" >&2
      return 1
    fi
    sleep "$interval"
  done
}

# ---------------------------------------------------------------------------
# wait_for_rollout <context> <namespace> <deployment> [timeout_s]
#
# Waits for a Deployment rollout to complete. Prefers the native
# `kubectl rollout status` waiter, which polls until all replicas are
# updated/Ready or times out with a clear error.
#
# Example:
#   wait_for_rollout prod-cluster prod api 180
# ---------------------------------------------------------------------------
wait_for_rollout() {
  local ctx="$1" ns="$2" deploy="$3" timeout="${4:-120}"
  kubectl --context "$ctx" -n "$ns" rollout status "deploy/${deploy}" \
    --timeout="${timeout}s"
}

# ---------------------------------------------------------------------------
# wait_for_health <url> [timeout_s] [interval_s]
#
# Waits for an HTTP health endpoint to return a 2xx (curl -f exits non-zero
# on 4xx/5xx). No native waiter exists for arbitrary endpoints, so poll.
#
# Example:
#   wait_for_health https://api.example.com/healthz 120 5
# ---------------------------------------------------------------------------
wait_for_health() {
  local url="$1" timeout="${2:-120}" interval="${3:-5}"
  wait_for "health 2xx from ${url}" "curl -fsS '${url}'" "$timeout" "$interval"
}

# ---------------------------------------------------------------------------
# wait_for_dns <name> <expected> [resolver] [timeout_s] [interval_s]
#
# Waits for a DNS name to resolve to an expected value at a given resolver.
# Use to confirm propagation after a zone change instead of `sleep 60`.
#
# Example:
#   wait_for_dns svc.example.com 10.0.0.5 8.8.8.8 300 10
# ---------------------------------------------------------------------------
wait_for_dns() {
  local name="$1" expected="$2" resolver="${3:-}" timeout="${4:-300}" interval="${5:-10}"
  local server_arg=""
  [ -n "$resolver" ] && server_arg="@${resolver}"
  wait_for "DNS ${name} -> ${expected} via ${resolver:-system}" \
    "dig +short ${server_arg} '${name}' | grep -qx '${expected}'" \
    "$timeout" "$interval"
}

# ---------------------------------------------------------------------------
# Usage example from an actual deploy/verification workflow:
#
# BEFORE (flaky):
# ---------------
# kubectl --context prod apply -f deploy.yaml
# sleep 30                                    # hope it's Ready in 30s
# curl -fsS https://api.example.com/healthz   # fails randomly under load
# dig +short svc.example.com                  # may show the old IP
#
# AFTER (reliable):
# ----------------
# kubectl --context prod apply -f deploy.yaml
# wait_for_rollout prod prod api 180              # wait for pods Ready
# wait_for_health https://api.example.com/healthz # wait for real 2xx
# wait_for_dns svc.example.com 10.0.0.5 8.8.8.8   # wait for propagation
#
# Result: verification completes when the system converges, and a real
# failure surfaces as "Timeout waiting for X" instead of a false success.
# ---------------------------------------------------------------------------

# If invoked directly (not sourced), run a tiny self-check of the poll loop.
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  echo "Self-check: wait_for should succeed immediately on a true condition..."
  wait_for "trivially true" "true" 5 1 && echo "  OK"
  echo "Self-check: wait_for should time out on a false condition..."
  if wait_for "always false" "false" 2 1; then
    echo "  UNEXPECTED: did not time out" >&2
    exit 1
  else
    echo "  OK (timed out as expected)"
  fi
fi
