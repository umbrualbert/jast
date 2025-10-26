#!/bin/bash
#
# SIPp Monitoring Script
# Real-time monitoring of SIPp containers and test execution
#
# Usage:
#   ./monitor.sh                    # Interactive mode
#   ./monitor.sh status            # Show status once
#   ./monitor.sh watch             # Continuous monitoring
#   ./monitor.sh stats <container> # Show statistics
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOGS_DIR="${SCRIPT_DIR}/../logs"

print_header() {
    clear
    echo -e "${CYAN}${BOLD}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}${BOLD}║              SIPp Real-Time Monitoring Dashboard               ║${NC}"
    echo -e "${CYAN}${BOLD}║              $(date '+%Y-%m-%d %H:%M:%S')                            ║${NC}"
    echo -e "${CYAN}${BOLD}╚════════════════════════════════════════════════════════════════╝${NC}\n"
}

show_container_status() {
    echo -e "${BOLD}Container Status:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    if ! docker ps -a --filter "name=sipp-" --format "table {{.Names}}\t{{.Status}}\t{{.RunningFor}}" | grep -q "sipp-"; then
        echo -e "${YELLOW}No SIPp containers found${NC}"
        return
    fi

    docker ps -a --filter "name=sipp-" --format "table {{.Names}}\t{{.Status}}\t{{.RunningFor}}\t{{.Size}}"
    echo ""
}

show_resource_usage() {
    echo -e "${BOLD}Resource Usage:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    if ! docker ps --filter "name=sipp-" --format "{{.Names}}" | grep -q "sipp-"; then
        echo -e "${YELLOW}No running SIPp containers${NC}"
        return
    fi

    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" \
        $(docker ps --filter "name=sipp-" --format "{{.Names}}")
    echo ""
}

show_network_stats() {
    echo -e "${BOLD}Network Statistics:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Show Docker networks
    docker network ls --filter "name=sipp" --format "table {{.Name}}\t{{.Driver}}\t{{.Scope}}"
    echo ""
}

show_latest_logs() {
    local container="$1"
    local lines="${2:-20}"

    echo -e "${BOLD}Latest Logs: $container (last $lines lines)${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    if docker ps -a --format "{{.Names}}" | grep -q "^${container}$"; then
        docker logs --tail "$lines" "$container" 2>&1 | tail -n "$lines"
    else
        echo -e "${RED}Container not found: $container${NC}"
    fi
    echo ""
}

parse_sipp_stats() {
    local stats_file="$1"

    if [[ ! -f "$stats_file" ]]; then
        echo -e "${YELLOW}Stats file not found: $stats_file${NC}"
        return
    fi

    echo -e "${BOLD}SIPp Statistics: $(basename $stats_file)${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Parse CSV and display key metrics
    if command -v column >/dev/null 2>&1; then
        tail -n 5 "$stats_file" | column -t -s ';'
    else
        tail -n 5 "$stats_file"
    fi
    echo ""
}

show_all_stats() {
    if [[ ! -d "$LOGS_DIR" ]]; then
        echo -e "${YELLOW}Logs directory not found: $LOGS_DIR${NC}"
        return
    fi

    local stats_files=$(find "$LOGS_DIR" -name "*-stats.csv" -type f 2>/dev/null)

    if [[ -z "$stats_files" ]]; then
        echo -e "${YELLOW}No statistics files found${NC}"
        return
    fi

    while IFS= read -r file; do
        parse_sipp_stats "$file"
    done <<< "$stats_files"
}

show_error_summary() {
    echo -e "${BOLD}Error Summary:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    if [[ ! -d "$LOGS_DIR" ]]; then
        echo -e "${YELLOW}Logs directory not found${NC}"
        return
    fi

    local error_files=$(find "$LOGS_DIR" -name "*-errors.log" -type f 2>/dev/null)

    if [[ -z "$error_files" ]]; then
        echo -e "${GREEN}No error logs found${NC}"
        return
    fi

    while IFS= read -r file; do
        local error_count=$(wc -l < "$file" 2>/dev/null || echo "0")
        if [[ $error_count -gt 0 ]]; then
            echo -e "${RED}$(basename $file): $error_count errors${NC}"
            echo "  Last error: $(tail -n 1 "$file" 2>/dev/null || echo 'N/A')"
        else
            echo -e "${GREEN}$(basename $file): No errors${NC}"
        fi
    done <<< "$error_files"
    echo ""
}

