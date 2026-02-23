// Parameter validation function module
// Implements strict mode parameter value validation

module validators

// Validation result enum
pub enum ValidationResult {
	ok             // Validation passed
	invalid_format // Invalid format
	out_of_range   // Out of range
	empty_value    // Empty value
}

// Check if it is a TCL expression (contains brackets)
fn is_tcl_expression(value string) bool {
	return value.contains('[') && value.contains(']')
}

// Validate positive number (> 0)
pub fn validate_positive_number(value string) ValidationResult {
	if value.len == 0 {
		return .empty_value
	}

	// TCL subcommand expression, skip validation
	if is_tcl_expression(value) {
		return .ok
	}

	// Try to parse as float
	num := value.f64()
	if num <= 0 {
		return .out_of_range
	}

	return .ok
}

// Validate non-negative number (>= 0)
pub fn validate_non_negative_number(value string) ValidationResult {
	if value.len == 0 {
		return .empty_value
	}

	num := value.f64()
	if num < 0 {
		return .out_of_range
	}

	return .ok
}

// Validate positive integer (> 0)
pub fn validate_positive_integer(value string) ValidationResult {
	if value.len == 0 {
		return .empty_value
	}

	// Check if it is an integer
	for ch in value {
		if !ch.is_digit() {
			return .invalid_format
		}
	}

	num := value.int()
	if num <= 0 {
		return .out_of_range
	}

	return .ok
}

// Validate non-negative integer (>= 0)
pub fn validate_non_negative_integer(value string) ValidationResult {
	if value.len == 0 {
		return .empty_value
	}

	for ch in value {
		if !ch.is_digit() {
			return .invalid_format
		}
	}

	return .ok
}

// Validate number (any real number)
pub fn validate_number(value string) ValidationResult {
	if value.len == 0 {
		return .empty_value
	}

	// Try to parse
	_ := value.f64()
	return .ok
}

// Validate percentage (0-100)
pub fn validate_percentage(value string) ValidationResult {
	if value.len == 0 {
		return .empty_value
	}

	// Remove trailing % symbol (if any)
	mut num_str := value
	if num_str.ends_with('%') {
		num_str = num_str[0..num_str.len - 1]
	}

	num := num_str.f64()
	if num < 0 || num > 100 {
		return .out_of_range
	}

	return .ok
}

// Validate hierarchy separator (must be one of specific characters)
pub fn validate_hierarchy_separator(value string) ValidationResult {
	if value.len == 0 {
		return .empty_value
	}

	if value.len != 1 {
		return .invalid_format
	}

	valid_separators := ['/', '@', '^', '#', '.', '|']
	for sep in valid_separators {
		if value == sep {
			return .ok
		}
	}
	return .out_of_range
}

// Validate time unit
pub fn validate_time_unit(value string) ValidationResult {
	if value.len == 0 {
		return .empty_value
	}

	// Remove quotes or braces (if any)
	mut val := value
	if val.starts_with('"') && val.ends_with('"') {
		val = val[1..val.len - 1]
	} else if val.starts_with('{') && val.ends_with('}') {
		val = val[1..val.len - 1]
	}

	// Supported suffixes: s, ms, us, ns, ps, fs
	// Sort by length descending, prioritize matching longer units
	valid_units := ['ms', 'us', 'ns', 'ps', 'fs', 's']

	for unit in valid_units {
		if val.ends_with(unit) {
			prefix := val[0..val.len - unit.len]
			// Prefix should be a number (optional)
			if prefix.len == 0 || is_valid_number_prefix(prefix) {
				return .ok
			}
			return .invalid_format
		}
	}

	// If no suffix, check if it is a pure number
	if is_valid_number(val) {
		return .ok
	}

	return .invalid_format
}

