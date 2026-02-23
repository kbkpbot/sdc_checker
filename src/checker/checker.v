// SDC Checker Core Module
// Implements strict mode command checking logic

module checker

import commands
import constants
import design
import parser
import variables
import validators
import errors

// SDC Checker struct
pub struct SdcChecker {
pub:
	registry     commands.CommandRegistry // Command registry
	file         string                   // Current file being checked
	strict_mode  bool                     // Strict mode flag
	ignore_warns []string                 // List of warning types to ignore
pub mut:
	vars               variables.VariableStore // Variable storage
	reporter           errors.ErrorReporter    // Error reporter
	defined_names      []string                // Record of defined names (for duplicate checking)
	checked_commands   int                     // Number of commands checked
	design_ctx         design.DesignContext    // Design context (for cross-command consistency checking)
	substitution_cache map[string]string       // Variable substitution cache
}

// Create a new SDC checker
pub fn new_checker(file string, strict_mode bool, ignore_warns []string) SdcChecker {
	return SdcChecker{
		registry:           commands.new_command_registry()
		file:               file
		strict_mode:        strict_mode
		ignore_warns:       ignore_warns
		vars:               variables.new_variable_store()
		reporter:           errors.new_error_reporter()
		defined_names:      []
		checked_commands:   0
		design_ctx:         design.new_design_context()
		substitution_cache: map[string]string{}
	}
}

// Check a single command
fn (mut c SdcChecker) check_command(cmd parser.ParsedCommand) {
	// Special handling for set command (used for variable definition)
	if cmd.name == 'set' {
		c.vars.process_set_command(cmd.positionals)
		return
	}

	// Special handling for echo/puts commands (debug commands, skip detailed checking)
	if cmd.name == 'echo' || cmd.name == 'puts' {
		return
	}

	// Get command definition
	cmd_def := c.registry.get_command(cmd.name) or {
		// Unknown command
		c.reporter.add_error(errors.SdcError{
			file:       c.file
			line:       cmd.line
			col:        cmd.col
			error_type: .unknown_command
			message:    "Unknown command '${cmd.name}'"
			suggestion: 'Please check the command spelling'
		})
		return
	}

	// Substitute variables
	mut processed_cmd := c.substitute_variables(cmd)

	// Special handling for create_generated_clock: -source requires a value, but parser treats it as a pure flag
	// If -source is in flags but not in args, move the first positional argument to args
	if cmd.name == 'create_generated_clock' {
		if '-source' in processed_cmd.flags && '-source' !in processed_cmd.args {
			if processed_cmd.positionals.len > 0 {
				mut new_args := processed_cmd.args.clone()
				mut new_flags := processed_cmd.flags.clone()
				mut new_positionals := processed_cmd.positionals.clone()

				// Use the first positional argument as the -source value
				new_args['-source'] = new_positionals[0]
				// Remove -source from flags
				new_flags = new_flags.filter(it != '-source')
				// Remove the first positional argument (explicit clone to avoid warning)
				new_positionals = new_positionals[1..].clone()

				processed_cmd = parser.ParsedCommand{
					name:        processed_cmd.name
					args:        new_args
					flags:       new_flags
					positionals: new_positionals
					line:        processed_cmd.line
					col:         processed_cmd.col
				}
			}
		}
	}

	// Check required arguments
	c.check_required_args(processed_cmd, cmd_def)

	// Check positional argument count
	c.check_positional_args(processed_cmd, cmd_def)

	// Strict mode: validate argument values
	c.validate_arg_values(processed_cmd, cmd_def)

	// Check special rules for specific commands
	c.check_special_rules(processed_cmd, cmd_def)

	// Strict mode: additional checks
	if c.strict_mode {
		c.check_strict_rules(processed_cmd, cmd_def)
	}

	// Track command in design context (for cross-command consistency checking)
	c.track_command_in_context(processed_cmd)
}

