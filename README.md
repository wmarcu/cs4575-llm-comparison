# Energy Consumption of Quantized LLMs
This repository contains source code for data collection and analysis in fufillment of the coursework requirements for the [Sustainable Software Engineering (CS4575)](https://studyguide.tudelft.nl/courses/study-guide/educations/14777) course at [Delft University of Technology (Netherlands, EU)](https://se.ewi.tudelft.nl/teaching/). The findings of this study are submitted to the [Course Website](https://luiscruz.github.io/course_sustainableSE/2026/). This repository serves to make the methodology used throughout the study transparent and reproducible.

## Data Collection
Bash scripts are used to automate the data collection process. The `/src/run_experiment.sh` which serves as the main orchestration script. The script's behaviour can be easily configured by editing `/src/config.sh`. To run the script use the following command:

```bash
sudo ./run_experiment.sh
```

### Prerequisites
Important: the script needs `sudo` permissions because Energibridge needs to have the necessary privileges to read energy usage values. Also make sure that any kernal drivers for energy measurements are loaded; for Linux on Intel architectures, this means loading the msr kernel driver using:

```bash
sudo modprobe msr
```

Other requirements for running the script are:
- Energibridge
- Ollama
- Locally available models

### Extending the Script
The script is organised into modules to make it development easier. These modules are imported by the main `run_experiment.sh` script. The modules in question are:
- `prerequisites.sh`: checks if all required programs, tools, and LLMs are available and informs the user of missing dependencies.
- `warmup.sh`: handles warmup logic for avoiding false energy measurements due to hardware cold starts.
- `trial_runner.sh`: builds the ollama and energibridge commands used in each trial, randomly shuffles these commands between different LLMs, collects and organises resulting CSV files, handles rest between different trials to avoid trail energy consumption between readings.
- `utils.sh`: various utility functions.


## Data Analysis
TODO