// Validate capacitance unit
pub fn validate_capacitance_unit(value string) ValidationResult {
	if value.len == 0 {
		return .empty_value
	}

	// Remove quotes or braces (if any)
	mut val := value
	if val.starts_with('"') && val.ends_with('"') {
		val = val[1..val.len - 1]
	} else if val.starts_with('{') && val.ends_with('}') {
		val = val[1..val.len - 1]
	}

	// Sort by length descending, prioritize matching longer units
	valid_units := ['mF', 'uF', 'nF', 'pF', 'fF', 'aF', 'F']

	for unit in valid_units {
		if val.ends_with(unit) || val.ends_with(unit.to_lower()) {
			prefix := val[0..val.len - unit.len]
			if prefix.len == 0 || is_valid_number_prefix(prefix) {
				return .ok
			}
			return .invalid_format
		}
	}

	if is_valid_number(val) {
		return .ok
	}

	return .invalid_format
}

// Validate resistance unit
pub fn validate_resistance_unit(value string) ValidationResult {
	if value.len == 0 {
		return .empty_value
	}

	// Remove quotes or braces (if any)
	mut val := value
	if val.starts_with('"') && val.ends_with('"') {
		val = val[1..val.len - 1]
	} else if val.starts_with('{') && val.ends_with('}') {
		val = val[1..val.len - 1]
	}

	// Convert to lowercase for matching
	val_lower := val.to_lower()

	// Sort by length descending, prioritize matching longer units
	valid_units := ['kohm', 'mohm', 'ohm']

	for unit in valid_units {
		if val_lower.ends_with(unit) {
			prefix := val_lower[0..val_lower.len - unit.len]
			if prefix.len == 0 || is_valid_number_prefix(prefix) {
				return .ok
			}
			return .invalid_format
		}
	}

	if is_valid_number(val) {
		return .ok
	}

	return .invalid_format
}

// Validate voltage unit
pub fn validate_voltage_unit(value string) ValidationResult {
	if value.len == 0 {
		return .empty_value
	}

	// Remove quotes or braces (if any)
	mut val := value
	if val.starts_with('"') && val.ends_with('"') {
		val = val[1..val.len - 1]
	} else if val.starts_with('{') && val.ends_with('}') {
		val = val[1..val.len - 1]
	}

	// Sort by length descending, prioritize matching longer units
	valid_units := ['mV', 'uV', 'nV', 'kV', 'MV', 'V']

	for unit in valid_units {
		if val.ends_with(unit) {
			prefix := val[0..val.len - unit.len]
			if prefix.len == 0 || is_valid_number_prefix(prefix) {
				return .ok
			}
			return .invalid_format
		}
	}

	if is_valid_number(val) {
		return .ok
	}

	return .invalid_format
}

// Validate current unit
pub fn validate_current_unit(value string) ValidationResult {
	if value.len == 0 {
		return .empty_value
	}

	// Remove quotes or braces (if any)
	mut val := value
	if val.starts_with('"') && val.ends_with('"') {
		val = val[1..val.len - 1]
	} else if val.starts_with('{') && val.ends_with('}') {
		val = val[1..val.len - 1]
	}

	// Sort by length descending, prioritize matching longer units
	valid_units := ['mA', 'uA', 'nA', 'pA', 'fA', 'kA', 'A']

	for unit in valid_units {
		if val.ends_with(unit) {
			prefix := val[0..val.len - unit.len]
			if prefix.len == 0 || is_valid_number_prefix(prefix) {
				return .ok
			}
			return .invalid_format
		}
	}

	if is_valid_number(val) {
		return .ok
	}

	return .invalid_format
}

// Validate power unit
pub fn validate_power_unit(value string) ValidationResult {
	if value.len == 0 {
		return .empty_value
	}

	// Remove quotes or braces (if any)
	mut val := value
	if val.starts_with('"') && val.ends_with('"') {
		val = val[1..val.len - 1]
	} else if val.starts_with('{') && val.ends_with('}') {
		val = val[1..val.len - 1]
	}

	// Sort by length descending, prioritize matching longer units
	valid_units := ['mW', 'uW', 'nW', 'pW', 'fW', 'kW', 'MW', 'W']

	for unit in valid_units {
		if val.ends_with(unit) {
			prefix := val[0..val.len - unit.len]
			if prefix.len == 0 || is_valid_number_prefix(prefix) {
				return .ok
			}
			return .invalid_format
		}
	}

	if is_valid_number(val) {
		return .ok
	}

	return .invalid_format
}

