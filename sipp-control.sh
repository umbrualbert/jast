#!/bin/bash
#
# SIPp Control Script - Menu-driven SIPp scenario execution
# Supports both interactive and remote command execution
#
# Usage:
#   Interactive:     ./sipp-control.sh
#   Remote/CLI:      ./sipp-control.sh [command] [options]
#
# Commands:
#   list-scenarios              List all available scenarios
#   run-uac <scenario>         Run UAC scenario
#   run-uas <scenario>         Run UAS scenario
#   docker-up                  Start Docker containers
#   docker-down                Stop Docker containers
#   status                     Show running containers
#   logs <container>           Show container logs
#   stats                      Show SIPp statistics
#   stop-all                   Stop all SIPp instances

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCENS_DIR="${SCRIPT_DIR}/scens"
LOGS_DIR="${SCRIPT_DIR}/logs"
CONFIG_FILE="${SCRIPT_DIR}/.env"

# Load configuration if exists
if [[ -f "${CONFIG_FILE}" ]]; then
    source "${CONFIG_FILE}"
fi

# Default configuration (can be overridden by .env)
SBC_IP="${SBC_IP:-192.168.1.100}"
SBC_PORT="${SBC_PORT:-5060}"
UAC_IP="${UAC_IP:-172.20.1.1}"
UAS_IP="${UAS_IP:-172.21.1.1}"
UAC_MEDIA_PORT="${UAC_MEDIA_PORT:-16384}"
UAS_MEDIA_PORT="${UAS_MEDIA_PORT:-28384}"
DEFAULT_CPS="${DEFAULT_CPS:-10}"
DEFAULT_MAX_CALLS="${DEFAULT_MAX_CALLS:-100}"
DEFAULT_DURATION="${DEFAULT_DURATION:-60}"

# Ensure logs directory exists
mkdir -p "${LOGS_DIR}"

#==============================================================================
# UTILITY FUNCTIONS
#==============================================================================

print_header() {
    echo -e "\n${CYAN}${BOLD}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}${BOLD}║           SIPp Load Testing - Control System                   ║${NC}"
    echo -e "${CYAN}${BOLD}║           JAST - Just Another SIP Tester v1.0                  ║${NC}"
    echo -e "${CYAN}${BOLD}╚════════════════════════════════════════════════════════════════╝${NC}\n"
}

print_section() {
    echo -e "\n${BLUE}${BOLD}▶ $1${NC}"
    echo -e "${BLUE}$(printf '─%.0s' {1..60})${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ $1${NC}"
}

