#!/usr/bin/env bash

# ============================================================================
# Trial Runner Module - Execute individual energy measurement trials
# ============================================================================

# Run a single LLM trial with energy measurement
run_llm_trial() {
    local model="$1"
    local trial_number="$2"
    local output_file="$3"
    
    log_debug "Running trial ${trial_number} for model: ${model}"
    
    # Build energibridge command
    local energibridge_cmd="${ENERGIBRIDGE_PATH}"
    energibridge_cmd="${energibridge_cmd} --output \"${output_file}\""
    energibridge_cmd="${energibridge_cmd} --separator \"${ENERGIBRIDGE_SEPARATOR}\""
    energibridge_cmd="${energibridge_cmd} --interval ${ENERGIBRIDGE_INTERVAL}"
    energibridge_cmd="${energibridge_cmd} --max-execution ${ENERGIBRIDGE_MAX_EXECUTION}"
    
    if [[ "${ENERGIBRIDGE_GPU}" == "true" ]]; then
        energibridge_cmd="${energibridge_cmd} --gpu"
    fi
    
    if [[ "${ENERGIBRIDGE_SUMMARY}" == "true" ]]; then
        energibridge_cmd="${energibridge_cmd} --summary"
    fi
    
    # Add the ollama command
    energibridge_cmd="${energibridge_cmd} -- ${OLLAMA_PATH} run ${model} \"${LLM_QUERY}\""
    
    # Execute the command
    log_debug "Executing: ${energibridge_cmd}"
    if [[ "${SHOW_LLM_OUTPUT}" == "true" ]]; then
        # Show LLM output for verification
        echo ""
        log_info "=== LLM Response (Trial ${trial_number}, Model: ${model}) ==="
        eval "${energibridge_cmd}"
        local exit_code=$?
        echo ""
        log_info "=== End of LLM Response ==="
    else
        # Hide output for cleaner logs
        eval "${energibridge_cmd}" > /dev/null 2>&1
        local exit_code=$?
    fi
    
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]] && [[ -f "${output_file}" ]]; then
        log_debug "Trial ${trial_number} completed successfully for ${model}"
        return 0
    else
        log_error "Trial ${trial_number} failed for ${model} (exit code: ${exit_code})"
        return 1
    fi
}

# Run a control trial (baseline measurement without LLM)
run_control_trial() {
    local trial_number="$1"
    local output_file="$2"
    
    log_debug "Running control trial ${trial_number}"
    
    # Build energibridge command for control (just sleep for a short duration)
    local energibridge_cmd="${ENERGIBRIDGE_PATH}"
    energibridge_cmd="${energibridge_cmd} --output \"${output_file}\""
    energibridge_cmd="${energibridge_cmd} --separator \"${ENERGIBRIDGE_SEPARATOR}\""
    energibridge_cmd="${energibridge_cmd} --interval ${ENERGIBRIDGE_INTERVAL}"
    energibridge_cmd="${energibridge_cmd} --max-execution ${ENERGIBRIDGE_MAX_EXECUTION}"
    
    if [[ "${ENERGIBRIDGE_GPU}" == "true" ]]; then
        energibridge_cmd="${energibridge_cmd} --gpu"
    fi
    
    if [[ "${ENERGIBRIDGE_SUMMARY}" == "true" ]]; then
        energibridge_cmd="${energibridge_cmd} --summary"
    fi
    
    # Use sleep as the baseline command
    energibridge_cmd="${energibridge_cmd} -- sleep ${CONTROL_SLEEP_SECONDS}"
    
    # Execute the command
    log_debug "Executing: ${energibridge_cmd}"
    eval "${energibridge_cmd}" > /dev/null 2>&1
    
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]] && [[ -f "${output_file}" ]]; then
        log_debug "Control trial ${trial_number} completed successfully"
        return 0
    else
        log_error "Control trial ${trial_number} failed (exit code: ${exit_code})"
        return 1
    fi
}

# Rest between trials to prevent thermal effects
rest_between_trials() {
    if [[ $REST_TIME_SECONDS -gt 0 ]]; then
        log_debug "Resting for ${REST_TIME_SECONDS} seconds..."
        sleep $REST_TIME_SECONDS
    fi
}

# Generate randomized trial schedule
generate_trial_schedule() {
    local -n schedule=$1
    local models=("${LLM_MODELS}")
    
    # Create array of all trials
    for model in ${models[@]}; do
        for ((i=1; i<=NUM_TRIALS; i++)); do
            schedule+=("${model}")
        done
    done
    
    # Add control trials
    for ((i=1; i<=NUM_CONTROL_TRIALS; i++)); do
        schedule+=("CONTROL")
    done
    
    # Shuffle the schedule
    shuffle_array schedule
    
    log_debug "Generated randomized trial schedule with ${#schedule[@]} total trials"
}

# Execute all trials according to randomized schedule
execute_trials() {
    local experiment_dir="$1"
    
    log_section "Executing Trials"
    
    # Generate randomized trial schedule
    local trial_schedule=()
    generate_trial_schedule trial_schedule
    
    local total_trials=${#trial_schedule[@]}
    log_info "Total trials to execute: ${total_trials}"
    log_info "  - LLM trials: $((total_trials - NUM_CONTROL_TRIALS))"
    log_info "  - Control trials: ${NUM_CONTROL_TRIALS}"
    
    # Track trial numbers for each model
    declare -A model_trial_count
    local control_trial_count=0
    
    # Execute trials in randomized order
    for ((idx=0; idx<total_trials; idx++)); do
        local trial_type="${trial_schedule[$idx]}"
        local progress=$((idx + 1))
        
        log_info "Progress: ${progress}/${total_trials}"
        
        if [[ "${trial_type}" == "CONTROL" ]]; then
            # Control trial
            ((control_trial_count++))
            local output_file="${experiment_dir}/control/trial-$(printf '%03d' $control_trial_count).csv"
            
            log_info "Executing control trial ${control_trial_count}/${NUM_CONTROL_TRIALS}"
            
            if run_control_trial $control_trial_count "${output_file}"; then
                log_success "Control trial ${control_trial_count} completed"
            else
                log_warning "Control trial ${control_trial_count} encountered issues"
            fi
        else
            # LLM trial
            local model="${trial_type}"
            
            # Increment trial count for this model
            if [[ -z "${model_trial_count[$model]:-}" ]]; then
                model_trial_count[$model]=0
            fi
            ((model_trial_count[$model]++))
            
            local trial_num=${model_trial_count[$model]}
            local output_file="${experiment_dir}/${model}/trial-$(printf '%03d' $trial_num).csv"
            
            log_info "Executing trial ${trial_num}/${NUM_TRIALS} for model: ${model}"
            
            if run_llm_trial "${model}" $trial_num "${output_file}"; then
                log_success "Trial ${trial_num} for ${model} completed"
            else
                log_warning "Trial ${trial_num} for ${model} encountered issues"
            fi
        fi
        
        # Rest between trials (except after the last one)
        if [[ $progress -lt $total_trials ]]; then
            rest_between_trials
        fi
    done
    
    log_success "All trials completed!"
}
