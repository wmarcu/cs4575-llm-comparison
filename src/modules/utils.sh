#!/usr/bin/env bash

# ============================================================================
# Utility Functions for LLM Energy Experiments
# ============================================================================

# ────────────────────────────────────────────────────────────────────────────
# Logging Functions
# ────────────────────────────────────────────────────────────────────────────

log_info() {
    echo -e "${BLUE}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_debug() {
    if [[ "${DEBUG:-false}" == "true" ]]; then
        echo -e "${PURPLE}[DEBUG]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
    fi
}

log_section() {
    echo -e "\n${CYAN}════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════════════${NC}\n"
}

# ────────────────────────────────────────────────────────────────────────────
# Utility Functions
# ────────────────────────────────────────────────────────────────────────────

# Detect operating system
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/NIXOS ]; then
            echo "nixos"
        else
            echo "linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    else
        echo "unknown"
    fi
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Sanitize model name for use as directory name
sanitize_model_name() {
    local model="$1"
    # Replace colons with underscores
    echo "${model//:/_}"
}

# Get the original user (before sudo)
get_original_user() {
    if [[ -n "${SUDO_USER:-}" ]]; then
        echo "${SUDO_USER}"
    else
        echo "${USER}"
    fi
}

# Fix ownership of files/directories created by sudo
fix_ownership() {
    local path="$1"
    local original_user
    original_user=$(get_original_user)
    
    # Only fix ownership if running as root and we know the original user
    if [[ "${EUID}" -eq 0 ]] && [[ -n "${original_user}" ]] && [[ "${original_user}" != "root" ]]; then
        log_debug "Fixing ownership of ${path} to ${original_user}"
        chown -R "${original_user}:${original_user}" "${path}" 2>/dev/null || true
    fi
}

# Generate next experiment directory name
generate_experiment_name() {
    local base_dir="$1"
    local counter=1
    
    while [[ -d "${base_dir}/experiment-$(printf '%03d' $counter)" ]]; do
        ((counter++))
    done
    
    echo "experiment-$(printf '%03d' $counter)"
}

# Create experiment directory structure
create_experiment_dirs() {
    local experiment_dir="$1"
    shift
    local models=("$@")
    
    mkdir -p "${experiment_dir}/control"
    
    for model in "${models[@]}"; do
        # Sanitize the model name before using it as a directory name
        local sanitized_model
        sanitized_model=$(sanitize_model_name "$model")
        mkdir -p "${experiment_dir}/${sanitized_model}"
    done
    
    log_success "Created experiment directory structure at: ${experiment_dir}"
}

# Save experiment metadata
save_metadata() {
    local experiment_dir="$1"
    local metadata_file="${experiment_dir}/metadata.json"
    
    # Escape JSON strings
    local escaped_query
    escaped_query=$(escape_json_string "${LLM_QUERY}")
    
    # Build models array
    local models_json=""
    local first=true
    for model in ${LLM_MODELS}; do
        if [[ "$first" == "true" ]]; then
            models_json="\"${model}\""
            first=false
        else
            models_json="${models_json}, \"${model}\""
        fi
    done
    
    cat > "${metadata_file}" <<EOF
{
  "experiment_name": "$(basename "${experiment_dir}")",
  "timestamp": "$(date -u '+%Y-%m-%dT%H:%M:%SZ')",
  "hostname": "$(hostname)",
  "os": "$(detect_os)",
  "configuration": {
    "num_trials": ${NUM_TRIALS},
    "num_control_trials": ${NUM_CONTROL_TRIALS},
    "rest_time_seconds": ${REST_TIME_SECONDS},
    "llm_models": [${models_json}],
    "llm_query": "${escaped_query}",
    "energibridge": {
      "interval": ${ENERGIBRIDGE_INTERVAL},
      "max_execution": ${ENERGIBRIDGE_MAX_EXECUTION},
      "gpu_enabled": ${ENERGIBRIDGE_GPU},
      "summary_enabled": ${ENERGIBRIDGE_SUMMARY}
    },
    "warmup": {
      "duration": ${WARMUP_DURATION}
    }
  }
}
EOF
    
    log_success "Saved experiment metadata to: ${metadata_file}"
}

# Escape special characters for JSON strings
escape_json_string() {
    local str="$1"
    # Escape backslashes first
    str="${str//\\/\\\\}"
    # Escape double quotes
    str="${str//\"/\\\"}"
    # Escape newlines
    str="${str//$'\n'/\\n}"
    # Escape tabs
    str="${str//$'\t'/\\t}"
    # Escape carriage returns
    str="${str//$'\r'/\\r}"
    echo "$str"
}

# Shuffle an array (Fisher-Yates shuffle)
shuffle_array() {
    local -n arr=$1
    local i tmp size rand
    size=${#arr[@]}
    
    for ((i=size-1; i>0; i--)); do
        rand=$((RANDOM % (i+1)))
        tmp="${arr[i]}"
        arr[i]="${arr[rand]}"
        arr[rand]="$tmp"
    done
}