// Substitute variables in a single value, return substituted value and whether substitution occurred
// Uses cache for performance optimization
fn (mut c SdcChecker) substitute_single_value(value string, line int, col int) (string, bool) {
	// Fast path: no variable, return directly
	if !value.contains('$') {
		return value, false
	}

	// Check cache
	if cached_value := c.substitution_cache[value] {
		return cached_value, cached_value != value
	}

	// Perform variable substitution
	new_value, undefined_vars := c.vars.substitute(value)

	// Report undefined variables
	for var_name in undefined_vars {
		c.reporter.add_error(errors.SdcError{
			file:       c.file
			line:       line
			col:        col
			error_type: .variable_undefined
			message:    "Variable '${var_name}' is undefined"
			suggestion: 'Use set ${var_name} <value> to define the variable'
		})
	}

	// Save to cache
	c.substitution_cache[value] = new_value

	return new_value, new_value != value
}

// Substitute variables in command
fn (mut c SdcChecker) substitute_variables(cmd parser.ParsedCommand) parser.ParsedCommand {
	// Substitute key-value arguments
	mut new_args := map[string]string{}
	for key, value in cmd.args {
		new_value, _ := c.substitute_single_value(value, cmd.line, cmd.col)
		new_args[key] = new_value
	}

	// Substitute positional arguments
	mut new_positionals := []string{}
	for value in cmd.positionals {
		new_value, _ := c.substitute_single_value(value, cmd.line, cmd.col)
		new_positionals << new_value
	}

	return parser.ParsedCommand{
		name:        cmd.name
		args:        new_args
		flags:       cmd.flags
		positionals: new_positionals
		line:        cmd.line
		col:         cmd.col
	}
}

// Get example values for required arguments
fn get_required_arg_example(cmd_name string, arg_name string) string {
	return match cmd_name {
		'create_clock' {
			if arg_name == '-period' {
				'Example: create_clock -period 10.0 clk'
			} else {
				'Example: create_clock -period 10.0 clk'
			}
		}
		'create_generated_clock' {
			if arg_name == '-source' {
				'Example: create_generated_clock -source clk -divide_by 2 gen_clk'
			} else {
				'Example: create_generated_clock -source clk gen_clk'
			}
		}
		'set_input_delay' {
			'Example: set_input_delay -clock clk 2.5 [get_ports din]'
		}
		'set_output_delay' {
			'Example: set_output_delay -clock clk 3.0 [get_ports dout]'
		}
		'set_false_path' {
			'Example: set_false_path -from [get_pins a] -to [get_pins b]'
		}
		'set_multicycle_path' {
			'Example: set_multicycle_path 2 -setup -from [get_pins a] -to [get_pins b]'
		}
		'set_max_delay' {
			'Example: set_max_delay 10.0 -from [get_pins a] -to [get_pins b]'
		}
		'set_min_delay' {
			'Example: set_min_delay 1.0 -from [get_pins a] -to [get_pins b]'
		}
		else {
			'Add ' + arg_name + ' <value>'
		}
	}
}

// Check required arguments
fn (mut c SdcChecker) check_required_args(cmd parser.ParsedCommand, cmd_def commands.SdcCommand) {
	for arg_def in cmd_def.args {
		if arg_def.required {
			// Check key-value arguments
			if arg_def.arg_type == .key_value {
				if arg_def.name !in cmd.args {
					c.reporter.add_error(errors.SdcError{
						file:       c.file
						line:       cmd.line
						col:        cmd.col
						error_type: .missing_required_arg
						message:    "Command '${cmd.name}' is missing required argument '${arg_def.name}'"
						suggestion: get_required_arg_example(cmd.name, arg_def.name)
					})
				}
			}
		}
	}

	// Check special rule for create_clock: requires -name or at least one positional argument
	if cmd.name == 'create_clock' {
		if '-name' !in cmd.args && cmd.positionals.len == 0 {
			c.reporter.add_error(errors.SdcError{
				file:       c.file
				line:       cmd.line
				col:        cmd.col
				error_type: .missing_required_arg
				message:    "Command 'create_clock' requires -name argument or pin list"
				suggestion: 'Example: create_clock -period 10.0 -name clk [get_pins clk_pin]'
			})
		}
	}
}

