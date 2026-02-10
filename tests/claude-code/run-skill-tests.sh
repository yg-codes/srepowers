#!/usr/bin/env bash
# Test runner for Claude Code skills
# Tests skills by invoking Claude Code CLI and verifying behavior
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "========================================"
echo " Claude Code Skills Test Suite"
echo "========================================"
echo ""
echo "Repository: $(cd ../.. && pwd)"
echo "Test time: $(date)"
echo "Claude version: $(claude --version 2>/dev/null || echo 'not found')"
echo ""

# Check if Claude Code is available
if ! command -v claude &> /dev/null; then
    echo "ERROR: Claude Code CLI not found"
    echo "Install Claude Code first: https://code.claude.com"
    exit 1
fi

# Parse command line arguments
VERBOSE=false
SPECIFIC_TEST=""
TIMEOUT=300  # Default 5 minute timeout per test
RUN_INTEGRATION=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --test|-t)
            SPECIFIC_TEST="$2"
            shift 2
            ;;
        --timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        --integration|-i)
            RUN_INTEGRATION=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --verbose, -v        Show verbose output"
            echo "  --test, -t NAME      Run only the specified test"
            echo "  --timeout SECONDS    Set timeout per test (default: 300)"
            echo "  --integration, -i    Run integration tests (slow, 10-30 min)"
            echo "  --help, -h           Show this help"
            echo ""
            echo "Tests:"
            echo "  test-test-driven-operation.sh           TDO skill loading and requirements"
            echo "  test-subagent-driven-operation.sh       SDO skill loading and requirements"
            echo "  test-verification-before-completion.sh  VBC skill evidence requirements"
            echo "  test-brainstorming-operations.sh        Brainstorming skill workflow"
            echo "  test-writing-operation-plans.sh         Planning skill TDO discipline"
            echo "  test-using-srepowers.sh                 Meta-skill skill listing"
            echo "  test-sre-runbook.sh                     Runbook format and sections"
            echo "  test-pve-admin.sh                       Proxmox administration"
            echo "  test-puppet-code-analyzer.sh            Puppet linting and analysis"
            echo "  test-cache-cleanup.sh                   Cache cleanup verification"
            echo "  test-gitlab-ecr-pipeline.sh             ECR pipeline patterns"
            echo "  test-clickup-ticket-creator.sh          ClickUp CCB template"
            echo "  test-architecture-designer.sh           Architecture design and ADRs"
            echo "  test-chaos-engineer.sh                  Chaos experiments and game days"
            echo "  test-cloud-architect.sh                 Cloud architecture and WAF"
            echo "  test-code-documenter.sh                 API documentation and docstrings"
            echo "  test-code-reviewer.sh                   Code quality and PR reviews"
            echo "  test-devops-engineer.sh                 CI/CD and containerization"
            echo "  test-golang-pro.sh                      Go concurrency and patterns"
            echo "  test-kubernetes-specialist.sh            K8s RBAC and troubleshooting"
            echo "  test-microservices-architect.sh          Service boundaries and sagas"
            echo "  test-monitoring-expert.sh               Observability and alerting"
            echo "  test-postgres-pro.sh                    PostgreSQL optimization"
            echo "  test-prompt-engineer.sh                 LLM prompt design"
            echo "  test-python-pro.sh                      Python type hints and async"
            echo "  test-rust-engineer.sh                   Rust ownership and async"
            echo "  test-secure-code-guardian.sh             OWASP and authentication"
            echo "  test-security-reviewer.sh               Security audits and SAST"
            echo "  test-sql-pro.sh                         SQL optimization and indexing"
            echo "  test-sre-engineer.sh                    SLO/SLI and error budgets"
            echo "  test-terraform-engineer.sh              Terraform modules and state"
            echo "  test-test-master.sh                     Test pyramid and coverage"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# List of skill tests to run (fast unit tests)