// Validate distance unit
pub fn validate_distance_unit(value string) ValidationResult {
	if value.len == 0 {
		return .empty_value
	}

	// Remove quotes or braces (if any)
	mut val := value
	if val.starts_with('"') && val.ends_with('"') {
		val = val[1..val.len - 1]
	} else if val.starts_with('{') && val.ends_with('}') {
		val = val[1..val.len - 1]
	}

	// Sort by length descending, prioritize matching longer units
	valid_units := ['mm', 'um', 'nm', 'pm', 'km', 'm']

	for unit in valid_units {
		if val.ends_with(unit) {
			prefix := val[0..val.len - unit.len]
			if prefix.len == 0 || is_valid_number_prefix(prefix) {
				return .ok
			}
			return .invalid_format
		}
	}

	if is_valid_number(val) {
		return .ok
	}

	return .invalid_format
}

// Validate waveform list (two numeric values)
pub fn validate_waveform_list(value string) ValidationResult {
	if value.len == 0 {
		return .empty_value
	}

	// Remove braces (if any)
	mut list_str := value
	if list_str.starts_with('{') && list_str.ends_with('}') {
		list_str = list_str[1..list_str.len - 1]
	}

	// Split into multiple values
	parts := list_str.split(' ')
	if parts.len != 2 {
		return .invalid_format
	}

	for part in parts {
		if part.len == 0 {
			return .empty_value
		}
		if !is_valid_number(part) {
			return .invalid_format
		}
	}

	return .ok
}

// Validate edge list (three integers)
pub fn validate_edge_list(value string) ValidationResult {
	if value.len == 0 {
		return .empty_value
	}

	mut list_str := value
	if list_str.starts_with('{') && list_str.ends_with('}') {
		list_str = list_str[1..list_str.len - 1]
	}

	parts := list_str.split(' ')
	if parts.len != 3 {
		return .invalid_format
	}

	for part in parts {
		if part.len == 0 {
			return .empty_value
		}
		for ch in part {
			if !ch.is_digit() {
				return .invalid_format
			}
		}
	}

	return .ok
}

// Validate number list
pub fn validate_number_list(value string) ValidationResult {
	if value.len == 0 {
		return .empty_value
	}

	mut list_str := value
	if list_str.starts_with('{') && list_str.ends_with('}') {
		list_str = list_str[1..list_str.len - 1]
	}

	parts := list_str.split(' ')
	if parts.len == 0 {
		return .empty_value
	}

	for part in parts {
		if part.len > 0 && !is_valid_number(part) {
			return .invalid_format
		}
	}

	return .ok
}

// Helper function: Check if it is a valid number
fn is_valid_number(s string) bool {
	if s.len == 0 {
		return false
	}

	mut has_digit := false
	mut has_dot := false
	mut has_exp := false
	mut pos := 0

	// Handle sign
	if s[0] == `-` || s[0] == `+` {
		pos = 1
	}

	for pos < s.len {
		ch := s[pos]
		if ch.is_digit() {
			has_digit = true
			pos++
		} else if ch == `.` && !has_dot && !has_exp {
			has_dot = true
			pos++
		} else if (ch == `e` || ch == `E`) && !has_exp && has_digit {
			has_exp = true
			pos++
			// Handle exponent sign
			if pos < s.len && (s[pos] == `-` || s[pos] == `+`) {
				pos++
			}
		} else {
			return false
		}
	}

	return has_digit
}

// Helper function: Check number prefix (used for unit validation)
fn is_valid_number_prefix(s string) bool {
	if s.len == 0 {
		return true // Empty prefix is valid (means 1)
	}

	return is_valid_number(s)
}

