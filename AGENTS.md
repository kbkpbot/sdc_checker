# SDC File Checker - Project Context

## Project Overview

This is an **SDC (Synopsys Design Constraints) file checker** written in **V Language**, used for validating timing constraint files in digital integrated circuit design.

### Main Features
- **Lexical Analysis**: Decomposes SDC files into Token sequences
- **Syntax Analysis**: Parses TCL/SDC command structures
- **Semantic Checking**: Validates command arguments, variable substitution, constraint rationality
- **Strict Mode**: Additional rationality checks and best practice recommendations
- **JSON Output**: Supports structured result output for CI/CD pipeline integration

### Primary Use Cases

The core use case of this tool is **pre-checking workflow for LLM-generated SDC constraint files**:

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

**Workflow Description:**
1. **Generation Phase**: LLM generates initial SDC constraint files based on design requirements
2. **Pre-check Phase**: Use `sdc_checker` for automated checking of generated SDC files
3. **Feedback Phase**: If errors are found (e.g., missing required parameters, invalid values, undefined variables), detailed error information (including line number, error type, fix suggestions) is fed back to the LLM
4. **Iterative Optimization**: LLM automatically fixes issues based on feedback and regenerates the SDC file
5. **Final Delivery**: When the check passes, the verified SDC file is passed to OpenSTA for formal static timing analysis (STA)

**Advantages:**
- **Early Problem Detection**: Captures syntax and semantic errors before calling OpenSTA, avoiding time-consuming manual debugging
- **Automated Feedback**: JSON format structured output facilitates LLM parsing and understanding of errors
- **Iterative Optimization**: Supports LLM autonomous fixing of issues, reducing manual intervention
- **Quality Assurance**: Strict mode ensures SDC files comply with best practices

### Technology Stack
- **Programming Language**: V (Vlang)
- **Reference Implementation**: OpenSTA (C++)
- **File Format**: SDC/TCL constraint files

---

## Directory Structure

```
/media/HD/github/kbkpbot/sdc_checker/
├── src/                    # V language source code
│   ├── main.v             # Program entry, command line parameter handling
│   ├── tokenizer.v        # Lexical analyzer: converts input to Tokens
│   ├── parser.v           # Syntax analyzer: parses command structures
│   ├── checker.v          # Semantic checker: validates constraint correctness
│   ├── commands.v         # SDC command definitions and parameter specifications
│   ├── variables.v        # TCL variable storage and substitution
│   ├── validators.v       # Parameter value validation functions
│   └── errors.v           # Error definition and reporting module
├── tests/                 # Test cases
│   ├── test_example.sdc   # Example SDC file (correct constraints)
│   ├── test_simple.sdc    # Simple test file
│   ├── test_error.sdc     # Error test file
│   ├── test_comprehensive.sdc      # Comprehensive test
│   └── test_comprehensive_fixed.sdc # Fixed comprehensive test
└── sdc_opensta_ref/       # OpenSTA reference code (C++)
    ├── Sdc.cc, Sdc.tcl    # SDC command implementation
    ├── Clock.cc           # Clock related commands
    ├── PortDelay.cc       # Port delays
    └── ...                # Other reference implementations
```

---

## Building and Running

### Requirements
- Install V Language compiler: https://vlang.io

### Build Commands
```bash
# Compile project
cd /media/HD/github/kbkpbot/sdc_checker
v -o sdc_checker src/main.v

# Or with optimization
v -prod -o sdc_checker src/main.v
```

### Run Commands
```bash
# Basic usage
./sdc_checker <sdc_file>

# Show help
./sdc_checker -h
./sdc_checker --help

# Verbose output
./sdc_checker -V design.sdc
./sdc_checker --verbose design.sdc

# JSON format output
./sdc_checker --json design.sdc

# Strict mode (enable additional checks)
./sdc_checker --strict design.sdc

# Show version
./sdc_checker -v
./sdc_checker --version
```

---

## Supported SDC Commands

### Clock Commands
- `create_clock` - Create clock
- `create_generated_clock` - Create generated clock
- `delete_clock` / `delete_generated_clock` - Delete clocks
- `set_clock_latency` - Set clock latency
- `set_clock_uncertainty` - Set clock uncertainty
- `set_clock_transition` - Set clock transition time
- `set_clock_groups` - Set clock groups
- `set_clock_sense` - Set clock sense attribute
- `set_clock_gating_check` - Set clock gating check

### I/O Constraints
- `set_input_delay` - Set input delay
- `set_output_delay` - Set output delay

### Timing Exceptions
- `set_false_path` - Set false path
- `set_multicycle_path` - Set multicycle path
- `set_max_delay` / `set_min_delay` - Set max/min delay

### Design Rules
- `set_max_transition` - Set max transition time
- `set_max_capacitance` / `set_min_capacitance` - Set max/min capacitance
- `set_max_fanout` - Set max fanout
- `set_case_analysis` - Set case analysis value
- `set_disable_timing` - Disable timing arc

### Object Access Commands
- `get_pins`, `get_ports`, `get_cells`, `get_nets`, `get_clocks`
- `all_inputs`, `all_outputs`, `all_clocks`, `all_registers`

