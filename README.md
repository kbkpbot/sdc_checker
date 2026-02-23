# SDC Checker

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![V Language](https://img.shields.io/badge/V-0.4.0-5d87bf.svg)](https://vlang.io)
[![GitHub Issues](https://img.shields.io/github/issues/kbkpbot/sdc_checker)](https://github.com/kbkpbot/sdc_checker/issues)
[![GitHub Stars](https://img.shields.io/github/stars/kbkpbot/sdc_checker)](https://github.com/kbkpbot/sdc_checker/stargazers)

A lightweight and efficient SDC (Synopsys Design Constraints) file checker written in [V Language](https://vlang.io), designed for validating timing constraint files in digital integrated circuit design.

## Features

- **Lexical Analysis**: Tokenizes SDC files with support for TCL syntax
- **Syntax Analysis**: Parses TCL/SDC command structures
- **Semantic Checking**: Validates command arguments, variable substitution, and constraint rationality
- **Strict Mode**: Optional additional checks for best practices
- **JSON Output**: Structured output for CI/CD pipeline integration
- **LLM-Friendly**: Designed for automated validation of LLM-generated SDC files

## Use Case: LLM-Generated SDC Pre-check

This tool excels in workflows involving LLM-generated SDC files:

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   LLM Gen   │────▶│ sdc_checker │────▶│   Results   │────▶│ Feedback to │
│  SDC File   │     │  Pre-check  │     │             │     │     LLM     │
└─────────────┘     └─────────────┘     └─────────────┘     └──────┬──────┘
                                                                    │
                              ◄─────────────────────────────────────┘
                              │         Loop until no errors
                              ▼
┌─────────────┐     ┌─────────────┐
│   OpenSTA   │◀────│   Passed    │
│    Timing   │     │   Delivery  │
│   Analysis  │     │             │
└─────────────┘     └─────────────┘
```

**Benefits:**
- Early error detection before running OpenSTA
- Automated feedback for LLM self-correction
- Reduced manual debugging time
- Consistent constraint quality

## Installation

### Prerequisites

- [V Language](https://vlang.io) compiler (v0.4.0 or later)

### Build

```bash
# Clone the repository
git clone https://github.com/kbkpbot/sdc_checker.git
cd sdc_checker

# Compile
v -o sdc_checker src/main.v

# Or with optimization
v -prod -o sdc_checker src/main.v
```

## Usage

### Basic Usage

```bash
./sdc_checker <sdc_file>
```

### Command Line Options

```bash
./sdc_checker -h              # Show help
./sdc_checker -v              # Show version
./sdc_checker -V design.sdc   # Verbose output
./sdc_checker --json design.sdc   # JSON output
./sdc_checker --strict design.sdc # Enable strict mode
```

### Examples

**Check a valid SDC file:**
```bash
$ ./sdc_checker tests/test_example.sdc
✓ No errors or warnings found, SDC file check passed!
```

**Check with errors:**
```bash
$ ./sdc_checker tests/test_error.sdc
create_clock -period
             ^~~~~~
tests/test_error.sdc:5:14: error: Command 'create_clock' missing required argument '-period'
suggestion: Example: create_clock -period 10.0 clk

--------------------------------------------------
Found 1 error
```

**JSON output for automation:**
```bash
$ ./sdc_checker --json tests/test_example.sdc
{
  "version": "1.0.0",
  "status": "passed",
  "errors": [],
  "warnings": [],
  "summary": {
    "error_count": 0,
    "warning_count": 0
  }
}
```

## Supported SDC Commands

### Clock Commands
- `create_clock`, `create_generated_clock`
- `delete_clock`, `delete_generated_clock`
- `set_clock_latency`, `set_clock_uncertainty`
- `set_clock_transition`, `set_clock_groups`
- `set_clock_sense`, `set_clock_gating_check`

### I/O Constraints
- `set_input_delay`, `set_output_delay`

### Timing Exceptions
- `set_false_path`, `set_multicycle_path`
- `set_max_delay`, `set_min_delay`

### Design Rules
- `set_max_transition`, `set_max_capacitance`, `set_min_capacitance`
- `set_max_fanout`, `set_case_analysis`, `set_disable_timing`

### Object Access
- `get_pins`, `get_ports`, `get_cells`, `get_nets`, `get_clocks`
- `all_inputs`, `all_outputs`, `all_clocks`, `all_registers`

### Environment & TCL
- `set_units`, `set_hierarchy_separator`
- `set_operating_conditions`, `set_wire_load_model`
- `set`, `echo`, `puts`, `source`

## Project Structure

```
sdc_checker/
├── src/                    # V language source code
│   ├── main.v             # Program entry point
│   ├── tokenizer/         # Lexical analyzer
│   ├── parser/            # Syntax analyzer
│   ├── checker/           # Semantic checker
│   ├── commands/          # SDC command definitions
│   ├── validators/        # Parameter validators
│   ├── variables/         # TCL variable management
│   ├── errors/            # Error reporting
│   ├── config/            # Configuration
│   ├── constants/         # Constants
│   └── design/            # Design context
├── tests/                 # Test SDC files
└── sdc_opensta_ref/       # OpenSTA reference code
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [OpenSTA](https://github.com/parallaxsw/OpenSTA) - Reference implementation for SDC command specifications