// Validate by validator name
pub fn validate_by_name(value string, validator_name string) ValidationResult {
	if validator_name == 'positive_number' {
		return validate_positive_number(value)
	}
	if validator_name == 'non_negative_number' {
		return validate_non_negative_number(value)
	}
	if validator_name == 'positive_integer' {
		return validate_positive_integer(value)
	}
	if validator_name == 'non_negative_integer' {
		return validate_non_negative_integer(value)
	}
	if validator_name == 'number' {
		return validate_number(value)
	}
	if validator_name == 'percentage' {
		return validate_percentage(value)
	}
	if validator_name == 'hierarchy_separator' {
		return validate_hierarchy_separator(value)
	}
	if validator_name == 'time_unit' {
		return validate_time_unit(value)
	}
	if validator_name == 'cap_unit' {
		return validate_capacitance_unit(value)
	}
	if validator_name == 'res_unit' {
		return validate_resistance_unit(value)
	}
	if validator_name == 'volt_unit' {
		return validate_voltage_unit(value)
	}
	if validator_name == 'current_unit' {
		return validate_current_unit(value)
	}
	if validator_name == 'power_unit' {
		return validate_power_unit(value)
	}
	if validator_name == 'dist_unit' {
		return validate_distance_unit(value)
	}
	if validator_name == 'waveform_list' {
		return validate_waveform_list(value)
	}
	if validator_name == 'edge_list' {
		return validate_edge_list(value)
	}
	if validator_name == 'number_list' {
		return validate_number_list(value)
	}
	// New validators
	if validator_name == 'delay_range' {
		return validate_delay_range(value)
	}
	if validator_name == 'clock_period' {
		return validate_clock_period(value)
	}
	if validator_name == 'transition_time' {
		return validate_transition_time(value)
	}
	if validator_name == 'glitch_threshold' {
		return validate_glitch_threshold(value)
	}
	if validator_name == 'capacitance_range' {
		return validate_capacitance_range(value)
	}
	if validator_name == 'path_margin' {
		return validate_path_margin(value)
	}
	if validator_name == 'clock_uncertainty' {
		return validate_clock_uncertainty(value)
	}
	if validator_name == 'jitter' {
		return validate_jitter(value)
	}
	return .ok // Unknown validator, default pass
}

// Get validation error description
pub fn get_validation_error_desc(result ValidationResult, validator_name string, value string) string {
	if result == .ok {
		return ''
	}
	if result == .invalid_format {
		return match validator_name {
			'clock_period' { 'Invalid clock period format, should be a number (units: s, ms, us, ns, ps, fs)' }
			'delay_range' { 'Invalid delay value format, should be a number' }
			'transition_time' { 'Invalid transition time format, should be a number' }
			'jitter' { 'Invalid jitter value format, should be a number' }
			'path_margin' { 'Invalid path margin format, should be a number' }
			else { 'Invalid parameter format' }
		}
	}
	if result == .out_of_range {
		return match validator_name {
			'clock_period' { 'Clock period out of valid range (1ps ~ 10ms)' }
			'delay_range' { 'Delay value out of valid range (0 ~ 1ms)' }
			'transition_time' { 'Transition time out of valid range (0 ~ 1ns)' }
			'clock_uncertainty' { 'Clock uncertainty out of valid range (0 ~ 10ns)' }
			'jitter' { 'Jitter value out of valid range (0 ~ 1ns)' }
			'path_margin' { 'Path margin out of valid range (-10ns ~ 10ns)' }
			'capacitance_range' { 'Capacitance value out of valid range (0 ~ 1nF)' }
			'glitch_threshold' { 'Glitch threshold out of valid range (0 ~ 1V)' }
			else { 'Parameter value out of valid range' }
		}
	}
	if result == .empty_value {
		return 'Parameter value cannot be empty'
	}
	return ''
}