// Get positional argument examples for commands
fn get_positional_example(cmd_name string, min_pos int, max_pos int) string {
	return match cmd_name {
		'create_clock' { 'Example: create_clock -period 10.0 clk' }
		'create_generated_clock' { 'Example: create_generated_clock -source clk -divide_by 2 gen_clk' }
		'set_input_delay' { 'Example: set_input_delay -clock clk 2.5 [get_ports din]' }
		'set_output_delay' { 'Example: set_output_delay -clock clk 3.0 [get_ports dout]' }
		'set_max_delay' { 'Example: set_max_delay 10.0 -from [get_pins a] -to [get_pins b]' }
		'set_min_delay' { 'Example: set_min_delay 1.0 -from [get_pins a] -to [get_pins b]' }
		'set_hierarchy_separator' { 'Example: set_hierarchy_separator /' }
		'set_case_analysis' { 'Example: set_case_analysis 0 [get_pins reset]' }
		'set_false_path' { 'Example: set_false_path -from [get_pins reg1/clk] -to [get_pins reg2/d]' }
		'set_multicycle_path' { 'Example: set_multicycle_path 2 -setup -from [get_pins a] -to [get_pins b]' }
		'set_max_transition' { 'Example: set_max_transition 0.5 [get_pins *]' }
		'set_max_capacitance' { 'Example: set_max_capacitance 0.2 [get_pins *]' }
		'set_max_fanout' { 'Example: set_max_fanout 20 [get_pins *]' }
		'set_input_transition' { 'Example: set_input_transition 0.1 [get_ports *]' }
		'set_driving_cell' { 'Example: set_driving_cell -lib_cell BUFX2 [get_ports *]' }
		'set_load' { 'Example: set_load 0.05 [get_ports *]' }
		'set_fanout_load' { 'Example: set_fanout_load 1.0 [get_ports *]' }
		'set_resistance' { 'Example: set_resistance 10.0 [get_nets *]' }
		'set_voltage' { 'Example: set_voltage 0.8' }
		'set_clock_uncertainty' { 'Example: set_clock_uncertainty 0.5 [get_clocks *]' }
		'set_clock_latency' { 'Example: set_clock_latency 0.2 [get_clocks *]' }
		'set_propagated_clock' { 'Example: set_propagated_clock [get_clocks *]' }
		else { '' }
	}
}

// Check positional argument count
fn (mut c SdcChecker) check_positional_args(cmd parser.ParsedCommand, cmd_def commands.SdcCommand) {
	// Debug: print positional arguments (temporarily enabled)
	// println("DEBUG: Positional arguments for command '${cmd.name}': ${cmd.positionals}")

	pos_count := cmd.positionals.len

	// Check minimum count
	if pos_count < cmd_def.min_positional {
		mut suggestion := 'Add ' + (cmd_def.min_positional - pos_count).str() + ' argument(s)'
		example := get_positional_example(cmd.name, cmd_def.min_positional, cmd_def.max_positional)
		if example.len > 0 {
			suggestion = example
		}
		c.reporter.add_error(errors.SdcError{
			file:       c.file
			line:       cmd.line
			col:        cmd.col
			error_type: .missing_required_arg
			message:    "Command '${cmd.name}' requires at least ${cmd_def.min_positional} positional argument(s), but only ${pos_count} provided"
			suggestion: suggestion
		})
	}

	// Check maximum count
	if cmd_def.max_positional >= 0 && pos_count > cmd_def.max_positional {
		mut suggestion := 'Remove ' + (pos_count - cmd_def.max_positional).str() +
			' extra argument(s)'
		example := get_positional_example(cmd.name, cmd_def.min_positional, cmd_def.max_positional)
		if example.len > 0 {
			suggestion = example
		}
		c.reporter.add_error(errors.SdcError{
			file:       c.file
			line:       cmd.line
			col:        cmd.col
			error_type: .invalid_arg_type
			message:    "Command '${cmd.name}' accepts at most ${cmd_def.max_positional} positional argument(s), but ${pos_count} provided"
			suggestion: suggestion
		})
	}
}