### Environment Setup
- `set_units` - Set units
- `set_hierarchy_separator` - Set hierarchy separator
- `set_operating_conditions` - Set operating conditions
- `set_wire_load_mode` / `set_wire_load_model` - Wire load settings

### Other Commands
- `set`, `echo`, `puts` - TCL basic commands
- `read_sdc`, `write_sdc`, `source` - File operations

---

## Core Module Description

### 1. tokenizer.v - Lexical Analyzer
Decomposes SDC file content into Token sequences, supports:
- TCL strings (double quotes, curly braces)
- Variable references (`$var`, `${var}`)
- Bracket command substitution (`[command]`)
- Comments (starting with `#`)
- Numbers (supports unit suffixes like `10ns`, `1.5pF`)

### 2. parser.v - Syntax Analyzer
Parses Token sequences into structured commands:
- Command name recognition
- Flag argument parsing (`-flag`)
- Key-value pair argument parsing (`-key value`)
- Positional argument extraction

### 3. checker.v - Semantic Checker
Performs comprehensive constraint checking:
- Required parameter checks
- Parameter count validation
- Variable substitution and undefined variable detection
- Parameter value validation (strict mode)
- Constraint rationality checks (period, delay value ranges, etc.)

### 4. commands.v - Command Definitions
Defines all supported SDC commands and their parameter specifications:
- Parameter types (flag, key_value, positional)
- Required/optional flags
- Validator names (for strict mode)
- Positional argument count limits

### 5. validators.v - Validators
Implements various parameter value validation logic:
- Number range validation (clock period, delay values, etc.)
- Unit validation (time, capacitance, resistance, etc.)
- Special format validation (waveform lists, edge lists)

### 6. variables.v - Variable Management
TCL variable storage and substitution:
- `set` command handling
- `$var` and `${var}` format support
- Nested variable recursive substitution
- Undefined variable detection

### 7. errors.v - Error Reporting
Definition and output of errors and warnings:
- Structured error information (file, line, column, suggestions)
- Terminal-friendly formatted output
- JSON format output support

---

## Development Standards

### Code Style
- Use V language standard naming conventions (snake_case)
- Use comments to describe module functionality
- Use `pub` marker for public functions and structs
- Use uppercase for constants (e.g., `version = '1.0.0'`)

### Error Handling
- Use `?Type` optional type for operations that may fail
- Error messages include specific fix suggestions
- Use `eprintln` to output errors to standard error stream
- Return non-zero exit code to indicate check failure

### Testing Practices
- Test files stored in `tests/` directory
- Use `.sdc` extension
- Include both correct and incorrect examples to verify checker

---

## Relationship with OpenSTA

The `sdc_opensta_ref/` directory contains reference code from the OpenSTA project, used for:
- Understanding standard implementation of SDC commands
- Verifying parameter specifications and checking logic
- Ensuring compatibility with industry-standard tools

**Note**: These C++ files are for reference only and do not participate in compilation.

---

## Usage Examples

### Check Correct SDC File
```bash
$ ./sdc_checker tests/test_example.sdc
✓ No errors or warnings found, SDC file check passed!
```

### Check File with Errors
```bash
$ ./sdc_checker tests/test_error.sdc
create_clock -period
             ^~~~~~
tests/test_error.sdc:5:14: error: Command 'create_clock' missing required argument '-period'
suggestion: Example: create_clock -period 10.0 clk

--------------------------------------------------
Found 1 error
```

### JSON Output (for Automation)
```bash
$ ./sdc_checker --json tests/test_example.sdc
{
  "status": "passed",
  "errors": [],
  "warnings": [],
  "summary": {
    "error_count": 0,
    "warning_count": 0
  }
}
```

---

## Extension Guide

### Add New SDC Command
1. Add command definition in `init_commands()` function in `commands.v`
2. Specify parameter list, required parameters, positional argument count limits
3. If needed, add new validators in `validators.v`
4. Add special checking logic in `checker.v` (if applicable)

### Add New Validator
1. Implement validation function in `validators.v`
2. Add dispatch logic in `validate_by_name()`
3. Add error description in `get_validation_error_desc()`
4. Add suggestion information in `get_suggestion_for_validator()`

### Add New Error Type
1. Add new type to `ErrorType` enum in `errors.v`
2. Add description in `error_type_desc()`
3. Use `reporter.add_error()` to report error in checker

---

## FAQ

**Q: Does the tool support all SDC commands?**  
A: Supports the most commonly used SDC commands (about 40+), covering clock, I/O, timing exceptions, design rules, and other major categories.

**Q: How to handle TCL expressions?**  
A: TCL expressions containing brackets (e.g., `[get_ports clk]`) are preserved as-is and skipped during strict mode validation.

**Q: Does variable substitution support nesting?**  
A: Yes, for example `set a 10; set b $a; create_clock -period $b clk` can be correctly parsed.

**Q: Is include/source file supported?**  
A: Currently does not support cross-file variable tracking; each file is checked independently.

---

*This document was automatically generated by iFlow CLI to provide project context information.*