check_dependencies() {
    local missing=()

    command -v docker >/dev/null 2>&1 || missing+=("docker")

    if [[ ${#missing[@]} -gt 0 ]]; then
        print_error "Missing dependencies: ${missing[*]}"
        print_info "Please install Docker before continuing"
        exit 1
    fi
}

#==============================================================================
# SCENARIO MANAGEMENT
#==============================================================================

list_scenarios() {
    local type="${1:-all}"

    print_section "Available SIPp Scenarios"

    if [[ ! -d "${SCENS_DIR}" ]]; then
        print_error "Scenarios directory not found: ${SCENS_DIR}"
        return 1
    fi

    echo -e "${BOLD}UAC (User Agent Client) Scenarios:${NC}"
    echo "----------------------------------------"
    local count=1
    while IFS= read -r scenario; do
        local basename=$(basename "$scenario" .xml)
        local desc=$(get_scenario_description "$scenario")
        printf "%3d. %-40s %s\n" "$count" "$basename" "$desc"
        ((count++))
    done < <(find "${SCENS_DIR}" -name "*uac*.xml" -o -name "uac.xml" | sort)

    echo ""
    echo -e "${BOLD}UAS (User Agent Server) Scenarios:${NC}"
    echo "----------------------------------------"
    count=1
    while IFS= read -r scenario; do
        local basename=$(basename "$scenario" .xml)
        local desc=$(get_scenario_description "$scenario")
        printf "%3d. %-40s %s\n" "$count" "$basename" "$desc"
        ((count++))
    done < <(find "${SCENS_DIR}" -name "*uas*.xml" -o -name "uas.xml" | sort)

    echo ""
    echo -e "${BOLD}Other Scenarios:${NC}"
    echo "----------------------------------------"
    count=1
    while IFS= read -r scenario; do
        local basename=$(basename "$scenario" .xml)
        local desc=$(get_scenario_description "$scenario")
        printf "%3d. %-40s %s\n" "$count" "$basename" "$desc"
        ((count++))
    done < <(find "${SCENS_DIR}" -maxdepth 1 -name "*.xml" ! -name "*uac*" ! -name "*uas*" ! -name "uac.xml" ! -name "uas.xml" | sort)
}

get_scenario_description() {
    local scenario="$1"
    local basename=$(basename "$scenario" .xml)

    # Scenario descriptions based on filename patterns
    case "$basename" in
        *basic*) echo "[Basic call flow]" ;;
        *register*) echo "[Registration]" ;;
        *subscribe*) echo "[Subscription/Presence]" ;;
        *pcap_g711a*) echo "[G.711 alaw with RTP]" ;;
        *pcap_g711*) echo "[G.711 with RTP]" ;;
        *pcap_g722*) echo "[G.722 wideband]" ;;
        *pcap_g729*) echo "[G.729 codec]" ;;
        *pcap_h264*) echo "[H.264 video]" ;;
        *audio_video*) echo "[Audio+Video]" ;;
        *hold*) echo "[Call hold/resume]" ;;
        *reinvite*) echo "[Re-INVITE test]" ;;
        *refer*) echo "[Call transfer]" ;;
        *dtmf*) echo "[DTMF tones]" ;;
        *fax*) echo "[FAX transmission]" ;;
        *no_sdp*) echo "[No SDP test]" ;;
        *bogus*) echo "[Error injection]" ;;
        *bad_message*) echo "[Malformed message]" ;;
        17minutes*|17March*) echo "[Long duration 17min]" ;;
        *anonymous*) echo "[Anonymous calling]" ;;
        *late_offer*) echo "[Late SDP offer]" ;;
        OPTIONS*) echo "[OPTIONS request]" ;;
        INVITE*) echo "[INVITE test]" ;;
        uac) echo "[Standard UAC]" ;;
        uas) echo "[Standard UAS]" ;;
        *) echo "" ;;
    esac
}