// Strict mode: validate argument values
fn (mut c SdcChecker) validate_arg_values(cmd parser.ParsedCommand, cmd_def commands.SdcCommand) {
	// Validate key-value arguments
	for arg_def in cmd_def.args {
		if arg_def.validator.len > 0 {
			if value := cmd.args[arg_def.name] {
				result := validators.validate_by_name(value, arg_def.validator)
				if result != .ok {
					error_desc := validators.get_validation_error_desc(result, arg_def.validator,
						value)
					c.reporter.add_error(errors.SdcError{
						file:       c.file
						line:       cmd.line
						col:        cmd.col
						error_type: .invalid_arg_value
						message:    "Invalid value for argument '${arg_def.name}': ${error_desc}"
						suggestion: validators.get_suggestion_for_validator(arg_def.validator,
							arg_def.name)
					})
				}
			}
		}
	}

	// Check specific warnings
	c.check_warnings(cmd, cmd_def)
}

// 检查警告（非错误）
fn (mut c SdcChecker) check_warnings(cmd parser.ParsedCommand, cmd_def commands.SdcCommand) {
	// Check for negative values in delay-related commands
	if cmd.name in ['set_input_delay', 'set_output_delay', 'set_clock_latency', 'set_max_delay',
		'set_min_delay'] {
		// First positional argument is usually the delay value
		if cmd.positionals.len > 0 {
			delay_value := cmd.positionals[0]
			if validators.is_negative_number(delay_value) {
				c.add_warning_if_not_ignored(errors.SdcWarning{
					file:         c.file
					line:         cmd.line
					col:          cmd.col
					warning_type: .negative_delay
					message:      "Delay value '${delay_value}' is negative, which may cause unexpected timing behavior"
				})
			}
		}
	}

	// Check for zero period in create_clock
	if cmd.name == 'create_clock' {
		if period := cmd.args['-period'] {
			if validators.is_zero(period) {
				c.add_warning_if_not_ignored(errors.SdcWarning{
					file:         c.file
					line:         cmd.line
					col:          cmd.col
					warning_type: .zero_period
					message:      'Clock period is zero, which will cause timing analysis to fail'
				})
			}
		}
	}

	// Check for large values in set_clock_uncertainty
	if cmd.name == 'set_clock_uncertainty' {
		if cmd.positionals.len > 0 {
			uncertainty := cmd.positionals[0]
			if is_valid_number(uncertainty) {
				val := uncertainty.f64()
				if val > constants.max_uncertainty_warning_ns {
					c.add_warning_if_not_ignored(errors.SdcWarning{
						file:         c.file
						line:         cmd.line
						col:          cmd.col
						warning_type: .large_uncertainty
						message:      "Clock uncertainty value '${uncertainty}' is large (>${constants.max_uncertainty_warning_ns}ns), please verify if correct"
					})
				}
			}
		}
	}
}

