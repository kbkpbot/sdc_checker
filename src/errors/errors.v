// SDC Error Definition and Reporting Module
// Defines error types, severity levels, and formatting output

module errors

import os
import constants
import x.json2

// Error Type Enumeration
pub enum ErrorType {
	missing_required_arg     // Missing required argument
	unknown_command          // Unknown command
	invalid_arg_value        // Invalid argument value
	invalid_arg_type         // Invalid argument type
	tcl_syntax_error         // TCL syntax error
	unmatched_brace          // Unmatched brace
	unmatched_bracket        // Unmatched bracket
	unmatched_quote          // Unmatched quote
	empty_pin_list           // Empty pin list
	invalid_separator        // Invalid separator
	variable_undefined       // Variable undefined
	undefined_clock          // Reference to undefined clock
	undefined_port           // Reference to undefined port
	undefined_pin            // Reference to undefined pin
	duplicate_clock          // Duplicate clock definition
	duplicate_constraint     // Duplicate constraint
	self_referencing_clock   // Clock self-reference
}

// Convert ErrorType to ErrorCode
fn error_type_to_code(err_type ErrorType) constants.ErrorCode {
	return match err_type {
		.missing_required_arg { constants.ErrorCode.missing_required_arg }
		.unknown_command { constants.ErrorCode.unknown_command }
		.invalid_arg_value { constants.ErrorCode.invalid_arg_value }
		.invalid_arg_type { constants.ErrorCode.invalid_arg_type }
		.tcl_syntax_error { constants.ErrorCode.tcl_syntax_error }
		.unmatched_brace { constants.ErrorCode.unmatched_brace }
		.unmatched_bracket { constants.ErrorCode.unmatched_bracket }
		.unmatched_quote { constants.ErrorCode.unmatched_quote }
		.empty_pin_list { constants.ErrorCode.empty_pin_list }
		.invalid_separator { constants.ErrorCode.invalid_separator }
		.variable_undefined { constants.ErrorCode.variable_undefined }
		.undefined_clock { constants.ErrorCode.undefined_clock }
		.undefined_port { constants.ErrorCode.undefined_port }
		.undefined_pin { constants.ErrorCode.undefined_pin }
		.duplicate_clock { constants.ErrorCode.duplicate_clock }
		.duplicate_constraint { constants.ErrorCode.duplicate_constraint }
		.self_referencing_clock { constants.ErrorCode.self_referencing_clock }
	}
}

// Warning Type Enumeration
pub enum WarningType {
	negative_delay       // Negative delay value
	zero_period          // Zero period
	large_uncertainty    // Large uncertainty
	ambiguous_wildcard   // Ambiguous wildcard usage
	missing_name         // Missing -name argument
	duplicate_definition // Duplicate definition
	unrealistic_period   // Unrealistic clock period
	unrealistic_delay    // Unrealistic delay value
	unrealistic_transition // Unrealistic transition time
}

// Error Structure
pub struct SdcError {
pub:
	file       string    // File name
	line       int       // Line number
	col        int       // Column number
	error_type ErrorType // Error type
	message    string    // Error message
	suggestion string    // Fix suggestion
	context    string    // Context information (e.g., current command)
}

// Warning Structure
pub struct SdcWarning {
pub:
	file         string
	line         int
	col          int
	warning_type WarningType
	message      string
}

// Error Reporter
pub struct ErrorReporter {
pub mut:
	errors    []SdcError
	warnings  []SdcWarning
	has_error bool
}

// Create new error reporter
pub fn new_error_reporter() ErrorReporter {
	return ErrorReporter{
		errors:    []
		warnings:  []
		has_error: false
	}
}

// Add error
pub fn (mut r ErrorReporter) add_error(err SdcError) {
	r.errors << err
	r.has_error = true
}

// Add warning
pub fn (mut r ErrorReporter) add_warning(warn SdcWarning) {
	r.warnings << warn
}

// Get error type description
fn error_type_desc(err_type ErrorType) string {
	return match err_type {
		.missing_required_arg { 'Missing required argument' }
		.unknown_command { 'Unknown command' }
		.invalid_arg_value { 'Invalid argument value' }
		.invalid_arg_type { 'Invalid argument type' }
		.tcl_syntax_error { 'TCL syntax error' }
		.unmatched_brace { 'Unmatched brace' }
		.unmatched_bracket { 'Unmatched bracket' }
		.unmatched_quote { 'Unmatched quote' }
		.empty_pin_list { 'Empty pin list' }
		.invalid_separator { 'Invalid separator' }
		.variable_undefined { 'Variable undefined' }
		.undefined_clock { 'Reference to undefined clock' }
		.undefined_port { 'Reference to undefined port' }
		.undefined_pin { 'Reference to undefined pin' }
		.duplicate_clock { 'Duplicate clock definition' }
		.duplicate_constraint { 'Duplicate constraint' }
		.self_referencing_clock { 'Clock self-reference' }
	}
}

// Get warning type description
fn warning_type_desc(warn_type WarningType) string {
	return match warn_type {
		.negative_delay { 'Negative delay value' }
		.zero_period { 'Zero period' }
		.large_uncertainty { 'Large uncertainty' }
		.ambiguous_wildcard { 'Ambiguous wildcard' }
		.missing_name { 'Missing name argument' }
		.duplicate_definition { 'Duplicate definition' }
		.unrealistic_period { 'Unrealistic clock period' }
		.unrealistic_delay { 'Unrealistic delay value' }
		.unrealistic_transition { 'Unrealistic transition time' }
	}
}

