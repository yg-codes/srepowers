#!/usr/bin/env bash
#
# Proxmox VE Capacity Check Script
# Description: Consolidated capacity, allocation, and inventory reporting for PVE nodes
# Usage: bash check-pve-capacity.sh [--section all|memory|storage|inventory|placement] [--format text|json|csv]
#        ssh <pve-node> 'bash -s' < check-pve-capacity.sh -- --section all

set -euo pipefail

SECTION="all"
FORMAT="text"

MEM_WARN_MB=4096
MEM_CRIT_MB=2048
STORAGE_WARN_PCT=75
STORAGE_CRIT_PCT=85

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
	cat <<'EOF'
Usage: check-pve-capacity.sh [options]

Options:
  --section NAME        all, memory, storage, inventory, placement
  --format NAME         text, json, csv
  --mem-warn-mb N       Warning threshold for available memory (default: 4096)
  --mem-crit-mb N       Critical threshold for available memory (default: 2048)
  --storage-warn-pct N  Warning threshold for storage usage (default: 75)
  --storage-crit-pct N  Critical threshold for storage usage (default: 85)
  -h, --help            Show this help

Sections:
  all        Full capacity report (memory, storage, inventory)
  memory     Node and guest memory allocation
  storage    Storage, ZFS pool, and top consumer analysis
  inventory  VM/CT inventory with VM disk allocation details
  placement  Alias for inventory

Formats:
  text       Human-readable report
  json       Structured JSON output
  csv        Flat CSV inventory/metric output
EOF
}

while [[ $# -gt 0 ]]; do
	case "$1" in
	--section)
		SECTION="${2:-}"
		shift 2
		;;
	--format)
		FORMAT="${2:-}"
		shift 2
		;;
	--mem-warn-mb)
		MEM_WARN_MB="${2:-}"
		shift 2
		;;
	--mem-crit-mb)
		MEM_CRIT_MB="${2:-}"
		shift 2
		;;
	--storage-warn-pct)
		STORAGE_WARN_PCT="${2:-}"
		shift 2
		;;
	--storage-crit-pct)
		STORAGE_CRIT_PCT="${2:-}"
		shift 2
		;;
	-h | --help)
		usage
		exit 0
		;;
	*)
		echo "Unknown argument: $1" >&2
		usage >&2
		exit 1
		;;
	esac
done

case "$SECTION" in
all | memory | storage | inventory | placement) ;;
*)
	echo "Invalid section: $SECTION" >&2
	exit 1
	;;
esac

if [[ "$SECTION" == "placement" ]]; then
	SECTION="inventory"
fi

case "$FORMAT" in
text | json | csv) ;;
*)
	echo "Invalid format: $FORMAT" >&2
	exit 1
	;;
esac

require_cmd() {
	if ! command -v "$1" >/dev/null 2>&1; then
		echo "Required command not found: $1" >&2
		exit 1
	fi
}

print_header() {
	echo ""
	echo "========================================"
	echo "$1"
	echo "========================================"
}

print_section() {
	echo ""
	echo "--- $1 ---"
}

status_label() {
	local level=$1
	local message=$2
	if [[ "$FORMAT" != "text" ]]; then
		printf '%s' "$level: $message"
		return 0
	fi

	case "$level" in
	ok) printf '%b[OK]%b %s\n' "$GREEN" "$NC" "$message" ;;
	warn) printf '%b[WARN]%b %s\n' "$YELLOW" "$NC" "$message" ;;
	crit) printf '%b[CRIT]%b %s\n' "$RED" "$NC" "$message" ;;
	info) printf '%b[INFO]%b %s\n' "$BLUE" "$NC" "$message" ;;
	*) printf '%s\n' "$message" ;;
	esac
}

require_cmd qm
require_cmd pct
require_cmd pvesh
require_cmd pvesm
require_cmd jq

if [[ "$SECTION" == "storage" || "$SECTION" == "all" ]]; then
	require_cmd awk
fi

NODE_SHORT=$(hostname -s)
NODE_FQDN=$(hostname -f 2>/dev/null || hostname)
TIMESTAMP=$(date --iso-8601=seconds 2>/dev/null || date)
FREE_BYTES=$(free -b)
TOTAL_MEM_BYTES=$(printf '%s\n' "$FREE_BYTES" | awk 'NR==2 {print $2}')
USED_MEM_BYTES=$(printf '%s\n' "$FREE_BYTES" | awk 'NR==2 {print $3}')
AVAILABLE_MEM_BYTES=$(printf '%s\n' "$FREE_BYTES" | awk 'NR==2 {print $7}')