// Check special rules for specific commands
fn (mut c SdcChecker) check_special_rules(cmd parser.ParsedCommand, cmd_def commands.SdcCommand) {
	// Validation for set_hierarchy_separator
	if cmd.name == 'set_hierarchy_separator' {
		if cmd.positionals.len > 0 {
			sep := cmd.positionals[0]
			result := validators.validate_hierarchy_separator(sep)
			if result != .ok {
				c.reporter.add_error(errors.SdcError{
					file:       c.file
					line:       cmd.line
					col:        cmd.col
					error_type: .invalid_separator
					message:    "无效的层次分隔符 '${sep}'"
					suggestion: '层次分隔符必须是以下字符之一：/ @ ^ # . |'
				})
			}
		}
	}

	// Validation for set_wire_load_mode
	if cmd.name == 'set_wire_load_mode' {
		if cmd.positionals.len > 0 {
			mode := cmd.positionals[0]
			valid_modes := ['top', 'enclosed', 'segmented']
			if mode !in valid_modes {
				c.reporter.add_error(errors.SdcError{
					file:       c.file
					line:       cmd.line
					col:        cmd.col
					error_type: .invalid_arg_value
					message:    "Invalid wire load mode '${mode}'"
					suggestion: 'Valid values are: top, enclosed, segmented'
				})
			}
		}
	}

	// Validation for set_case_analysis
	if cmd.name == 'set_case_analysis' {
		if cmd.positionals.len > 0 {
			value := cmd.positionals[0]
			valid_values := ['0', '1', 'zero', 'one', 'rise', 'fall']
			if value !in valid_values {
				c.reporter.add_error(errors.SdcError{
					file:       c.file
					line:       cmd.line
					col:        cmd.col
					error_type: .invalid_arg_value
					message:    "无效的案例分析值 '${value}'"
					suggestion: '有效值为：0、1、zero、one、rise、fall'
				})
			}
		}
	}
}

// Helper function: check if string is a valid number
fn is_valid_number(s string) bool {
	return validators.validate_number(s) == .ok
}

// Check all commands
pub fn (mut c SdcChecker) check_all(cmds []parser.ParsedCommand) {
	for cmd in cmds {
		c.check_command(cmd)
	}

	// After all commands are checked, perform cross-command consistency checking
	c.check_cross_command_consistency()
}

// Get error reporter
pub fn (c &SdcChecker) get_reporter() errors.ErrorReporter {
	return c.reporter
}

// Check if there are errors
pub fn (c &SdcChecker) has_errors() bool {
	return c.reporter.has_error
}

// Get variable storage (for debugging)
pub fn (c &SdcChecker) get_variables() variables.VariableStore {
	return c.vars
}

// Strict mode checks
fn (mut c SdcChecker) check_strict_rules(cmd parser.ParsedCommand, cmd_def commands.SdcCommand) {
	// 1. Check ambiguous wildcards
	c.check_wildcard_usage(cmd)

	// 2. Check -name argument (for commands that require naming)
	c.check_name_argument(cmd)

	// 3. Check for duplicate definitions
	c.check_duplicate_definition(cmd)

	// 4. Constraint reasonableness check
	c.check_constraint_reasonableness(cmd)
}

// Check wildcard usage
fn (mut c SdcChecker) check_wildcard_usage(cmd parser.ParsedCommand) {
	// Check wildcards in positional arguments
	for pos in cmd.positionals {
		if pos == '*' || pos == '**' {
			c.add_warning_if_not_ignored(errors.SdcWarning{
				file:         c.file
				line:         cmd.line
				col:          cmd.col
				warning_type: .ambiguous_wildcard
				message:      "Strict mode: Using bare wildcard '*' may match too many objects, consider using a more specific pattern like '*/clk'"
			})
		}
	}
}

// Check -name argument
fn (mut c SdcChecker) check_name_argument(cmd parser.ParsedCommand) {
	// For creation commands, recommend using -name
	name_required_commands := ['create_clock', 'create_generated_clock', 'group_path']
	if cmd.name in name_required_commands {
		if '-name' !in cmd.args {
			c.add_warning_if_not_ignored(errors.SdcWarning{
				file:         c.file
				line:         cmd.line
				col:          cmd.col
				warning_type: .missing_name
				message:      "Strict mode: Recommend adding -name argument for '${cmd.name}' to facilitate debugging and tracking"
			})
		}
	}
}

// Check for duplicate definitions
fn (mut c SdcChecker) check_duplicate_definition(cmd parser.ParsedCommand) {
	// For create_clock, check for duplicate clock name definitions
	if cmd.name == 'create_clock' || cmd.name == 'create_generated_clock' {
		if '-name' in cmd.args {
			name := cmd.args['-name']
			if name in c.defined_names {
				c.add_warning_if_not_ignored(errors.SdcWarning{
					file:         c.file
					line:         cmd.line
					col:          cmd.col
					warning_type: .duplicate_definition
					message:      "Strict mode: Clock name '${name}' may be duplicate defined"
				})
			} else {
				c.defined_names << name
			}
		}
	}
}

