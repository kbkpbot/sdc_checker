# Contributing to SDC Checker

Thank you for your interest in contributing to SDC Checker! This document provides guidelines for contributing to this project.

## Code of Conduct

This project and everyone participating in it is governed by our [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

## How Can I Contribute?

### Reporting Bugs

Before creating a bug report, please check the existing issues to see if the problem has already been reported.

When creating a bug report, please include:
- A clear title and description
- Steps to reproduce the issue
- Expected vs actual behavior
- Your environment (OS, V version, SDC Checker version)
- Sample SDC file that triggers the issue (if applicable)

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion:
- Use a clear title
- Provide a detailed description of the proposed feature
- Explain why this enhancement would be useful
- Reference SDC/OpenSTA documentation if applicable

### Pull Requests

1. Fork the repository
2. Create a new branch from `main` for your changes
3. Make your changes following our coding standards
4. Test your changes with the provided test files
5. Submit a pull request

## Development Setup

### Prerequisites

- [V Language](https://vlang.io) compiler (v0.4.0 or later)
- Git

### Building

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/sdc_checker.git
cd sdc_checker

# Compile
v -o sdc_checker src/main.v

# Run tests
./sdc_checker tests/test_example.sdc
```

## Coding Standards

### V Language Style

- Use `snake_case` for variable and function names
- Use `PascalCase` for struct names
- Use `UPPER_CASE` for constants
- Use tabs for indentation
- Keep functions focused and concise

### Code Organization

```
src/
├── module_name/
│   └── module_name.v      # Main module file
│   └── module_name_test.v # Tests (if any)
```

### Documentation

- Add comments for public functions and structs
- Use `//` for single-line comments
- Use `/* */` for multi-line comments only when necessary

### Error Handling

- Use V's optional type (`?Type`) for operations that may fail
- Provide meaningful error messages with suggestions for fixes
- Use the error reporting system in `errors.v`

## Adding New SDC Commands

To add support for a new SDC command:

1. **Define the command** in `src/commands/commands.v`:
   ```v
   cmd := Command{
       name: 'new_command'
       params: [
           Param{name: '-option', ptype: .key_value, required: true},
       ]
   }
   ```

2. **Add validators** (if needed) in `src/validators/validators.v`

3. **Add check logic** in `src/checker/checker.v`

4. **Add test cases** in `tests/` directory

## Testing

### Test Files

Place test SDC files in the `tests/` directory:
- `test_example.sdc` - Valid constraints for basic testing
- `test_error.sdc` - Intentionally invalid constraints
- `test_COMMAND.sdc` - Command-specific tests

### Running Tests

```bash
# Test valid file
./sdc_checker tests/test_example.sdc

# Test with strict mode
./sdc_checker --strict tests/test_example.sdc

# Test with JSON output
./sdc_checker --json tests/test_example.sdc
```

## Commit Messages

Use clear and descriptive commit messages:

- Use the present tense ("Add feature" not "Added feature")
- Use the imperative mood ("Move cursor to..." not "Moves cursor to...")
- Limit the first line to 72 characters
- Reference issues and PRs where appropriate

Example:
```
Add support for set_clock_groups command

- Implement command parsing
- Add validation for clock group types
- Include test cases

Fixes #123
```

## Questions?

Feel free to open an issue for questions or join discussions.

Thank you for contributing!
