#!/usr/bin/env bash
#
# Phase 0: Manage ZFS replication jobs for pre-sync VMs
# Description: Create and verify replication jobs used for low-downtime VM migration
#
# Location:
#   scripts/phase0-replication.sh
#
# Usage:
#   ssh root@<source-node>.example.com 'bash -s -- --target <target-node> setup 22001 22013 22009' < scripts/phase0-replication.sh
#   ssh root@<source-node>.example.com 'bash -s -- --target <target-node> verify 22001 22013 22009' < scripts/phase0-replication.sh
#
# Prerequisites:
#   - jq installed on all nodes (apt install -y jq)
#   - target node has sufficient storage for the selected replicas
#   - Run setup well before the maintenance window
#
# Created: 2026-03-16
# Cluster: pve-node00 (UAT)

set -euo pipefail

TARGET_NODE=""
SCHEDULE='mon..sun 19..23:59/59'
SOURCE_NODE=""
FORCE_DELETE=false

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
	echo -e "${GREEN}[INFO]${NC} $1"
}

log_ok() {
	echo -e "${GREEN}[OK]${NC} $1"
}

log_warn() {
	echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
	echo -e "${RED}[ERROR]${NC} $1"
}

usage() {
	cat <<EOF
Usage:
	${0##*/} --target <node> [--schedule '<schedule>'] <setup|verify|delete> <vmid> [vmid ...]

Commands:
	setup   Create local replication jobs for the selected VMIDs
	verify  Verify replication job health and replica datasets for the selected VMIDs
	delete  Remove local replication jobs for the selected VMIDs

Options:
	--target <node>          Required target node for replication jobs and checks
	--schedule '<schedule>'  Replication schedule for setup (default: ${SCHEDULE})
	--yes                    Skip confirmation prompt for delete (non-interactive mode)

Examples:
	${0##*/} --target pve-node21 setup 98701 99609
	${0##*/} --target pve-node03 setup 22001 22013 22009
	${0##*/} --target pve-node03 verify 22001 22013 22009
	${0##*/} --target pve-node03 delete 22001 22013 22009

Remote usage:
	ssh root@pve-node23.example.com 'bash -s -- --target pve-node21 setup 98701 99609' < ${0##*/}
	ssh root@pve-node01.example.com 'bash -s -- --target pve-node03 verify 22001 22013 22009' < ${0##*/}
	ssh root@pve-node01.example.com 'bash -s -- --target pve-node03 delete 22001 22013 22009' < ${0##*/}
EOF
}

parse_args() {
	if (($# == 0)); then
		usage
		exit 1
	fi

	while (($# > 0)); do
		case "$1" in
		--target)
			if (($# < 2)); then
				log_error "Missing value for --target"
				usage
				exit 1
			fi
			TARGET_NODE=$2
			shift 2
			;;
		--schedule)
			if (($# < 2)); then
				log_error "Missing value for --schedule"
				usage
				exit 1
			fi
			SCHEDULE=$2
			shift 2
			;;
		--yes | -y)
			FORCE_DELETE=true
			shift
			;;
		-h | --help | help)
			usage
			exit 0
			;;
		setup | verify | delete)
			COMMAND=$1
			shift
			break
			;;
		*)
			log_error "Unknown argument: $1"
			usage
			exit 1
			;;
		esac
	done

	if [[ -z "$TARGET_NODE" ]]; then
		log_error "--target is required"
		usage
		exit 1
	fi

	if [[ -z "${COMMAND:-}" ]]; then
		log_error "A command is required"
		usage
		exit 1
	fi

	if (($# == 0)); then
		log_error "At least one VMID is required"
		usage
		exit 1
	fi

	VMID_ARGS=("$@")
}

require_source_node() {
	CURRENT_NODE=$(hostname -s)
	SOURCE_NODE=$CURRENT_NODE
	if [[ "$TARGET_NODE" == "$SOURCE_NODE" ]]; then
		log_error "Target node must be different from source node ($SOURCE_NODE)"
		exit 1
	fi
}

validate_vmids() {
	if (($# == 0)); then
		log_error "At least one VMID is required"
		usage
		exit 1
	fi

	VMIDS=()
	for vmid in "$@"; do
		if [[ ! "$vmid" =~ ^[0-9]+$ ]]; then
			log_error "Invalid VMID: $vmid"
			usage
			exit 1
		fi
		if ! qm status "$vmid" &>/dev/null; then
			log_error "VM $vmid not found in cluster"
			exit 1
		fi
		if ! qm list | awk -v vmid="$vmid" '$1 == vmid {found=1} END {exit found ? 0 : 1}'; then
			log_error "VM $vmid is not present on $SOURCE_NODE"
			exit 1
		fi
		VMIDS+=("$vmid")
	done

	REPLICA_PATTERN=$(printf 'vm-%s|' "${VMIDS[@]}")
	REPLICA_PATTERN="${REPLICA_PATTERN%|}"
}

check_target_reachable() {
	log_info "Verifying connectivity to $TARGET_NODE..."
	if ! ping -c 1 "$TARGET_NODE" &>/dev/null; then
		log_error "Cannot reach $TARGET_NODE"
		exit 1
	fi
}

check_target_storage() {
	log_info "Checking storage capacity on $TARGET_NODE..."
	TARGET_FREE=$(ssh "$TARGET_NODE" 'zpool list -Hpo free rpool')
	TARGET_FREE_GB=$((TARGET_FREE / 1024 / 1024 / 1024))
	log_info "$TARGET_NODE rpool free: ${TARGET_FREE_GB}GB"

	if ((TARGET_FREE_GB == 0)); then
		log_error "Unable to determine free storage on $TARGET_NODE"
		exit 1
	fi
}

show_replica_data() {
	echo "--- Replica Data on $TARGET_NODE ---"
	ssh "$TARGET_NODE" 'zfs list -r -o name,used,avail rpool/data' | grep -E "NAME|$REPLICA_PATTERN" || true
	echo ""
}

command_setup() {
	check_target_reachable
	check_target_storage

	log_info "Creating replication jobs..."
	for vmid in "${VMIDS[@]}"; do
		VM_NAME=$(qm config "$vmid" | awk '/^name:/ {print $2}')
		JOB_ID="${vmid}-0"

		log_info "Creating job $JOB_ID for VM $vmid ($VM_NAME) -> $TARGET_NODE"

		if pvesr list | grep -q "^$JOB_ID"; then
			log_warn "Job $JOB_ID already exists, skipping"
		else
			pvesr create-local-job "$JOB_ID" "$TARGET_NODE" --schedule "$SCHEDULE"
			log_info "Created job $JOB_ID"
		fi
	done

	log_info "Verifying replication jobs..."
	echo ""
	pvesr list
	echo ""

	log_info "Waiting for initial sync to begin (30 seconds)..."
	sleep 30

	log_info "Initial replication status:"
	echo ""
	pvesr status
	echo ""

	echo "========================================"
	echo "Phase 0 Setup Complete"
	echo "========================================"
	echo ""
	echo "Replication Jobs Created:"
	for vmid in "${VMIDS[@]}"; do
		VM_NAME=$(qm config "$vmid" | awk '/^name:/ {print $2}')
		ZFS_USED=$(zfs list -Hpo used "rpool/data/vm-${vmid}-disk-0" 2>/dev/null | numfmt --to=iec || echo "unknown")
		echo "  - $vmid ($VM_NAME): ~$ZFS_USED -> $TARGET_NODE"
	done
	echo ""
	echo "Schedule: $SCHEDULE"
	echo ""
	echo "Next Steps:"
	echo "  1. Monitor replication status: pvesr status"
	echo "  2. Verify FailCount is 0 for the selected jobs before maintenance"
	echo "  3. Allow sufficient time for the initial full sync to complete"
	echo "  4. Verify target storage remains healthy during sync"
	echo ""
	echo "Verify on $TARGET_NODE:"
	echo "  ssh $TARGET_NODE 'zfs list -r -o name,used rpool/data | grep -E \"$REPLICA_PATTERN\"'"
	echo ""
}

command_verify() {
	echo "========================================"
	echo "Phase 0 Replication Verification"
	echo "========================================"
	echo ""
	echo "Run date: $(date)"
	echo "Source node: $SOURCE_NODE"
	echo "Target node: $TARGET_NODE"
	echo ""

	echo "--- Replication Jobs ---"
	pvesr list
	echo ""

	echo "--- Replication Status ---"
	PVE_SR_STATUS=$(pvesr status)
	printf '%s\n' "$PVE_SR_STATUS"
	echo ""

	FAIL_COUNT=0
	for vmid in "${VMIDS[@]}"; do
		JOB_ID="${vmid}-0"
		JOB_FAIL=$(printf '%s\n' "$PVE_SR_STATUS" | awk -v job="$JOB_ID" '$1 == job {print $7}')

		if [[ -z "$JOB_FAIL" ]]; then
			log_error "Job $JOB_ID not found"
			FAIL_COUNT=$((FAIL_COUNT + 1))
		elif [[ "$JOB_FAIL" != "0" ]]; then
			log_error "Job $JOB_ID has FailCount=$JOB_FAIL"
			FAIL_COUNT=$((FAIL_COUNT + 1))
		else
			log_ok "Job $JOB_ID: FailCount=0"
		fi
	done
	echo ""

	echo "--- Last Sync Times ---"
	for vmid in "${VMIDS[@]}"; do
		JOB_ID="${vmid}-0"
		LAST_SYNC=$(printf '%s\n' "$PVE_SR_STATUS" | awk -v job="$JOB_ID" '$1 == job {print $4}')
		NEXT_SYNC=$(printf '%s\n' "$PVE_SR_STATUS" | awk -v job="$JOB_ID" '$1 == job {print $5}')

		if [[ -n "$LAST_SYNC" ]]; then
			echo "  $JOB_ID: LastSync=$LAST_SYNC, NextSync=$NEXT_SYNC"
		fi
	done
	echo ""

	show_replica_data

	echo "--- Storage Summary ---"
	echo "Source ($SOURCE_NODE):"
	zpool list rpool
	echo ""
	echo "Target ($TARGET_NODE):"
	ssh "$TARGET_NODE" 'zpool list rpool'
	echo ""

	echo "========================================"
	if ((FAIL_COUNT == 0)); then
		log_ok "All replication jobs healthy - ready for upgrade"
		exit 0
	else
		log_error "$FAIL_COUNT job(s) have failures - investigate before proceeding"
		exit 1
	fi
}

command_delete() {
	echo "========================================"
	echo "Phase 0 Replication Job Removal"
	echo "========================================"
	echo ""
	log_warn "This removes replication jobs for the selected VMIDs"
	echo "Selected jobs:"
	for vmid in "${VMIDS[@]}"; do
		echo "  - ${vmid}-0"
	done
	echo ""

	if [[ "$FORCE_DELETE" != "true" ]]; then
		read -p "Delete these replication jobs? [y/N] " -n 1 -r
		echo
		if [[ ! $REPLY =~ ^[Yy]$ ]]; then
			log_info "Aborted by user"
			exit 0
		fi
	else
		log_info "Skipping confirmation (--yes flag provided)"
	fi

	for vmid in "${VMIDS[@]}"; do
		JOB_ID="${vmid}-0"
		if pvesr list | grep -q "^$JOB_ID"; then
			log_info "Deleting job $JOB_ID"
			pvesr delete "$JOB_ID"
			log_ok "Deleted job $JOB_ID"
		else
			log_warn "Job $JOB_ID not found, skipping"
		fi
	done

	echo ""
	log_info "Remaining replication jobs:"
	pvesr list
}

main() {
	parse_args "$@"
	require_source_node
	validate_vmids "${VMID_ARGS[@]}"

	case "$COMMAND" in
	setup)
		command_setup
		;;
	verify)
		command_verify
		;;
	delete)
		command_delete
		;;
	*)
		log_error "Unknown command: $COMMAND"
		usage
		exit 1
		;;
	esac
}

main "$@"