NODE_STATUS_JSON=$(pvesh get "/nodes/$NODE_SHORT/status" --output-format json 2>/dev/null || echo '{}')
CLUSTER_STATUS_JSON=$(pvesh get /cluster/status --output-format json 2>/dev/null || echo '[]')
CLUSTER_VM_RESOURCES_JSON=$(pvesh get /cluster/resources --type vm --output-format json 2>/dev/null || echo '[]')
VM_RUNTIME_JSON=$(pvesh get "/nodes/$NODE_SHORT/qemu" --output-format json 2>/dev/null || echo '[]')
CT_RUNTIME_JSON=$(pvesh get "/nodes/$NODE_SHORT/lxc" --output-format json 2>/dev/null || echo '[]')

build_vm_json() {
	local vmid status_json config name status current_mem maxmem_bytes cpus maxcpu memory_mb balloon_mb cores sockets disks_json
	for vmid in $(printf '%s' "$VM_RUNTIME_JSON" | jq -r '.[].vmid'); do
		status_json=$(printf '%s' "$VM_RUNTIME_JSON" | jq -c --argjson id "$vmid" '.[] | select(.vmid == $id)')
		config=$(qm config "$vmid" 2>/dev/null || true)
		name=$(printf '%s\n' "$config" | awk '/^name:/ {print $2; exit}')
		if [[ -z "$name" || "$name" == "null" ]]; then
			name=$(printf '%s' "$status_json" | jq -r '.name // "vm-unknown"')
		fi
		status=$(printf '%s' "$status_json" | jq -r '.status // "unknown"')
		current_mem=$(printf '%s' "$status_json" | jq -r '.mem // 0')
		maxmem_bytes=$(printf '%s' "$status_json" | jq -r '.maxmem // 0')
		cpus=$(printf '%s' "$status_json" | jq -r '.cpus // 0')
		maxcpu=$(printf '%s' "$status_json" | jq -r '.maxcpu // 0')
		memory_mb=$(printf '%s\n' "$config" | awk '/^memory:/ {print $2; exit}')
		balloon_mb=$(printf '%s\n' "$config" | awk '/^balloon:/ {print $2; exit}')
		cores=$(printf '%s\n' "$config" | awk '/^cores:/ {print $2; exit}')
		sockets=$(printf '%s\n' "$config" | awk '/^sockets:/ {print $2; exit}')
		memory_mb=${memory_mb:-0}
		balloon_mb=${balloon_mb:-0}
		cores=${cores:-0}
		sockets=${sockets:-0}

		disks_json=$(printf '%s\n' "$config" | awk -F': ' '/^(scsi|virtio|sata|ide|efidisk)[0-9]+:/ {print $1 "\t" $2}' |
			jq -Rn '[inputs | split("\t") | {
        disk: .[0],
        config: .[1],
        storage: ((.[1] | split(":"))[0] // ""),
        volume: (try (.[1] | capture("(?<volume>(vm|base)-[0-9]+-disk-[0-9]+)").volume) catch ""),
        size: (try (.[1] | capture("size=(?<size>[0-9.]+[KMGTP]+)").size) catch "")
      }]')

		jq -n \
			--argjson vmid "$vmid" \
			--arg name "$name" \
			--arg status "$status" \
			--argjson runtime_mem_bytes "$current_mem" \
			--argjson maxmem_bytes "$maxmem_bytes" \
			--argjson cpus "$cpus" \
			--argjson maxcpu "$maxcpu" \
			--argjson memory_mb "$memory_mb" \
			--argjson balloon_mb "$balloon_mb" \
			--argjson cores "$cores" \
			--argjson sockets "$sockets" \
			--arg node "$NODE_SHORT" \
			--argjson disks "$disks_json" \
			'{
        vmid: $vmid,
        name: $name,
        status: $status,
        node: $node,
        runtime_mem_bytes: $runtime_mem_bytes,
        maxmem_bytes: $maxmem_bytes,
        memory_mb: $memory_mb,
        balloon_mb: $balloon_mb,
        cpus: $cpus,
        maxcpu: $maxcpu,
        cores: $cores,
        sockets: $sockets,
        disks: $disks
      }'
	done | jq -s '.'
}

