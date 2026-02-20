#!/usr/bin/env bash

# ============================================================================
# Configuration File for LLM Energy Consumption Experiments
# ============================================================================

# ────────────────────────────────────────────────────────────────────────────
# Paths
# ────────────────────────────────────────────────────────────────────────────
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENERGIBRIDGE_PATH="${ROOT_DIR}/../energibridge/target/release/energibridge"
OLLAMA_PATH="${OLLAMA_PATH:-ollama}"

# ────────────────────────────────────────────────────────────────────────────
# Experiment Configuration
# ────────────────────────────────────────────────────────────────────────────
# Number of trials per LLM
NUM_TRIALS="${NUM_TRIALS:-30}"

# Number of control trials (no LLM, baseline measurement)
NUM_CONTROL_TRIALS="${NUM_CONTROL_TRIALS:-30}"

# Rest time between trials in seconds
REST_TIME_SECONDS="${REST_TIME_SECONDS:-60}"

# LLM models to test (space-separated list)
LLM_MODELS="${LLM_MODELS:-llama3.1:8b-instruct-q4_K_M llama3.1:8b-instruct-q8_0 llama3.1:8b-instruct-fp16 deepseek-r1:8b-llama-distill-q4_K_M deepseek-r1:8b-llama-distill-q8_0 deepseek-r1:8b-llama-distill-fp16}"

# The time to run the sleep command for obtaining "baseline" energy consumption
CONTROL_SLEEP_SECONDS="${CONTROL_SLEEP_SECONDS:-60}"

# ────────────────────────────────────────────────────────────────────────────
# LLM Query Configuration
# ────────────────────────────────────────────────────────────────────────────
LLM_QUERY="${LLM_QUERY:-Here is a list of 16 words: popular, period, cross, stamp, span, psalm, pass, ryan, lanyard, stretch, reacher, marple, fair, interval, wristband, bosch. Categorize the list into 4 groups of 4 which each share something in common. Categories will always be more specific than '5-LETTER-WORDS', 'NAMES' or 'VERBS'. All words must be used and each word can only be used once. Describe what the 4 categories are and justify your assignment for each word. Fianlly, assess how confident you are that your solution is correct.}" # Puzzle from: https://www.connectionsunlimited.org/?archive=2/2/2026

# ────────────────────────────────────────────────────────────────────────────
# Energibridge Configuration
# ────────────────────────────────────────────────────────────────────────────
# Measurement interval in microseconds
ENERGIBRIDGE_INTERVAL="${ENERGIBRIDGE_INTERVAL:-200}"

# Maximum execution time in seconds (-1 to disable)
ENERGIBRIDGE_MAX_EXECUTION="${ENERGIBRIDGE_MAX_EXECUTION:-60}"

# Enable GPU monitoring (true/false)
ENERGIBRIDGE_GPU="${ENERGIBRIDGE_GPU:-true}"

# LD_LIBRARY_PATH for GPU support (required for NVML on some systems)
# Set this if energibridge can't find NVIDIA libraries
# NixOS example: /run/opengl-driver/lib
# Ubuntu/Debian example: /usr/local/cuda/lib64
# Leave empty if not needed
ENERGIBRIDGE_LD_LIBRARY_PATH="${ENERGIBRIDGE_LD_LIBRARY_PATH:-/run/opengl-driver/lib}"

# Enable summary output (true/false)
ENERGIBRIDGE_SUMMARY="${ENERGIBRIDGE_SUMMARY:-false}"

# CSV separator
ENERGIBRIDGE_SEPARATOR="${ENERGIBRIDGE_SEPARATOR:-,}"

# ────────────────────────────────────────────────────────────────────────────
# Warmup Configuration
# ────────────────────────────────────────────────────────────────────────────
# Duration of warmup phase in seconds (both CPU and GPU)
WARMUP_DURATION="${WARMUP_DURATION:-300}"

# ────────────────────────────────────────────────────────────────────────────
# Output Configuration
# ────────────────────────────────────────────────────────────────────────────
# Base directory for results
RESULTS_DIR="${RESULTS_DIR:-../results}"

# Experiment name (auto-generated if not specified)
EXPERIMENT_NAME="${EXPERIMENT_NAME:-}"

# ────────────────────────────────────────────────────────────────────────────
# Logging Configuration
# ────────────────────────────────────────────────────────────────────────────
# Enable debug logging (true/false)
DEBUG="${DEBUG:-false}"

SHOW_LLM_OUTPUT="${SHOW_LLM_OUTPUT:-false}"

# ────────────────────────────────────────────────────────────────────────────
# Color Codes for Logging
# ────────────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
