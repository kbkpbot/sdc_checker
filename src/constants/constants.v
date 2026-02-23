// Constants Definition Module
// Centralized management of all magic numbers and thresholds

module constants

// Version Information
pub const version = '1.1.0'

// Timing Constraint Thresholds (assuming units are in ns unless otherwise specified)
pub const min_realistic_period_ns = 0.1    // 100ps - values below this are considered unrealistic
pub const max_realistic_period_ns = 1000.0 // 1000ns (1MHz) - values above this are considered unrealistic

// Delay Value Realism Check Thresholds
pub const max_realistic_delay_ns = 100.0   // 100ns - warning issued if exceeded

// Transition Time Realism Check Thresholds
pub const max_realistic_transition_ns = 10.0  // 10ns - warning issued if exceeded

// Clock Uncertainty Thresholds
pub const max_uncertainty_warning_ns = 10.0  // 10ns - warning issued if exceeded
pub const max_uncertainty_error_ns   = 5.0   // 5ns - stronger warning in strict mode if exceeded

// Error and Warning Limits
pub const default_max_errors    = 100   // Default maximum number of errors
pub const default_max_warnings  = 100   // Default maximum number of warnings
pub const max_substitution_depth = 10   // Maximum recursion depth for variable substitution

// Tokenizer Limits
pub const max_line_length = 10000  // Maximum characters per line
pub const max_nesting_depth = 50   // Maximum nesting depth (brackets, etc.)

// JSON Output Configuration
pub const json_indent = '  '  // JSON indentation (two spaces)

// Error Code Definitions
pub enum ErrorCode as u16 {
	ok                          = 0
	missing_required_arg        = 1001
	unknown_command             = 1002
	invalid_arg_value           = 1003
	invalid_arg_type            = 1004
	tcl_syntax_error            = 1005
	unmatched_brace             = 1006
	unmatched_bracket           = 1007
	unmatched_quote             = 1008
	empty_pin_list              = 1009
	invalid_separator           = 1010
	variable_undefined          = 1011
	file_not_found              = 1012
	file_read_error             = 1013
	
	// Cross-Command Consistency Check Errors (2000+ range)
	undefined_clock             = 2001
	undefined_port              = 2002
	undefined_pin               = 2003
	duplicate_clock             = 2004
	duplicate_constraint        = 2005
	self_referencing_clock      = 2006
}

// Get string description for error code
pub fn error_code_description(code ErrorCode) string {
	return match code {
		.ok { 'Success' }
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
		.file_not_found { 'File not found' }
		.file_read_error { 'File read error' }
		// Cross-command consistency check errors
		.undefined_clock { 'Reference to undefined clock' }
		.undefined_port { 'Reference to undefined port' }
		.undefined_pin { 'Reference to undefined pin' }
		.duplicate_clock { 'Duplicate clock definition' }
		.duplicate_constraint { 'Duplicate constraint' }
		.self_referencing_clock { 'Clock self-reference' }
	}
}

// Get English identifier for error code (used for JSON output)
pub fn error_code_identifier(code ErrorCode) string {
	return match code {
		.ok { 'ok' }
		.missing_required_arg { 'missing_required_arg' }
		.unknown_command { 'unknown_command' }
		.invalid_arg_value { 'invalid_arg_value' }
		.invalid_arg_type { 'invalid_arg_type' }
		.tcl_syntax_error { 'tcl_syntax_error' }
		.unmatched_brace { 'unmatched_brace' }
		.unmatched_bracket { 'unmatched_bracket' }
		.unmatched_quote { 'unmatched_quote' }
		.empty_pin_list { 'empty_pin_list' }
		.invalid_separator { 'invalid_separator' }
		.variable_undefined { 'variable_undefined' }
		.file_not_found { 'file_not_found' }
		.file_read_error { 'file_read_error' }
		// Cross-command consistency check errors
		.undefined_clock { 'undefined_clock' }
		.undefined_port { 'undefined_port' }
		.undefined_pin { 'undefined_pin' }
		.duplicate_clock { 'duplicate_clock' }
		.duplicate_constraint { 'duplicate_constraint' }
		.self_referencing_clock { 'self_referencing_clock' }
	}
}