// Constraint reasonableness check
fn (mut c SdcChecker) check_constraint_reasonableness(cmd parser.ParsedCommand) {
	// 1. Check clock period realism
	if cmd.name == 'create_clock' {
		if period := cmd.args['-period'] {
			c.check_realistic_period(period, cmd.line, cmd.col)
		}
	}

	// 2. Check delay value realism
	if cmd.name in ['set_input_delay', 'set_output_delay', 'set_max_delay', 'set_min_delay'] {
		if cmd.positionals.len > 0 {
			c.check_realistic_delay(cmd.positionals[0], cmd.line, cmd.col)
		}
	}

	// 3. Check transition time realism
	if cmd.name == 'set_clock_transition' || cmd.name == 'set_input_transition' {
		if cmd.positionals.len > 0 {
			c.check_realistic_transition(cmd.positionals[0], cmd.line, cmd.col)
		}
	}

	// 4. Check uncertainty realism
	if cmd.name == 'set_clock_uncertainty' {
		if cmd.positionals.len > 0 {
			c.check_realistic_uncertainty(cmd.positionals[0], cmd.line, cmd.col)
		}
	}
}

// Check realism: clock period
fn (mut c SdcChecker) check_realistic_period(period string, line int, col int) {
	// Check if unit is present
	has_unit := period.contains('ps') || period.contains('ns') || period.contains('us')
		|| period.contains('ms') || period.contains('s')

	num := period.f64()
	// 假设无单位是 ns
	period_ns := if has_unit { num } else { num }

	// Use constants for realism checking
	if period_ns < constants.min_realistic_period_ns {
		c.add_warning_if_not_ignored(errors.SdcWarning{
			file:         c.file
			line:         line
			col:          col
			warning_type: .unrealistic_period
			message:      'Clock period ${period} is too small (< ${constants.min_realistic_period_ns}ns), may be unrealistic'
		})
	}
	if period_ns > constants.max_realistic_period_ns {
		c.add_warning_if_not_ignored(errors.SdcWarning{
			file:         c.file
			line:         line
			col:          col
			warning_type: .unrealistic_period
			message:      'Clock period ${period} is too large (> ${constants.max_realistic_period_ns}ns), may be unrealistic'
		})
	}
}

// Check realism: delay value
fn (mut c SdcChecker) check_realistic_delay(delay string, line int, col int) {
	num := delay.f64()
	if num < 0 {
		// Negative delay already warned elsewhere
		return
	}
	// 假设无单位是 ns
	if num > constants.max_realistic_delay_ns {
		c.add_warning_if_not_ignored(errors.SdcWarning{
			file:         c.file
			line:         line
			col:          col
			warning_type: .unrealistic_delay
			message:      'Delay value ${delay} is too large (> ${constants.max_realistic_delay_ns}ns), please verify if correct'
		})
	}
}

// Check realism: transition time
fn (mut c SdcChecker) check_realistic_transition(transition string, line int, col int) {
	num := transition.f64()
	if num < 0 {
		return
	}
	// Transition time is usually very small
	if num > constants.max_realistic_transition_ns {
		c.add_warning_if_not_ignored(errors.SdcWarning{
			file:         c.file
			line:         line
			col:          col
			warning_type: .unrealistic_transition
			message:      'Transition time ${transition} is too large (> ${constants.max_realistic_transition_ns}ns), please verify if correct'
		})
	}
}

// Check realism: uncertainty
fn (mut c SdcChecker) check_realistic_uncertainty(uncertainty string, line int, col int) {
	num := uncertainty.f64()
	if num < 0 {
		return
	}
	if num > constants.max_uncertainty_warning_ns {
		c.add_warning_if_not_ignored(errors.SdcWarning{
			file:         c.file
			line:         line
			col:          col
			warning_type: .large_uncertainty
			message:      'Clock uncertainty ${uncertainty} is too large (> ${constants.max_uncertainty_warning_ns}ns), please verify if correct'
		})
	}
}