build_ct_json() {
	local ctid status_json config name status current_mem maxmem_bytes cpus memory_mb cores
	for ctid in $(printf '%s' "$CT_RUNTIME_JSON" | jq -r '.[].vmid'); do
		status_json=$(printf '%s' "$CT_RUNTIME_JSON" | jq -c --argjson id "$ctid" '.[] | select(.vmid == $id)')
		config=$(pct config "$ctid" 2>/dev/null || true)
		name=$(printf '%s\n' "$config" | awk '/^hostname:/ {print $2; exit}')
		if [[ -z "$name" || "$name" == "null" ]]; then
			name=$(printf '%s' "$status_json" | jq -r '.name // "ct-unknown"')
		fi
		status=$(printf '%s' "$status_json" | jq -r '.status // "unknown"')
		current_mem=$(printf '%s' "$status_json" | jq -r '.mem // 0')
		maxmem_bytes=$(printf '%s' "$status_json" | jq -r '.maxmem // 0')
		cpus=$(printf '%s' "$status_json" | jq -r '.cpus // 0')
		memory_mb=$(printf '%s\n' "$config" | awk '/^memory:/ {print $2; exit}')
		cores=$(printf '%s\n' "$config" | awk '/^cores:/ {print $2; exit}')
		memory_mb=${memory_mb:-0}
		cores=${cores:-0}

		jq -n \
			--argjson ctid "$ctid" \
			--arg name "$name" \
			--arg status "$status" \
			--arg node "$NODE_SHORT" \
			--argjson runtime_mem_bytes "$current_mem" \
			--argjson maxmem_bytes "$maxmem_bytes" \
			--argjson cpus "$cpus" \
			--argjson memory_mb "$memory_mb" \
			--argjson cores "$cores" \
			'{
        ctid: $ctid,
        name: $name,
        status: $status,
        node: $node,
        runtime_mem_bytes: $runtime_mem_bytes,
        maxmem_bytes: $maxmem_bytes,
        memory_mb: $memory_mb,
        cpus: $cpus,
        cores: $cores
      }'
	done | jq -s '.'
}

build_storage_json() {
	local pvesm_json zpool_json dataset_json
	pvesm_json=$(pvesm status 2>/dev/null | awk 'NR>1 {printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\n", $1, $2, $3, $4, $5, $6, $7}' |
		jq -Rn '[inputs | split("\t") | {
      name: .[0],
      type: .[1],
      status: .[2],
      total: .[3],
      used: .[4],
      available: .[5],
      percent: .[6]
    }]')

	if command -v zpool >/dev/null 2>&1; then
		zpool_json=$(zpool list -Hp -o name,size,alloc,free,cap,health 2>/dev/null |
			jq -Rn '[inputs | split("\t") | {
        name: .[0],
        size_bytes: (.[1] | tonumber),
        alloc_bytes: (.[2] | tonumber),
        free_bytes: (.[3] | tonumber),
        cap_pct: (.[4] | tonumber),
        health: .[5]
      }]')

		dataset_json=$(zfs list -Hp -o name,used,avail,referenced -S used 2>/dev/null | awk '/vm-|ct-|base-/ {print; count++; if (count == 10) exit}' |
			jq -Rn '[inputs | split("\t") | {
        name: .[0],
        used_bytes: (.[1] | tonumber),
        avail_bytes: (.[2] | tonumber),
        referenced_bytes: (.[3] | tonumber)
      }]')
	else
		zpool_json='[]'
		dataset_json='[]'
	fi

	jq -n \
		--argjson pvesm "$pvesm_json" \
		--argjson zpools "$zpool_json" \
		--argjson top_datasets "$dataset_json" \
		'{pvesm: $pvesm, zpools: $zpools, top_datasets: $top_datasets}'
}

VMS_JSON=$(build_vm_json)
CTS_JSON=$(build_ct_json)
STORAGE_JSON=$(build_storage_json)