tests=(
    "test-test-driven-operation.sh"
    "test-subagent-driven-operation.sh"
    "test-verification-before-completion.sh"
    "test-brainstorming-operations.sh"
    "test-writing-operation-plans.sh"
    "test-using-srepowers.sh"
    "test-sre-runbook.sh"
    "test-pve-admin.sh"
    "test-puppet-code-analyzer.sh"
    "test-cache-cleanup.sh"
    "test-gitlab-ecr-pipeline.sh"
    "test-clickup-ticket-creator.sh"
    "test-architecture-designer.sh"
    "test-chaos-engineer.sh"
    "test-cloud-architect.sh"
    "test-code-documenter.sh"
    "test-code-reviewer.sh"
    "test-devops-engineer.sh"
    "test-golang-pro.sh"
    "test-kubernetes-specialist.sh"
    "test-microservices-architect.sh"
    "test-monitoring-expert.sh"
    "test-postgres-pro.sh"
    "test-prompt-engineer.sh"
    "test-python-pro.sh"
    "test-rust-engineer.sh"
    "test-secure-code-guardian.sh"
    "test-security-reviewer.sh"
    "test-sql-pro.sh"
    "test-sre-engineer.sh"
    "test-terraform-engineer.sh"
    "test-test-master.sh"
)

# Integration tests (slow, full execution)
integration_tests=(
    # Coming soon
)

# Add integration tests if requested
if [ "$RUN_INTEGRATION" = true ]; then
    tests+=("${integration_tests[@]}")
fi

# Filter to specific test if requested
if [ -n "$SPECIFIC_TEST" ]; then
    tests=("$SPECIFIC_TEST")
fi

# Track results
passed=0
failed=0
skipped=0

# Run each test
for test in "${tests[@]}"; do
    echo "----------------------------------------"
    echo "Running: $test"
    echo "----------------------------------------"

    test_path="$SCRIPT_DIR/$test"

    if [ ! -f "$test_path" ]; then
        echo "  [SKIP] Test file not found: $test"
        skipped=$((skipped + 1))
        continue
    fi

    if [ ! -x "$test_path" ]; then
        echo "  Making $test executable..."
        chmod +x "$test_path"
    fi

    start_time=$(date +%s)

    if [ "$VERBOSE" = true ]; then
        if timeout "$TIMEOUT" bash "$test_path"; then
            end_time=$(date +%s)
            duration=$((end_time - start_time))
            echo ""
            echo "  [PASS] $test (${duration}s)"
            passed=$((passed + 1))
        else
            exit_code=$?
            end_time=$(date +%s)
            duration=$((end_time - start_time))
            echo ""
            if [ $exit_code -eq 124 ]; then
                echo "  [FAIL] $test (timeout after ${TIMEOUT}s)"
            else
                echo "  [FAIL] $test (${duration}s)"
            fi
            failed=$((failed + 1))
        fi
    else
        # Capture output for non-verbose mode
        if output=$(timeout "$TIMEOUT" bash "$test_path" 2>&1); then
            end_time=$(date +%s)
            duration=$((end_time - start_time))
            echo "  [PASS] (${duration}s)"
            passed=$((passed + 1))
        else
            exit_code=$?
            end_time=$(date +%s)
            duration=$((end_time - start_time))
            if [ $exit_code -eq 124 ]; then
                echo "  [FAIL] (timeout after ${TIMEOUT}s)"
            else
                echo "  [FAIL] (${duration}s)"
            fi
            echo ""
            echo "  Output:"
            echo "$output" | sed 's/^/    /'
            failed=$((failed + 1))
        fi
    fi

    echo ""
done

# Print summary
echo "========================================"
echo " Test Results Summary"
echo "========================================"
echo ""
echo "  Passed:  $passed"
echo "  Failed:  $failed"
echo "  Skipped: $skipped"
echo ""

if [ "$RUN_INTEGRATION" = false ] && [ ${#integration_tests[@]} -gt 0 ]; then
    echo "Note: Integration tests were not run (they take 10-30 minutes)."
    echo "Use --integration flag to run full workflow execution tests."
    echo ""
fi

if [ $failed -gt 0 ]; then
    echo "STATUS: FAILED"
    exit 1
else
    echo "STATUS: PASSED"
    exit 0
fi