// Helper method: add warning (skip if ignored)
fn (mut c SdcChecker) add_warning_if_not_ignored(warn errors.SdcWarning) {
	// Check if this warning type is in the ignore list
	warn_type_str := warning_type_to_string(warn.warning_type)
	if warn_type_str in c.ignore_warns {
		return
	}
	c.reporter.add_warning(warn)
}

// Get string identifier for warning type
fn warning_type_to_string(warn_type errors.WarningType) string {
	return match warn_type {
		.negative_delay { 'negative_delay' }
		.zero_period { 'zero_period' }
		.large_uncertainty { 'large_uncertainty' }
		.ambiguous_wildcard { 'ambiguous_wildcard' }
		.missing_name { 'missing_name' }
		.duplicate_definition { 'duplicate_definition' }
		.unrealistic_period { 'unrealistic_period' }
		.unrealistic_delay { 'unrealistic_delay' }
		.unrealistic_transition { 'unrealistic_transition' }
	}
}

// ========== Design Context Tracking Methods ==========

// Track command in design context
fn (mut c SdcChecker) track_command_in_context(cmd parser.ParsedCommand) {
	match cmd.name {
		'create_clock' {
			c.track_create_clock(cmd)
		}
		'create_generated_clock' {
			c.track_create_generated_clock(cmd)
		}
		'set_input_delay' {
			c.track_io_delay(cmd, 'input')
		}
		'set_output_delay' {
			c.track_io_delay(cmd, 'output')
		}
		'set_clock_groups' {
			c.track_clock_groups(cmd)
		}
		'set_false_path', 'set_multicycle_path', 'set_max_delay', 'set_min_delay' {
			c.track_timing_exception(cmd)
		}
		else {}
	}
}

// Track create_clock command
fn (mut c SdcChecker) track_create_clock(cmd parser.ParsedCommand) {
	mut name := ''
	mut period := ''
	mut source := ''

	if '-name' in cmd.args {
		name = cmd.args['-name']
	}
	if '-period' in cmd.args {
		period = cmd.args['-period']
	}

	// Check for duplicate definition
	if name.len > 0 && c.design_ctx.is_clock_defined(name) {
		c.reporter.add_error(errors.SdcError{
			file:       c.file
			line:       cmd.line
			col:        cmd.col
			error_type: .duplicate_clock
			message:    "Clock '${name}' is already defined"
			suggestion: 'Use a different clock name, or remove the duplicate definition'
		})
		return
	}

	// Register clock
	if name.len > 0 {
		c.design_ctx.register_clock(name, period, source, cmd.line, cmd.col, false)
	}
}

// Track create_generated_clock command
fn (mut c SdcChecker) track_create_generated_clock(cmd parser.ParsedCommand) {
	mut name := ''
	mut source := ''

	if '-name' in cmd.args {
		name = cmd.args['-name']
	}
	if '-source' in cmd.args {
		source = cmd.args['-source']
	}

	// Check for duplicate name
	if name.len > 0 && c.design_ctx.is_clock_defined(name) {
		c.reporter.add_error(errors.SdcError{
			file:       c.file
			line:       cmd.line
			col:        cmd.col
			error_type: .duplicate_clock
			message:    "Clock '${name}' is already defined"
			suggestion: 'Use a different clock name, or remove the duplicate definition'
		})
		return
	}

	// Check for self-reference
	if name == source {
		c.reporter.add_error(errors.SdcError{
			file:       c.file
			line:       cmd.line
			col:        cmd.col
			error_type: .self_referencing_clock
			message:    "Generated clock '${name}' cannot reference itself as source clock"
			suggestion: 'Specify a different master clock as the -source argument'
		})
		return
	}

	// Check if source clock is defined
	if source.len > 0 && !c.design_ctx.is_clock_defined(source) {
		c.reporter.add_error(errors.SdcError{
			file:       c.file
			line:       cmd.line
			col:        cmd.col
			error_type: .undefined_clock
			message:    "Generated clock references undefined source clock '${source}'"
			suggestion: 'Define the source clock using create_clock first, or check the clock name spelling'
		})
		return
	}

	// Register generated clock
	if name.len > 0 && source.len > 0 {
		c.design_ctx.register_generated_clock(name, source, cmd.line, cmd.col)
	}
}