MEMORY_JSON=$(jq -n \
	--argjson total_mem_bytes "$TOTAL_MEM_BYTES" \
	--argjson used_mem_bytes "$USED_MEM_BYTES" \
	--argjson available_mem_bytes "$AVAILABLE_MEM_BYTES" \
	--argjson vms "$VMS_JSON" \
	--argjson cts "$CTS_JSON" \
	'def safe_pct(num; den): if den == 0 then 0 else ((num / den) * 100) end;
   {
     physical: {
       total_bytes: $total_mem_bytes,
       used_bytes: $used_mem_bytes,
       available_bytes: $available_mem_bytes,
       used_pct: (safe_pct($used_mem_bytes; $total_mem_bytes)),
       available_pct: (safe_pct($available_mem_bytes; $total_mem_bytes))
     },
     allocation: {
       vm_allocated_mb: ([$vms[]?.memory_mb] | add // 0),
       vm_running_allocated_mb: ([$vms[] | select(.status == "running") | .memory_mb] | add // 0),
       ct_allocated_mb: ([$cts[]?.memory_mb] | add // 0),
       ct_running_allocated_mb: ([$cts[] | select(.status == "running") | .memory_mb] | add // 0)
     }
   } |
   .allocation.total_allocated_mb = (.allocation.vm_allocated_mb + .allocation.ct_allocated_mb) |
   .allocation.total_running_allocated_mb = (.allocation.vm_running_allocated_mb + .allocation.ct_running_allocated_mb) |
   .allocation.total_allocated_bytes = (.allocation.total_allocated_mb * 1024 * 1024) |
   .allocation.overcommit_bytes = (.allocation.total_allocated_bytes - .physical.total_bytes) |
   .allocation.overcommit_pct = (safe_pct(.allocation.total_allocated_bytes; .physical.total_bytes))')

FINAL_JSON=$(jq -n \
	--arg section "$SECTION" \
	--arg format "$FORMAT" \
	--arg timestamp "$TIMESTAMP" \
	--arg node "$NODE_SHORT" \
	--arg fqdn "$NODE_FQDN" \
	--argjson node_status "$NODE_STATUS_JSON" \
	--argjson cluster_status "$CLUSTER_STATUS_JSON" \
	--argjson cluster_vm_resources "$CLUSTER_VM_RESOURCES_JSON" \
	--argjson vms "$VMS_JSON" \
	--argjson containers "$CTS_JSON" \
	--argjson memory "$MEMORY_JSON" \
	--argjson storage "$STORAGE_JSON" \
	'{
    metadata: {
      section: $section,
      format: $format,
      timestamp: $timestamp,
      node: $node,
      fqdn: $fqdn
    },
    node_status: $node_status,
    cluster_status: $cluster_status,
    memory: $memory,
    storage: $storage,
    inventory: {
      vms: $vms,
      containers: $containers,
      cluster_vm_resources: $cluster_vm_resources
    }
  }')

emit_text_memory() {
	local available_mb total_mb used_pct alloc_mb overcommit_bytes overcommit_mb
	available_mb=$(printf '%s' "$FINAL_JSON" | jq -r '.memory.physical.available_bytes / 1024 / 1024 | floor')
	total_mb=$(printf '%s' "$FINAL_JSON" | jq -r '.memory.physical.total_bytes / 1024 / 1024 | floor')
	used_pct=$(printf '%s' "$FINAL_JSON" | jq -r '.memory.physical.used_pct | floor')
	alloc_mb=$(printf '%s' "$FINAL_JSON" | jq -r '.memory.allocation.total_allocated_mb')
	overcommit_bytes=$(printf '%s' "$FINAL_JSON" | jq -r '.memory.allocation.overcommit_bytes')
	overcommit_mb=$(printf '%s\n' "$overcommit_bytes" | awk '{printf "%d", $1 / 1024 / 1024}')

	print_section "Memory Summary"
	echo "Node: $NODE_FQDN"
	echo "Physical memory: ${total_mb} MB"
	echo "Used memory: $(printf '%s' "$FINAL_JSON" | jq -r '.memory.physical.used_bytes / 1024 / 1024 | floor') MB (${used_pct}%)"
	echo "Available memory: ${available_mb} MB"
	echo "Configured guest allocation: ${alloc_mb} MB"
	echo "Running guest allocation: $(printf '%s' "$FINAL_JSON" | jq -r '.memory.allocation.total_running_allocated_mb') MB"

	if ((available_mb <= MEM_CRIT_MB)); then
		status_label crit "Available memory is below ${MEM_CRIT_MB} MB"
	elif ((available_mb <= MEM_WARN_MB)); then
		status_label warn "Available memory is below ${MEM_WARN_MB} MB"
	else
		status_label ok "Available memory is within threshold"
	fi

	if ((overcommit_bytes > 0)); then
		status_label warn "Configured guest memory exceeds physical memory by ${overcommit_mb} MB"
	else
		status_label ok "Configured guest memory fits within physical memory"
	fi

	echo ""
	echo "VM memory allocation:"
	printf '%s' "$FINAL_JSON" | jq -r '.inventory.vms[] | "  VM \(.vmid) | \(.name) | \(.status) | configured=\(.memory_mb)MB | current=\(if .runtime_mem_bytes >= (1024 * 1024 * 1024) then ((((.runtime_mem_bytes / 1024 / 1024 / 1024) * 10) | floor) / 10 | tostring) + "GB" else ((.runtime_mem_bytes / 1024 / 1024) | floor | tostring) + "MB" end)"'

	echo ""
	echo "Container memory allocation:"
	if [[ $(printf '%s' "$FINAL_JSON" | jq '(.inventory.containers | length)') -eq 0 ]]; then
		echo "  No containers found on this node"
	else
		printf '%s' "$FINAL_JSON" | jq -r '.inventory.containers[] | "  CT \(.ctid) | \(.name) | \(.status) | configured=\(.memory_mb)MB | current=\(if .runtime_mem_bytes >= (1024 * 1024 * 1024) then ((((.runtime_mem_bytes / 1024 / 1024 / 1024) * 10) | floor) / 10 | tostring) + "GB" else ((.runtime_mem_bytes / 1024 / 1024) | floor | tostring) + "MB" end)"'
	fi
}

emit_text_storage() {
	local crit_count warn_count
	print_section "Storage Summary"
	echo "Proxmox storage status:"
	printf '%s' "$FINAL_JSON" | jq -r '.storage.pvesm[] | "  \(.name) | type=\(.type) | status=\(.status) | used=\(.used) | avail=\(.available) | pct=\(.percent)"'

	echo ""
	if [[ $(printf '%s' "$FINAL_JSON" | jq '(.storage.zpools | length)') -gt 0 ]]; then
		echo "ZFS pools:"
		printf '%s' "$FINAL_JSON" | jq -r '.storage.zpools[] | "  \(.name) | used=\(.cap_pct)% | health=\(.health) | free=\((.free_bytes / 1024 / 1024 / 1024) | floor)GB"'
	else
		echo "ZFS pools: none detected"
	fi

	crit_count=$(printf '%s' "$FINAL_JSON" | jq --argjson crit "$STORAGE_CRIT_PCT" '[.storage.zpools[] | select(.cap_pct >= $crit)] | length')
	warn_count=$(printf '%s' "$FINAL_JSON" | jq --argjson warn "$STORAGE_WARN_PCT" --argjson crit "$STORAGE_CRIT_PCT" '[.storage.zpools[] | select(.cap_pct >= $warn and .cap_pct < $crit)] | length')
	if ((crit_count > 0)); then
		status_label crit "${crit_count} ZFS pool(s) at or above ${STORAGE_CRIT_PCT}% usage"
	elif ((warn_count > 0)); then
		status_label warn "${warn_count} ZFS pool(s) at or above ${STORAGE_WARN_PCT}% usage"
	else
		status_label ok "ZFS pool usage is within threshold"
	fi

	echo ""
	echo "Top datasets by used bytes:"
	if [[ $(printf '%s' "$FINAL_JSON" | jq '(.storage.top_datasets | length)') -eq 0 ]]; then
		echo "  No ZFS VM/CT datasets found"
	else
		printf '%s' "$FINAL_JSON" | jq -r '.storage.top_datasets[] | "  \(.name) | used=\((.used_bytes / 1024 / 1024 / 1024) | floor)GB | avail=\((.avail_bytes / 1024 / 1024 / 1024) | floor)GB"'
	fi
}

emit_text_inventory() {
	print_section "Inventory Summary"
	echo "VM count: $(printf '%s' "$FINAL_JSON" | jq '.inventory.vms | length')"
	echo "Container count: $(printf '%s' "$FINAL_JSON" | jq '.inventory.containers | length')"
	echo ""
	echo "VM inventory:"
	printf '%s' "$FINAL_JSON" | jq -r '.inventory.vms[] | ("  VM \(.vmid) | \(.name) | \(.status) | mem=\(.memory_mb)MB | cores=\(.cores) | disks=\(.disks | length)"), (.disks[]? | "    - \(.disk): storage=\(.storage) size=\((.size // "n/a")) volume=\((.volume // "n/a"))")'
	echo ""
	echo "Container inventory:"
	if [[ $(printf '%s' "$FINAL_JSON" | jq '(.inventory.containers | length)') -eq 0 ]]; then
		echo "  No containers found on this node"
	else
		printf '%s' "$FINAL_JSON" | jq -r '.inventory.containers[] | "  CT \(.ctid) | \(.name) | \(.status) | mem=\(.memory_mb)MB | cores=\(.cores)"'
	fi
	echo ""
	echo "Cluster placement view:"
	if [[ $(printf '%s' "$FINAL_JSON" | jq '(.inventory.cluster_vm_resources | length)') -eq 0 ]]; then
		echo "  Cluster resource view unavailable"
	else
		printf '%s' "$FINAL_JSON" | jq -r '.inventory.cluster_vm_resources[] | "  VMID \((.vmid // .id // "n/a")) | \((.name // "n/a")) | node=\((.node // "n/a")) | status=\((.status // "unknown")) | maxmem=\(((.maxmem // 0) / 1024 / 1024 / 1024 | floor))GB"'
	fi
}

emit_json() {
	case "$SECTION" in
	memory)
		printf '%s\n' "$FINAL_JSON" | jq '{metadata, node_status, memory, inventory: {vms: .inventory.vms, containers: .inventory.containers}}'
		;;
	storage)
		printf '%s\n' "$FINAL_JSON" | jq '{metadata, node_status, storage}'
		;;
	inventory)
		printf '%s\n' "$FINAL_JSON" | jq '{metadata, node_status, cluster_status, inventory}'
		;;
	all)
		printf '%s\n' "$FINAL_JSON" | jq '.'
		;;
	esac
}

emit_csv() {
	{
		echo 'category,id,name,status,node,memory_mb,current_mem_bytes,storage,size,used_bytes,extra'
		if [[ "$SECTION" == "all" || "$SECTION" == "memory" || "$SECTION" == "inventory" ]]; then
			printf '%s' "$FINAL_JSON" | jq -r '.inventory.vms[] | ["vm", (.vmid|tostring), .name, .status, .node, (.memory_mb|tostring), (.runtime_mem_bytes|tostring), "", "", "", ("disks=" + ((.disks|length)|tostring))] | @csv'
			printf '%s' "$FINAL_JSON" | jq -r '.inventory.containers[] | ["ct", (.ctid|tostring), .name, .status, .node, (.memory_mb|tostring), (.runtime_mem_bytes|tostring), "", "", "", ""] | @csv'
		fi
		if [[ "$SECTION" == "all" || "$SECTION" == "storage" || "$SECTION" == "inventory" ]]; then
			printf '%s' "$FINAL_JSON" | jq -r '.storage.pvesm[] | ["storage", .name, .name, .status, "", "", "", .name, "", "", ("used=" + .used + ";avail=" + .available + ";pct=" + .percent)] | @csv'
			printf '%s' "$FINAL_JSON" | jq -r '.storage.zpools[] | ["zpool", .name, .name, .health, "", "", "", .name, (.size_bytes|tostring), (.alloc_bytes|tostring), ("free_bytes=" + (.free_bytes|tostring) + ";cap_pct=" + (.cap_pct|tostring))] | @csv'
			printf '%s' "$FINAL_JSON" | jq -r '.storage.top_datasets[] | ["dataset", .name, .name, "", "", "", "", .name, "", (.used_bytes|tostring), ("avail_bytes=" + (.avail_bytes|tostring))] | @csv'
		fi
	}
}

if [[ "$FORMAT" == "json" ]]; then
	emit_json
	exit 0
fi

if [[ "$FORMAT" == "csv" ]]; then
	emit_csv
	exit 0
fi

print_header "Proxmox VE Capacity Check"
echo "Run date: $TIMESTAMP"
echo "Node: $NODE_FQDN"
echo "Section: $SECTION"

case "$SECTION" in
memory)
	emit_text_memory
	;;
storage)
	emit_text_storage
	;;
inventory)
	emit_text_inventory
	;;
all)
	emit_text_memory
	emit_text_storage
	emit_text_inventory
	;;
esac