select_scenario() {
    local type="$1"
    local pattern=""

    if [[ "$type" == "uac" ]]; then
        pattern="*uac*.xml"
    elif [[ "$type" == "uas" ]]; then
        pattern="*uas*.xml"
    else
        pattern="*.xml"
    fi

    local scenarios=()
    while IFS= read -r scenario; do
        scenarios+=("$scenario")
    done < <(find "${SCENS_DIR}" -maxdepth 1 -name "$pattern" | sort)

    if [[ ${#scenarios[@]} -eq 0 ]]; then
        print_error "No scenarios found matching pattern: $pattern"
        return 1
    fi

    echo -e "\n${BOLD}Select a scenario:${NC}"
    for i in "${!scenarios[@]}"; do
        local basename=$(basename "${scenarios[$i]}" .xml)
        local desc=$(get_scenario_description "${scenarios[$i]}")
        printf "%3d. %-40s %s\n" $((i+1)) "$basename" "$desc"
    done

    echo -n -e "\n${BOLD}Enter scenario number (or 0 to cancel): ${NC}"
    read -r selection

    if [[ "$selection" == "0" ]] || [[ -z "$selection" ]]; then
        print_info "Cancelled"
        return 1
    fi

    if [[ "$selection" -gt 0 ]] && [[ "$selection" -le "${#scenarios[@]}" ]]; then
        echo "${scenarios[$((selection-1))]}"
        return 0
    else
        print_error "Invalid selection"
        return 1
    fi
}

#==============================================================================
# CONTAINER MANAGEMENT
#==============================================================================

docker_status() {
    print_section "Docker Container Status"

    if ! docker ps -a --filter "name=sipp-" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -q "sipp-"; then
        print_info "No SIPp containers running"
    else
        docker ps -a --filter "name=sipp-" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    fi
}

docker_compose_up() {
    print_section "Starting Docker Containers"

    if [[ -f "${SCRIPT_DIR}/docker-compose.yml" ]]; then
        cd "${SCRIPT_DIR}"
        docker compose up -d
        print_success "Containers started"
        docker_status
    else
        print_error "docker-compose.yml not found"
        print_info "Use manual container creation or create docker-compose.yml"
    fi
}

docker_compose_down() {
    print_section "Stopping Docker Containers"

    if [[ -f "${SCRIPT_DIR}/docker-compose.yml" ]]; then
        cd "${SCRIPT_DIR}"
        docker compose down
        print_success "Containers stopped"
    else
        print_warning "docker-compose.yml not found, stopping individual containers"
        docker ps -a --filter "name=sipp-" --format "{{.Names}}" | xargs -r docker stop
        docker ps -a --filter "name=sipp-" --format "{{.Names}}" | xargs -r docker rm
        print_success "Containers stopped and removed"
    fi
}

show_logs() {
    local container="${1}"

    if [[ -z "$container" ]]; then
        print_error "Container name required"
        echo "Usage: $0 logs <container-name>"
        echo ""
        echo "Available containers:"
        docker ps --filter "name=sipp-" --format "  - {{.Names}}"
        return 1
    fi

    print_section "Logs for container: $container"
    docker logs -f "$container"
}

#==============================================================================
# SIPP EXECUTION
#==============================================================================

run_sipp_uac() {
    local scenario_path="$1"
    local scenario_name=$(basename "$scenario_path" .xml)

    print_section "Configuring UAC Test: $scenario_name"

    # Get test parameters
    echo -e "${BOLD}Test Configuration:${NC}"
    echo -n "Target SBC IP [$SBC_IP]: "
    read -r target_ip
    target_ip=${target_ip:-$SBC_IP}

    echo -n "Target SBC Port [$SBC_PORT]: "
    read -r target_port
    target_port=${target_port:-$SBC_PORT}

    echo -n "Local UAC IP [$UAC_IP]: "
    read -r local_ip
    local_ip=${local_ip:-$UAC_IP}

    echo -n "Media Port [$UAC_MEDIA_PORT]: "
    read -r media_port
    media_port=${media_port:-$UAC_MEDIA_PORT}

    echo -n "Call Rate (CPS) [$DEFAULT_CPS]: "
    read -r cps
    cps=${cps:-$DEFAULT_CPS}

    echo -n "Max Concurrent Calls [$DEFAULT_MAX_CALLS]: "
    read -r max_calls
    max_calls=${max_calls:-$DEFAULT_MAX_CALLS}

    echo -n "Total Calls [1000]: "
    read -r total_calls
    total_calls=${total_calls:-1000}

    echo -n "Use CSV data file? (y/n) [n]: "
    read -r use_csv

    local csv_param=""
    if [[ "$use_csv" == "y" ]] || [[ "$use_csv" == "Y" ]]; then
        echo "Available CSV files:"
        ls -1 "${SCENS_DIR}"/*.csv 2>/dev/null || echo "  (none found)"
        echo -n "CSV filename [2numbers.csv]: "
        read -r csv_file
        csv_file=${csv_file:-2numbers.csv}
        if [[ -f "${SCENS_DIR}/${csv_file}" ]]; then
            csv_param="-inf /scens/${csv_file}"
        else
            print_warning "CSV file not found, continuing without CSV"
        fi
    fi

    # Build SIPp command
    local container_name="sipp-uac-${scenario_name}-$$"
    local log_file="${LOGS_DIR}/${container_name}.log"
    local error_file="${LOGS_DIR}/${container_name}-errors.log"
    local stats_file="${LOGS_DIR}/${container_name}-stats.csv"

    local sipp_args="-i ${local_ip} -mi ${local_ip} -mp ${media_port} \
-sf /scens/$(basename $scenario_path) \
${csv_param} \
-r ${cps} -m ${max_calls} -l ${total_calls} \
-trace_err -error_file /logs/$(basename $error_file) \
-trace_stat -stf /logs/$(basename $stats_file) \
${target_ip}:${target_port}"

    print_section "Starting UAC Container"
    echo -e "${BOLD}Container:${NC} $container_name"
    echo -e "${BOLD}Scenario:${NC}  $scenario_name"
    echo -e "${BOLD}Target:${NC}    $target_ip:$target_port"
    echo -e "${BOLD}Rate:${NC}      $cps CPS, $max_calls concurrent, $total_calls total"
    echo -e "${BOLD}Logs:${NC}      $log_file"
    echo ""

    echo -n "Start test? (y/n) [y]: "
    read -r confirm
    confirm=${confirm:-y}

    if [[ "$confirm" != "y" ]] && [[ "$confirm" != "Y" ]]; then
        print_info "Cancelled"
        return 0
    fi

    # Run container
    docker run -d \
        --name "$container_name" \
        --network host \
        -e ARGS="$sipp_args" \
        -v "${SCENS_DIR}:/scens:ro" \
        -v "${LOGS_DIR}:/logs" \
        sipp:3.7.3

    print_success "Container started: $container_name"
    print_info "Monitor with: docker logs -f $container_name"
    print_info "View stats:   cat $stats_file"

    echo ""
    echo -n "Show live logs? (y/n) [y]: "
    read -r show_logs
    show_logs=${show_logs:-y}

    if [[ "$show_logs" == "y" ]] || [[ "$show_logs" == "Y" ]]; then
        docker logs -f "$container_name"
    fi
}

run_sipp_uas() {
    local scenario_path="$1"
    local scenario_name=$(basename "$scenario_path" .xml)

    print_section "Configuring UAS Test: $scenario_name"

    # Get test parameters
    echo -e "${BOLD}Server Configuration:${NC}"
    echo -n "Local UAS IP [$UAS_IP]: "
    read -r local_ip
    local_ip=${local_ip:-$UAS_IP}

    echo -n "SIP Port [5060]: "
    read -r sip_port
    sip_port=${sip_port:-5060}

    echo -n "Media Port [$UAS_MEDIA_PORT]: "
    read -r media_port
    media_port=${media_port:-$UAS_MEDIA_PORT}

    echo -n "Enable RTP Echo? (y/n) [y]: "
    read -r rtp_echo
    rtp_echo=${rtp_echo:-y}

    local rtp_param=""
    if [[ "$rtp_echo" == "y" ]] || [[ "$rtp_echo" == "Y" ]]; then
        rtp_param="-rtp_echo"
    fi

    # Build SIPp command
    local container_name="sipp-uas-${scenario_name}-$$"
    local log_file="${LOGS_DIR}/${container_name}.log"
    local error_file="${LOGS_DIR}/${container_name}-errors.log"

    local sipp_args="-i ${local_ip} -mi ${local_ip} -mp ${media_port} \
-p ${sip_port} \
-sf /scens/$(basename $scenario_path) \
${rtp_param} \
-trace_err -error_file /logs/$(basename $error_file)"

    print_section "Starting UAS Container"
    echo -e "${BOLD}Container:${NC} $container_name"
    echo -e "${BOLD}Scenario:${NC}  $scenario_name"
    echo -e "${BOLD}Listen:${NC}    $local_ip:$sip_port"
    echo -e "${BOLD}Media:${NC}     $media_port (RTP Echo: $rtp_echo)"
    echo -e "${BOLD}Logs:${NC}      $log_file"
    echo ""

    echo -n "Start server? (y/n) [y]: "
    read -r confirm
    confirm=${confirm:-y}

    if [[ "$confirm" != "y" ]] && [[ "$confirm" != "Y" ]]; then
        print_info "Cancelled"
        return 0
    fi

    # Run container
    docker run -d \
        --name "$container_name" \
        --network host \
        -e ARGS="$sipp_args" \
        -v "${SCENS_DIR}:/scens:ro" \
        -v "${LOGS_DIR}:/logs" \
        sipp:3.7.3

    print_success "Container started: $container_name"
    print_info "Server listening on $local_ip:$sip_port"
    print_info "Monitor with: docker logs -f $container_name"

    echo ""
    echo -n "Show live logs? (y/n) [n]: "
    read -r show_logs
    show_logs=${show_logs:-n}

    if [[ "$show_logs" == "y" ]] || [[ "$show_logs" == "Y" ]]; then
        docker logs -f "$container_name"
    fi
}

run_quick_test() {
    print_section "Quick Test - Basic UAC"

    echo -n "Target IP [$SBC_IP]: "
    read -r target
    target=${target:-$SBC_IP}

    local container_name="sipp-quick-test-$$"

    print_info "Starting quick test to $target:5060 (10 CPS, 50 calls)"

    docker run -d \
        --name "$container_name" \
        --network host \
        -e ARGS="-sf /scens/sipp_uac_basic.xml -r 10 -m 50 ${target}:5060" \
        -v "${SCENS_DIR}:/scens:ro" \
        -v "${LOGS_DIR}:/logs" \
        sipp:3.7.3

    print_success "Quick test started: $container_name"
    docker logs -f "$container_name"
}

stop_all_tests() {
    print_section "Stopping All SIPp Tests"

    local containers=$(docker ps --filter "name=sipp-" --format "{{.Names}}")

    if [[ -z "$containers" ]]; then
        print_info "No running SIPp containers found"
        return 0
    fi

    echo "Found running containers:"
    echo "$containers"
    echo ""
    echo -n "Stop all containers? (y/n) [y]: "
    read -r confirm
    confirm=${confirm:-y}

    if [[ "$confirm" == "y" ]] || [[ "$confirm" == "Y" ]]; then
        echo "$containers" | xargs docker stop
        echo "$containers" | xargs docker rm
        print_success "All containers stopped and removed"
    else
        print_info "Cancelled"
    fi
}

view_statistics() {
    print_section "SIPp Statistics"

    local stat_files=$(find "${LOGS_DIR}" -name "*-stats.csv" -type f 2>/dev/null)

    if [[ -z "$stat_files" ]]; then
        print_info "No statistics files found in ${LOGS_DIR}"
        return 0
    fi

    echo "Available statistics files:"
    local count=1
    local files=()
    while IFS= read -r file; do
        files+=("$file")
        printf "%3d. %s\n" "$count" "$(basename $file)"
        ((count++))
    done <<< "$stat_files"

    echo ""
    echo -n "Select file to view (or 0 to cancel): "
    read -r selection

    if [[ "$selection" == "0" ]] || [[ -z "$selection" ]]; then
        return 0
    fi

    if [[ "$selection" -gt 0 ]] && [[ "$selection" -le "${#files[@]}" ]]; then
        local file="${files[$((selection-1))]}"
        print_info "Viewing: $(basename $file)"
        echo ""

        if command -v column >/dev/null 2>&1; then
            cat "$file" | column -t -s ';'
        else
            cat "$file"
        fi
    fi
}

#==============================================================================
# REMOTE EXECUTION MODE
#==============================================================================

execute_remote_command() {
    local cmd="$1"
    shift

    case "$cmd" in
        list-scenarios)
            list_scenarios "$@"
            ;;
        run-uac)
            if [[ -z "$1" ]]; then
                print_error "Scenario file required"
                echo "Usage: $0 run-uac <scenario.xml> [target_ip] [cps] [max_calls]"
                exit 1
            fi
            run_uac_remote "$@"
            ;;
        run-uas)
            if [[ -z "$1" ]]; then
                print_error "Scenario file required"
                echo "Usage: $0 run-uas <scenario.xml> [local_ip] [port]"
                exit 1
            fi
            run_uas_remote "$@"
            ;;
        docker-up)
            docker_compose_up
            ;;
        docker-down)
            docker_compose_down
            ;;
        status)
            docker_status
            ;;
        logs)
            show_logs "$@"
            ;;
        stats)
            view_statistics
            ;;
        stop-all)
            # Non-interactive stop
            docker ps --filter "name=sipp-" --format "{{.Names}}" | xargs -r docker stop
            docker ps -a --filter "name=sipp-" --format "{{.Names}}" | xargs -r docker rm
            print_success "All containers stopped"
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "Unknown command: $cmd"
            show_help
            exit 1
            ;;
    esac
}

run_uac_remote() {
    local scenario="$1"
    local target="${2:-$SBC_IP}"
    local cps="${3:-$DEFAULT_CPS}"
    local max_calls="${4:-$DEFAULT_MAX_CALLS}"
    local total_calls="${5:-1000}"

    # Find scenario file
    local scenario_path="${SCENS_DIR}/${scenario}"
    if [[ ! -f "$scenario_path" ]]; then
        scenario_path="${SCENS_DIR}/${scenario}.xml"
    fi

    if [[ ! -f "$scenario_path" ]]; then
        print_error "Scenario not found: $scenario"
        exit 1
    fi

    local scenario_name=$(basename "$scenario_path" .xml)
    local container_name="sipp-uac-${scenario_name}-$$"
    local error_file="${LOGS_DIR}/${container_name}-errors.log"
    local stats_file="${LOGS_DIR}/${container_name}-stats.csv"

    local sipp_args="-sf /scens/$(basename $scenario_path) \
-r ${cps} -m ${max_calls} -l ${total_calls} \
-trace_err -error_file /logs/$(basename $error_file) \
-trace_stat -stf /logs/$(basename $stats_file) \
${target}:${SBC_PORT}"

    print_info "Starting UAC: $scenario_name -> $target (${cps} CPS, ${max_calls} concurrent)"

    docker run -d \
        --name "$container_name" \
        --network host \
        -e ARGS="$sipp_args" \
        -v "${SCENS_DIR}:/scens:ro" \
        -v "${LOGS_DIR}:/logs" \
        sipp:3.7.3

    print_success "Container started: $container_name"
    echo "Stats: $stats_file"
}

run_uas_remote() {
    local scenario="$1"
    local local_ip="${2:-$UAS_IP}"
    local port="${3:-5060}"

    # Find scenario file
    local scenario_path="${SCENS_DIR}/${scenario}"
    if [[ ! -f "$scenario_path" ]]; then
        scenario_path="${SCENS_DIR}/${scenario}.xml"
    fi

    if [[ ! -f "$scenario_path" ]]; then
        print_error "Scenario not found: $scenario"
        exit 1
    fi

    local scenario_name=$(basename "$scenario_path" .xml)
    local container_name="sipp-uas-${scenario_name}-$$"

    local sipp_args="-p ${port} -sf /scens/$(basename $scenario_path) -rtp_echo"

    print_info "Starting UAS: $scenario_name listening on $local_ip:$port"

    docker run -d \
        --name "$container_name" \
        --network host \
        -e ARGS="$sipp_args" \
        -v "${SCENS_DIR}:/scens:ro" \
        -v "${LOGS_DIR}:/logs" \
        sipp:3.7.3

    print_success "Server started: $container_name"
}

show_help() {
    cat << EOF
SIPp Control Script - Menu-driven SIPp scenario execution

USAGE:
    Interactive Mode:    $0
    Remote/CLI Mode:     $0 [command] [options]

COMMANDS:
    list-scenarios                     List all available test scenarios
    run-uac <scenario> [ip] [cps] [max] [total]
                                      Run UAC (client) scenario
    run-uas <scenario> [ip] [port]    Run UAS (server) scenario
    docker-up                         Start Docker Compose containers
    docker-down                       Stop Docker Compose containers
    status                            Show running container status
    logs <container>                  Show container logs (follow mode)
    stats                             View SIPp statistics files
    stop-all                          Stop all running SIPp containers
    help                              Show this help message

EXAMPLES:
    # Interactive mode
    $0

    # List all scenarios
    $0 list-scenarios

    # Run UAC scenario (remote execution)
    $0 run-uac sipp_uac_basic 192.168.1.100 20 500 10000

    # Run UAS scenario
    $0 run-uas sipp_uas_basic 192.168.1.50 5060

    # Check status
    $0 status

    # View logs
    $0 logs sipp-uac-basic-12345

CONFIGURATION:
    Edit .env file to set defaults:
        SBC_IP=<target IP>
        SBC_PORT=<target port>
        DEFAULT_CPS=<calls per second>
        DEFAULT_MAX_CALLS=<concurrent calls>

FILES:
    Scenarios:    ${SCENS_DIR}
    Logs:         ${LOGS_DIR}
    Config:       ${CONFIG_FILE}

EOF
}

#==============================================================================
# INTERACTIVE MENU
#==============================================================================

show_menu() {
    print_header

    echo -e "${BOLD}Main Menu:${NC}"
    echo "  1. List Available Scenarios"
    echo "  2. Run UAC (User Agent Client) Test"
    echo "  3. Run UAS (User Agent Server) Test"
    echo "  4. Quick Test (Basic UAC)"
    echo ""
    echo "  5. Docker - Start Containers (docker-compose)"
    echo "  6. Docker - Stop Containers"
    echo "  7. Show Container Status"
    echo "  8. View Container Logs"
    echo ""
    echo "  9. View Statistics"
    echo " 10. Stop All Running Tests"
    echo ""
    echo "  0. Exit"
    echo ""
}

interactive_menu() {
    while true; do
        show_menu
        echo -n -e "${BOLD}Select option: ${NC}"
        read -r option

        case $option in
            1)
                list_scenarios
                echo ""
                read -p "Press Enter to continue..."
                ;;
            2)
                scenario=$(select_scenario "uac")
                if [[ $? -eq 0 ]] && [[ -n "$scenario" ]]; then
                    run_sipp_uac "$scenario"
                fi
                echo ""
                read -p "Press Enter to continue..."
                ;;
            3)
                scenario=$(select_scenario "uas")
                if [[ $? -eq 0 ]] && [[ -n "$scenario" ]]; then
                    run_sipp_uas "$scenario"
                fi
                echo ""
                read -p "Press Enter to continue..."
                ;;
            4)
                run_quick_test
                echo ""
                read -p "Press Enter to continue..."
                ;;
            5)
                docker_compose_up
                echo ""
                read -p "Press Enter to continue..."
                ;;
            6)
                docker_compose_down
                echo ""
                read -p "Press Enter to continue..."
                ;;
            7)
                docker_status
                echo ""
                read -p "Press Enter to continue..."
                ;;
            8)
                echo ""
                docker ps --filter "name=sipp-" --format "{{.Names}}"
                echo ""
                echo -n "Enter container name: "
                read -r container
                if [[ -n "$container" ]]; then
                    show_logs "$container"
                fi
                ;;
            9)
                view_statistics
                echo ""
                read -p "Press Enter to continue..."
                ;;
            10)
                stop_all_tests
                echo ""
                read -p "Press Enter to continue..."
                ;;
            0)
                print_info "Exiting..."
                exit 0
                ;;
            *)
                print_error "Invalid option"
                sleep 1
                ;;
        esac
    done
}

#==============================================================================
# MAIN
#==============================================================================

main() {
    # Check for dependencies
    check_dependencies

    # If no arguments, run interactive menu
    if [[ $# -eq 0 ]]; then
        interactive_menu
    else
        # Remote execution mode
        execute_remote_command "$@"
    fi
}

# Run main function
main "$@"