// Check if number is negative (used for warning)
pub fn is_negative_number(value string) bool {
	if value.len == 0 {
		return false
	}

	num := value.f64()
	return num < 0
}

// Check if number is zero (used for warning)
pub fn is_zero(value string) bool {
	if value.len == 0 {
		return false
	}

	num := value.f64()
	return num == 0
}

// Validate delay value range (reasonable delay range 0-1ms)
// Note: Numbers without units are assumed to be ns (nanoseconds)
pub fn validate_delay_range(value string) ValidationResult {
	if value.len == 0 {
		return .empty_value
	}

	// Skip validation for TCL expressions
	if value.contains('[') && value.contains(']') {
		return .ok
	}

	// Check if there is a unit suffix
	mut has_unit := false
	for ch in value {
		if ch.is_letter() {
			has_unit = true
			break
		}
	}

	mut num := value.f64()
	// If no unit, assume ns (nanoseconds), convert to seconds
	if !has_unit {
		num = num * 1e-9
	}

	// Delay range: 0 to 1e-3 seconds (1ms)
	if num < 0 || num > 1e-3 {
		return .out_of_range
	}

	return .ok
}

// Validate clock period range (1ps to 10ms)
// Note: Numbers without units are assumed to be ns (nanoseconds)
pub fn validate_clock_period(value string) ValidationResult {
	if value.len == 0 {
		return .empty_value
	}

	// Skip validation for TCL expressions
	if value.contains('[') && value.contains(']') {
		return .ok
	}

	// Check if there is a unit suffix
	mut has_unit := false
	for ch in value {
		if ch.is_letter() {
			has_unit = true
			break
		}
	}

	mut num := value.f64()
	// If no unit, assume ns (nanoseconds), convert to seconds
	if !has_unit {
		num = num * 1e-9
	}

	// Clock period range: 1ps (1e-12) to 10ms (1e-2)
	if num < 1e-12 || num > 1e-2 {
		return .out_of_range
	}

	return .ok
}

// Validate transition time range (0-1ns)
// Note: Numbers without units are assumed to be ns (nanoseconds)
pub fn validate_transition_time(value string) ValidationResult {
	if value.len == 0 {
		return .empty_value
	}

	if value.contains('[') && value.contains(']') {
		return .ok
	}

	// Check if there is a unit suffix
	mut has_unit := false
	for ch in value {
		if ch.is_letter() {
			has_unit = true
			break
		}
	}

	mut num := value.f64()
	// If no unit, assume ns (nanoseconds), convert to seconds
	if !has_unit {
		num = num * 1e-9
	}

	// Transition time: 0 to 1e-9 seconds (1ns)
	if num < 0 || num > 1e-9 {
		return .out_of_range
	}

	return .ok
}

// Validate glitch threshold (0-1V)
pub fn validate_glitch_threshold(value string) ValidationResult {
	if value.len == 0 {
		return .empty_value
	}

	if value.contains('[') && value.contains(']') {
		return .ok
	}

	num := value.f64()
	// Glitch threshold: 0 to 1.0V
	if num < 0 || num > 1.0 {
		return .out_of_range
	}

	return .ok
}

// Validate capacitance range (0-1nF)
pub fn validate_capacitance_range(value string) ValidationResult {
	if value.len == 0 {
		return .empty_value
	}

	if value.contains('[') && value.contains(']') {
		return .ok
	}

	num := value.f64()
	// Capacitance range: 0 to 1e-9 F (1nF)
	if num < 0 || num > 1e-9 {
		return .out_of_range
	}

	return .ok
}

// Validate path margin range (-10ns to 10ns)
// Note: Numbers without units are assumed to be ns (nanoseconds)
pub fn validate_path_margin(value string) ValidationResult {
	if value.len == 0 {
		return .empty_value
	}

	if value.contains('[') && value.contains(']') {
		return .ok
	}

	// Check if there is a unit suffix
	mut has_unit := false
	for ch in value {
		if ch.is_letter() {
			has_unit = true
			break
		}
	}

	mut num := value.f64()
	// If no unit, assume ns (nanoseconds), convert to seconds
	if !has_unit {
		num = num * 1e-9
	}

	// Path margin: -10ns to 10ns (±1e-8)
	if num < -1e-8 || num > 1e-8 {
		return .out_of_range
	}

	return .ok
}

