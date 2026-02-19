#!/usr/bin/env bash

# ============================================================================
# Prerequisites Check Module
# ============================================================================

check_prerequisites() {
    log_section "Checking Prerequisites"
    
    local all_ok=true
    local os_type
    os_type=$(detect_os)
    
    log_info "Detected OS: ${os_type}"
    
    # Check if OS is supported
    if [[ "${os_type}" != "nixos" && "${os_type}" != "macos" && "${os_type}" != "linux" ]]; then
        log_error "Unsupported operating system: ${OSTYPE}"
        log_error "This script supports NixOS, macOS, and Linux only"
        all_ok=false
    else
        log_success "Operating system is supported"
    fi
    
    # Check for energibridge
    log_info "Checking for energibridge..."
    if command_exists "${ENERGIBRIDGE_PATH}"; then
        local energibridge_version
        energibridge_version=$("${ENERGIBRIDGE_PATH}" --version 2>&1 || echo "unknown")
        log_success "energibridge found: ${energibridge_version}"
    else
        log_error "energibridge not found at: ${ENERGIBRIDGE_PATH}"
        log_error "Please install energibridge or set ENERGIBRIDGE_PATH to the correct location"
        all_ok=false
    fi

    # Check for msr kernel module (required for Intel RAPL energy measurement)
    if [[ "${os_type}" == "linux" || "${os_type}" == "nixos" ]]; then
        log_info "Checking for msr kernel module..."
        if lsmod | grep -q "^msr"; then
            log_success "msr kernel module is loaded"
        else
            log_error "msr kernel module is not loaded"
            log_error "Energibridge requires msr module for CPU energy measurement"
            log_error "Load it with: sudo modprobe msr"
            all_ok=false
        fi
    fi
    
    # Check for ollama
    log_info "Checking for ollama..."
    if command_exists "${OLLAMA_PATH}"; then
        local ollama_version
        ollama_version=$("${OLLAMA_PATH}" --version 2>&1 || echo "unknown")
        log_success "ollama found: ${ollama_version}"
        
        # Check if ollama service is running
        if "${OLLAMA_PATH}" list >/dev/null 2>&1; then
            log_success "ollama service is running"
        else
            log_error "ollama service may not be running"
            log_error "Please ensure ollama is running before starting experiments."
            log_error "To start ollama, run: ollama serve"
            all_ok=false
        fi
    else
        log_error "ollama not found at: ${OLLAMA_PATH}"
        log_error "Please install ollama or set OLLAMA_PATH to the correct location"
        all_ok=false
    fi
    
    # Check for required utilities
    # log_info "Checking for required utilities..."
    
    # local required_commands=("jq" "bc")
    # for cmd in "${required_commands[@]}"; do
    #     if command_exists "$cmd"; then
    #         log_success "$cmd is installed"
    #     else
    #         log_error "$cmd is not installed"
    #         log_error "Please install $cmd to continue"
    #         all_ok=false
    #     fi
    # done
    
    # Check if specified LLM models are available
    if [[ "${all_ok}" == "true" ]]; then
        log_info "Checking if specified LLM models are available..."
        
        local available_models
        available_models=$("${OLLAMA_PATH}" list 2>/dev/null | tail -n +2 | awk '{print $1}')
        
        for model in ${LLM_MODELS}; do
            if echo "${available_models}" | grep -q "^${model}$"; then
                log_success "Model '${model}' is available"
            else
                log_error "Model '${model}' not found in ollama"
                log_error "Download it using: ollama pull ${model}"
                all_ok=false
            fi
        done
    fi
    
    # Check write permissions for results directory
    log_info "Checking write permissions for results directory..."
    if [[ -d "${RESULTS_DIR}" ]]; then
        if [[ -w "${RESULTS_DIR}" ]]; then
            log_success "Results directory is writable: ${RESULTS_DIR}"
        else
            log_error "Results directory is not writable: ${RESULTS_DIR}"
            all_ok=false
        fi
    else
        # Try to create it
        if mkdir -p "${RESULTS_DIR}" 2>/dev/null; then
            log_success "Created results directory: ${RESULTS_DIR}"
        else
            log_error "Cannot create results directory: ${RESULTS_DIR}"
            all_ok=false
        fi
    fi
    
    # Final status
    echo ""
    if [[ "${all_ok}" == "true" ]]; then
        log_success "All prerequisites checks passed!"
        return 0
    else
        log_error "Some prerequisites checks failed. Please fix the issues above."
        return 1
    fi
}
