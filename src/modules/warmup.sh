#!/usr/bin/env bash

# ============================================================================
# Warmup Module - Prevent cold start effects on measurements
# ============================================================================

perform_warmup() {
    log_section "Performing System Warmup"
    
    log_info "Warmup duration: ${WARMUP_DURATION} seconds"
    
    local start_time
    start_time=$(date +%s)
    
    # CPU warmup - run some computational tasks
    log_info "Warming up CPU with Fibonacci computations..."
    cpu_warmup &
    local cpu_warmup_pid=$!
    
    # LLM warmup - send queries for the specified duration
    log_info "Warming up LLM models for ${WARMUP_DURATION} seconds..."
    llm_warmup &
    local llm_warmup_pid=$!
    
    # Wait for both warmup processes to complete
    wait $cpu_warmup_pid 2>/dev/null || true
    wait $llm_warmup_pid 2>/dev/null || true
    
    # Ensure minimum warmup duration
    local current_time
    current_time=$(date +%s)
    local elapsed=$((current_time - start_time))
    
    if [[ $elapsed -lt $WARMUP_DURATION ]]; then
        local remaining=$((WARMUP_DURATION - elapsed))
        log_info "Waiting additional ${remaining} seconds to complete warmup duration..."
        sleep $remaining
    fi
    
    log_success "Warmup completed (total time: $(($(date +%s) - start_time)) seconds)"
    
    log_debug "Resting for ${REST_TIME_SECONDS} seconds..."
    sleep $REST_TIME_SECONDS
}

# CPU warmup function - computes Fibonacci sequences
cpu_warmup() {
    local duration=$WARMUP_DURATION
    local end_time=$(($(date +%s) + duration))
    
    log_debug "Starting CPU warmup with Fibonacci computation"
    
    # Run Fibonacci computations until duration expires
    while [[ $(date +%s) -lt $end_time ]]; do
        # Compute Fibonacci sequence up to a large number
        compute_fibonacci 1000000 >/dev/null 2>&1 &
        
        # Small sleep to prevent overwhelming the system
        sleep 0.1
    done
    
    log_debug "CPU warmup completed"
}

# Compute Fibonacci sequence up to a maximum value
compute_fibonacci() {
    local max_value=$1
    local a=0
    local b=1
    local temp
    
    while [[ $a -lt $max_value ]]; do
        temp=$a
        a=$b
        b=$((temp + b))
    done
    
    echo $a
}

# LLM warmup function - sends queries for the specified duration
llm_warmup() {
    local duration=$WARMUP_DURATION
    local end_time=$(($(date +%s) + duration))
    local query_count=0
    
    log_debug "Starting LLM warmup for ${duration} seconds"
    
    # Keep sending queries until duration expires
    while [[ $(date +%s) -lt $end_time ]]; do
        for model in ${LLM_MODELS}; do
            # Check if we've exceeded the duration
            if [[ $(date +%s) -ge $end_time ]]; then
                break 2
            fi
            
            ((query_count++))
            log_debug "Warmup query ${query_count} for ${model}"
            
            # Send a simple warmup query (suppress output)
            "${OLLAMA_PATH}" run "${model}" "Hello" >/dev/null 2>&1 &
            local ollama_pid=$!
            
            # Wait for query to complete or timeout after 10 seconds
            local timeout=10
            local elapsed=0
            while kill -0 $ollama_pid 2>/dev/null && [[ $elapsed -lt $timeout ]]; do
                sleep 0.5
                ((elapsed++))
            done
            
            # Kill if still running
            if kill -0 $ollama_pid 2>/dev/null; then
                kill $ollama_pid 2>/dev/null
            fi
            
            # Check again if we've exceeded the duration
            if [[ $(date +%s) -ge $end_time ]]; then
                break 2
            fi
        done
    done
    
    log_debug "LLM warmup completed (${query_count} queries sent)"
}
