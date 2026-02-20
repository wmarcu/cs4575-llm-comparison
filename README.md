# Energy Consumption of Quantized LLMs
This repository contains source code for data collection and analysis in fufillment of the coursework requirements for the [Sustainable Software Engineering (CS4575)](https://studyguide.tudelft.nl/courses/study-guide/educations/14777) course at [Delft University of Technology (Netherlands, EU)](https://se.ewi.tudelft.nl/teaching/). The findings of this study are submitted to the [Course Website](https://luiscruz.github.io/course_sustainableSE/2026/). This repository serves to make the methodology used throughout the study transparent and reproducible.

## Data Collection
Bash scripts are used to automate the data collection process. The `/src/run_experiment.sh` which serves as the main orchestration script. The script's behaviour can be easily configured by editing `/src/config.sh`. To run the script use the following command:

### Prerequisites

Requirements for running the script are:
- Energibridge (set the correct path to the executable in `config.sh`)
- Ollama (with required models downloaded)
- Cargo and rustc (if building energibridge from source - required for measuring GPU)

Important: Make sure that any kernal drivers for energy measurements are loaded; for Linux on Intel architectures, this means loading the msr kernel driver using:

```bash
sudo modprobe msr
```

By default, the script needs `sudo` permissions because Energibridge needs to have the necessary privileges to read energy usage values. To avoid having to run as sudo, run the following commands before hand:

```bash
sudo chgrp -R msr /dev/cpu/*/msr;
sudo chmod g+r /dev/cpu/*/msr;
sudo setcap cap_sys_rawio=ep /target/release/energibridge;
```

Important: Nvidia GPU support for Energibridge uses the `nvml-wrapper` crate which must be loaded dynamically. If this library is not available or not in standard search paths, `NVML::init()` will fail silently, causing Energibridge to skip GPU metrics. GPU metrics are also not collected if using a release executable so make sure to build it yourself using:

```bash
cargo build -r;
```

One way to make NVML loadable dynamically is to add `/run/opengl-driver/lib` (a symlink to the current graphics driver) to `LD_LIBRARY_PATH`. This has only been tested on NixOS using Nvidia drivers so this solution might not work for other systems. The command to run is therefore:

```bash
LD_LIBRARY_PATH=/run/opengl-driver/lib ./run_experiment.sh
```

### Extending the Script
The script is organised into modules to make it development easier. These modules are imported by the main `run_experiment.sh` script. The modules in question are:
- `prerequisites.sh`: checks if all required programs, tools, and LLMs are available and informs the user of missing dependencies.
- `warmup.sh`: handles warmup logic for avoiding false energy measurements due to hardware cold starts.
- `trial_runner.sh`: builds the ollama and energibridge commands used in each trial, randomly shuffles these commands between different LLMs, collects and organises resulting CSV files, handles rest between different trials to avoid trail energy consumption between readings.
- `utils.sh`: various utility functions.


## Data Analysis
TODO