show_system_info() {
    echo -e "${BOLD}System Information:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Hostname: $(hostname)"
    echo "Uptime:   $(uptime -p)"
    echo "Load:     $(uptime | awk -F'load average:' '{print $2}')"
    echo ""

    # Network interfaces
    echo -e "${BOLD}Network Interfaces:${NC}"
    ip -br addr | grep -v "^lo" | head -n 5
    echo ""

    # Disk usage for Docker
    echo -e "${BOLD}Docker Disk Usage:${NC}"
    df -h /var/lib/docker 2>/dev/null || echo "N/A"
    echo ""
}

watch_mode() {
    while true; do
        print_header
        show_container_status
        show_resource_usage
        show_error_summary

        echo -e "${CYAN}Refreshing every 5 seconds... (Ctrl+C to exit)${NC}"
        sleep 5
    done
}

interactive_menu() {
    while true; do
        print_header

        echo -e "${BOLD}Monitoring Options:${NC}"
        echo "  1. Container Status"
        echo "  2. Resource Usage"
        echo "  3. Network Statistics"
        echo "  4. View Latest Logs"
        echo "  5. SIPp Statistics"
        echo "  6. Error Summary"
        echo "  7. System Information"
        echo "  8. Watch Mode (auto-refresh)"
        echo "  0. Exit"
        echo ""
        echo -n "Select option: "
        read -r option

        echo ""
        case $option in
            1)
                show_container_status
                read -p "Press Enter to continue..."
                ;;
            2)
                show_resource_usage
                read -p "Press Enter to continue..."
                ;;
            3)
                show_network_stats
                read -p "Press Enter to continue..."
                ;;
            4)
                echo "Available containers:"
                docker ps -a --filter "name=sipp-" --format "  - {{.Names}}"
                echo ""
                echo -n "Enter container name: "
                read -r container
                if [[ -n "$container" ]]; then
                    echo -n "Number of lines [20]: "
                    read -r lines
                    lines=${lines:-20}
                    show_latest_logs "$container" "$lines"
                fi
                read -p "Press Enter to continue..."
                ;;
            5)
                show_all_stats
                read -p "Press Enter to continue..."
                ;;
            6)
                show_error_summary
                read -p "Press Enter to continue..."
                ;;
            7)
                show_system_info
                read -p "Press Enter to continue..."
                ;;
            8)
                watch_mode
                ;;
            0)
                echo "Exiting..."
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option${NC}"
                sleep 1
                ;;
        esac
    done
}

# Main
case "${1:-}" in
    status)
        show_container_status
        show_resource_usage
        ;;
    watch)
        watch_mode
        ;;
    stats)
        if [[ -n "$2" ]]; then
            show_latest_logs "$2" 50
            # Try to find stats file for this container
            local stats_file="${LOGS_DIR}/${2}-stats.csv"
            if [[ -f "$stats_file" ]]; then
                parse_sipp_stats "$stats_file"
            fi
        else
            show_all_stats
        fi
        ;;
    errors)
        show_error_summary
        ;;
    system)
        show_system_info
        ;;
    help|--help|-h)
        echo "SIPp Monitoring Script"
        echo ""
        echo "Usage:"
        echo "  $0                    Interactive menu"
        echo "  $0 status            Show container status"
        echo "  $0 watch             Continuous monitoring (auto-refresh)"
        echo "  $0 stats [container] Show statistics"
        echo "  $0 errors            Show error summary"
        echo "  $0 system            Show system information"
        echo ""
        ;;
    *)
        interactive_menu
        ;;
esac