// Validate clock uncertainty range (0-10ns)
// Note: Numbers without units are assumed to be ns (nanoseconds)
pub fn validate_clock_uncertainty(value string) ValidationResult {
	if value.len == 0 {
		return .empty_value
	}

	if value.contains('[') && value.contains(']') {
		return .ok
	}

	// Check if there is a unit suffix
	mut has_unit := false
	for ch in value {
		if ch.is_letter() {
			has_unit = true
			break
		}
	}

	mut num := value.f64()
	// If no unit, assume ns (nanoseconds), convert to seconds
	if !has_unit {
		num = num * 1e-9
	}

	// Uncertainty: 0 to 10ns (1e-8)
	if num < 0 || num > 1e-8 {
		return .out_of_range
	}

	return .ok
}

// Validate jitter range (0-1ns)
// Note: Numbers without units are assumed to be ns (nanoseconds)
pub fn validate_jitter(value string) ValidationResult {
	if value.len == 0 {
		return .empty_value
	}

	if value.contains('[') && value.contains(']') {
		return .ok
	}

	// Check if there is a unit suffix
	mut has_unit := false
	for ch in value {
		if ch.is_letter() {
			has_unit = true
			break
		}
	}

	mut num := value.f64()
	// If no unit, assume ns (nanoseconds), convert to seconds
	if !has_unit {
		num = num * 1e-9
	}

	// Jitter: 0 to 1ns (1e-9)
	if num < 0 || num > 1e-9 {
		return .out_of_range
	}

	return .ok
}

// Get suggestion info for validator (includes example constraints)
pub fn get_suggestion_for_validator(validator_name string, arg_name string) string {
	return match validator_name {
		'positive_number' { 'Example: ' + arg_name + ' 10.0' }
		'non_negative_number' { 'Example: ' + arg_name + ' 0.0' }
		'positive_integer' { 'Example: ' + arg_name + ' 2' }
		'percentage' { 'Example: ' + arg_name + ' 50' }
		'hierarchy_separator' { 'Example: set_hierarchy_separator /' }
		'time_unit' { 'Example: -time 1ns' }
		'cap_unit' { 'Example: -capacitance 1.0pF' }
		'res_unit' { 'Example: -resistance 1.0kOhm' }
		'volt_unit' { 'Example: -voltage 0.8V' }
		'current_unit' { 'Example: -current 1.0mA' }
		'power_unit' { 'Example: -power 1.0mW' }
		'dist_unit' { 'Example: -distance 1.0um' }
		'waveform_list' { 'Example: -waveform {0 5.0}' }
		'edge_list' { 'Example: -edges {1 2 3}' }
		'number_list' { 'Example: {1.0 2.0 3.0}' }
		// New validator suggestions
		'clock_period' { 'Example: ' + arg_name + ' 10.0 (range: 1ps ~ 10ms)' }
		'delay_range' { 'Example: ' + arg_name + ' 2.5 (range: 0 ~ 1ms)' }
		'transition_time' { 'Example: ' + arg_name + ' 0.1 (range: 0 ~ 1ns)' }
		'clock_uncertainty' { 'Example: ' + arg_name + ' 0.2 (range: 0 ~ 10ns)' }
		'jitter' { 'Example: ' + arg_name + ' 0.05 (range: 0 ~ 1ns)' }
		'path_margin' { 'Example: ' + arg_name + ' 0.5 (range: -10ns ~ 10ns)' }
		'capacitance_range' { 'Example: ' + arg_name + ' 0.05 (range: 0 ~ 1nF)' }
		else { 'Check parameter value format' }
	}
}