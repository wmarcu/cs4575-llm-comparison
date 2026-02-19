#!/usr/bin/env bash

# ============================================================================
# LLM Energy Consumption Experiment Runner
# ============================================================================
# 
# This script orchestrates energy consumption experiments for LLM models
# using energibridge and Ollama. The script was tested on NixOS but should work
# on other Linux distributions and MacOS.
#
# Usage:
#   ./run_experiment.sh [EXPERIMENT_NAME]
#
# Environment variables can be set to override defaults in config.sh
#
# ============================================================================

# set -euo pipefail

# ────────────────────────────────────────────────────────────────────────────
# Setup
# ────────────────────────────────────────────────────────────────────────────

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load configuration
source "${SCRIPT_DIR}/config.sh"

# Load modules
source "${SCRIPT_DIR}/modules/utils.sh"
source "${SCRIPT_DIR}/modules/prerequisites.sh"
source "${SCRIPT_DIR}/modules/warmup.sh"
source "${SCRIPT_DIR}/modules/trial_runner.sh"

# ────────────────────────────────────────────────────────────────────────────
# Main Execution
# ────────────────────────────────────────────────────────────────────────────

main() {
    # Print banner
    log_section "LLM Energy Consumption Experiment"
    
    log_info "Script directory: ${SCRIPT_DIR}"
    log_info "Configuration loaded from: ${SCRIPT_DIR}/config.sh"
    
    # Parse command line arguments
    if [[ $# -gt 0 ]]; then
        EXPERIMENT_NAME="$1"
        log_info "Experiment name: ${EXPERIMENT_NAME}"
    fi
    
    # Check prerequisites
    if ! check_prerequisites; then
        log_error "Prerequisites check failed. Exiting."
        exit 1
    fi
    
    # Determine experiment directory
    if [[ -z "${EXPERIMENT_NAME}" ]]; then
        EXPERIMENT_NAME=$(generate_experiment_name "${RESULTS_DIR}")
        log_info "Auto-generated experiment name: ${EXPERIMENT_NAME}"
    fi
    
    EXPERIMENT_DIR="${RESULTS_DIR}/${EXPERIMENT_NAME}"
    
    # Check if experiment directory already exists
    if [[ -d "${EXPERIMENT_DIR}" ]]; then
        log_error "Experiment directory already exists: ${EXPERIMENT_DIR}"
        log_error "Please specify a different experiment name or remove the existing directory"
        exit 1
    fi
    
    log_info "Experiment directory: ${EXPERIMENT_DIR}"
    
    # Create experiment directory structure
    local models_array=(${LLM_MODELS})
    create_experiment_dirs "${EXPERIMENT_DIR}" "${models_array[@]}"
    
    # Save metadata
    save_metadata "${EXPERIMENT_DIR}"
    
    # Display experiment configuration
    log_section "Experiment Configuration"
    log_info "Models to test: ${LLM_MODELS}"
    log_info "Trials per model: ${NUM_TRIALS}"
    log_info "Control trials: ${NUM_CONTROL_TRIALS}"
    log_info "Rest time between trials: ${REST_TIME_SECONDS}s"
    log_info "LLM query: ${LLM_QUERY}"
    echo ""
    
    # Perform warmup
    perform_warmup
    
    # Execute trials
    execute_trials "${EXPERIMENT_DIR}"

    # Fix ownership of entire experiment directory if running with sudo
    fix_ownership "${EXPERIMENT_DIR}"
    
    # Final summary
    log_section "Experiment Complete"
    log_success "Experiment '${EXPERIMENT_NAME}' completed successfully!"
    log_info "Results saved to: ${EXPERIMENT_DIR}"
    
    # Count generated files
    local total_files
    total_files=$(find "${EXPERIMENT_DIR}" -name "*.csv" | wc -l)
    log_info "Total CSV files generated: ${total_files}"
}

# ────────────────────────────────────────────────────────────────────────────
# Error Handling
# ────────────────────────────────────────────────────────────────────────────

trap 'log_error "Script interrupted. Cleaning up..."; exit 130' INT TERM

# ────────────────────────────────────────────────────────────────────────────
# Entry Point
# ────────────────────────────────────────────────────────────────────────────

main "$@"