// Track I/O delay commands
fn (mut c SdcChecker) track_io_delay(cmd parser.ParsedCommand, direction string) {
	mut clock_name := ''
	mut port_name := ''

	if '-clock' in cmd.args {
		clock_name = cmd.args['-clock']
	}

	// Extract port name from positional arguments (simplified handling)
	if cmd.positionals.len >= 2 {
		port_name = cmd.positionals[1]
	}

	// Verify clock exists
	if clock_name.len > 0 && !c.design_ctx.is_clock_defined(clock_name) {
		c.reporter.add_error(errors.SdcError{
			file:       c.file
			line:       cmd.line
			col:        cmd.col
			error_type: .undefined_clock
			message:    "${direction} delay references undefined clock '${clock_name}'"
			suggestion: 'Define the clock using create_clock first, or check the clock name spelling'
		})
	}

	// Register port
	if port_name.len > 0 {
		c.design_ctx.register_port(port_name, direction, cmd.line)
		if clock_name.len > 0 {
			c.design_ctx.associate_port_clock(port_name, clock_name)
		}
	}

	// 记录约束
	if port_name.len > 0 {
		c.design_ctx.record_constraint(cmd.name, port_name, clock_name, cmd.line, 'delay')
	}
}

// Track clock group commands
fn (mut c SdcChecker) track_clock_groups(cmd parser.ParsedCommand) {
	mut group_type := ''
	mut clocks := []string{}

	if '-exclusive' in cmd.flags {
		group_type = 'exclusive'
	} else if '-asynchronous' in cmd.flags {
		group_type = 'asynchronous'
	}

	// Extract clock group from args (simplified handling)
	if '-group' in cmd.args {
		// Simplified handling here, actual implementation should parse the list
		clocks << cmd.args['-group']
	}

	// Verify all clocks in the group are defined
	for clock_name in clocks {
		if !c.design_ctx.is_clock_defined(clock_name) {
			c.reporter.add_error(errors.SdcError{
				file:       c.file
				line:       cmd.line
				col:        cmd.col
				error_type: .undefined_clock
				message:    "Clock group references undefined clock '${clock_name}'"
				suggestion: '先使用 create_clock 定义时钟，或从组中移除该时钟'
			})
		}
	}

	if group_type.len > 0 && clocks.len > 0 {
		c.design_ctx.register_clock_group(group_type, clocks, cmd.line)
	}
}

// Track timing exception commands
fn (mut c SdcChecker) track_timing_exception(cmd parser.ParsedCommand) {
	// Record constraint for duplicate detection
	mut target := ''
	if '-to' in cmd.args {
		target = cmd.args['-to']
	} else if cmd.positionals.len > 0 {
		target = cmd.positionals[0]
	}

	if target.len > 0 {
		c.design_ctx.record_constraint(cmd.name, target, '', cmd.line, 'exception')
	}
}

// Perform cross-command consistency checking (called after all commands are checked)
fn (mut c SdcChecker) check_cross_command_consistency() {
	// Check for undefined clock references
	undefined_refs := c.design_ctx.get_undefined_clock_references()
	for clock_name, refs in undefined_refs {
		for ref in refs {
			c.reporter.add_error(errors.SdcError{
				file:       c.file
				line:       ref.line
				col:        ref.col
				error_type: .undefined_clock
				message:    "References undefined clock '${clock_name}'"
				suggestion: 'Define the clock using create_clock first, or check the clock name spelling'
			})
		}
	}
}