// Get warning type string identifier (for JSON)
fn warning_type_to_string(warn_type WarningType) string {
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

// Get source line at specified position
fn get_source_line(file_path string, line_num int) string {
	content := os.read_file(file_path) or { return '' }
	lines := content.split('\n')
	if line_num > 0 && line_num <= lines.len {
		return lines[line_num - 1]
	}
	return ''
}

// Format single error output
fn (r &ErrorReporter) format_error(err SdcError) string {
	mut result := ''

	// Display source line (if available)
	source_line := get_source_line(err.file, err.line)
	if source_line.len > 0 {
		result += source_line + '\n'

		// Display position indicator and error info
		mut pointer := ''
		col := err.col
		if col > 1 {
			pointer = ' '.repeat(col - 1)
		}
		pointer += '^'

		// Show tilde to indicate range if suggestion exists
		if err.suggestion.len > 0 {
			pointer += '~'.repeat(5)
		}

		result += pointer + '\n'
	}

	// Error location and message
	result += err.file + ':' + err.line.str() + ':' + err.col.str() + ': error: ' + err.message +
		'\n'

	// Suggestion
	if err.suggestion.len > 0 {
		result += 'suggestion: ' + err.suggestion + '\n'
	}

	result += '\n'

	return result
}

// Format single warning output
fn (r &ErrorReporter) format_warning(warn SdcWarning) string {
	mut result := ''

	// Display source line (if available)
	source_line := get_source_line(warn.file, warn.line)
	if source_line.len > 0 {
		result += source_line + '\n'

		// Display position indicator
		mut pointer := ''
		col := warn.col
		if col > 1 {
			pointer = ' '.repeat(col - 1)
		}
		pointer += '^~~~~'

		result += pointer + '\n'
	}

	// Warning location and message
	result += warn.file + ':' + warn.line.str() + ':' + warn.col.str() + ': warning: ' +
		warn.message + '\n'

	result += '\n'

	return result
}

// Output all errors and warnings
pub fn (r &ErrorReporter) report() {
	// Output errors first
	for err in r.errors {
		println(r.format_error(err))
	}

	// Then output warnings
	for warn in r.warnings {
		println(r.format_warning(warn))
	}

	// Summary
	if r.errors.len > 0 || r.warnings.len > 0 {
		println('-'.repeat(50))
		if r.errors.len > 0 {
			println('Found ${r.errors.len} error(s)')
		}
		if r.warnings.len > 0 {
			println('Found ${r.warnings.len} warning(s)')
		}
	} else {
		println('✓ No errors or warnings found, SDC file check passed!')
	}
}

// Get error count
pub fn (r &ErrorReporter) error_count() int {
	return r.errors.len
}

// Get warning count
pub fn (r &ErrorReporter) warning_count() int {
	return r.warnings.len
}

// JSON Output Structures
pub struct JsonError {
pub:
	file          string
	line          int
	column        int
	error_code    int    // Numeric error code
	error_type    string // Machine-readable error type identifier
	message       string
	suggestion    string
	severity      string
	context       string // Context information
	fix_template  string // Fix template (if applicable)
}

pub struct JsonOutput {
pub:
	version      string   // Tool version
	status       string   // passed/warning/failed
	errors       []JsonError
	warnings     []JsonError
	summary      Summary
	statistics   Statistics  // Statistics
	metadata     Metadata    // Metadata
}

pub struct Statistics {
pub mut:
	total_commands     int     // Total commands checked
	checked_commands   int     // Actually checked commands
	error_count        int
	warning_count      int
	check_duration_ms  int     // Check duration (milliseconds)
}

pub struct Metadata {
pub:
	tool_name    string // Tool name
	version      string // Version
	strict_mode  bool   // Whether strict mode is enabled
	timestamp    string // Check timestamp
}

pub struct Summary {
pub mut:
	error_count   int
	warning_count int
}

// Generate JSON format output
// Stats parameter is used to pass statistics
pub fn (r &ErrorReporter) to_json(stats Statistics, strict_mode bool) string {
	mut json_errors := []JsonError{}
	mut json_warnings := []JsonError{}

	// Convert errors
	for err in r.errors {
		code := error_type_to_code(err.error_type)
		json_errors << JsonError{
			file:         err.file
			line:         err.line
			column:       err.col
			error_code:   int(code)
			error_type:   constants.error_code_identifier(code)
			message:      err.message
			suggestion:   err.suggestion
			severity:     'error'
			context:      err.context
			fix_template: ''
		}
	}

	// Convert warnings
	for warn in r.warnings {
		json_warnings << JsonError{
			file:         warn.file
			line:         warn.line
			column:       warn.col
			error_code:   0
			error_type:   warning_type_to_string(warn.warning_type)
			message:      warn.message
			suggestion:   ''
			severity:     'warning'
			context:      ''
			fix_template: ''
		}
	}

	// Build JSON output
	mut status := 'passed'
	if r.errors.len > 0 {
		status = 'failed'
	} else if r.warnings.len > 0 {
		status = 'warning'
	}

	output := JsonOutput{
		version:    constants.version
		status:     status
		errors:     json_errors
		warnings:   json_warnings
		summary:    Summary{
			error_count:   r.errors.len
			warning_count: r.warnings.len
		}
		statistics: stats
		metadata:   Metadata{
			tool_name:   'sdc_checker'
			version:     constants.version
			strict_mode: strict_mode
			timestamp:   ''  // Filled by caller
		}
	}

	// Generate JSON using x.json2 library
	return json2.encode(output, prettify: true)
}