// TCL variable storage and substitution module
// Supports set command and variable substitution

module variables

// Variable storage structure
pub struct VariableStore {
pub mut:
	vars map[string]string // variable name -> variable value
}

// Create new variable store
pub fn new_variable_store() VariableStore {
	return VariableStore{
		vars: map[string]string{}
	}
}

// Set variable
pub fn (mut v VariableStore) set(name string, value string) {
	v.vars[name] = value
}

// Get variable
pub fn (v &VariableStore) get(name string) ?string {
	if name in v.vars {
		return v.vars[name]
	}
	return none
}

// Check if variable exists
pub fn (v &VariableStore) exists(name string) bool {
	return name in v.vars
}

// Delete variable
pub fn (mut v VariableStore) unset(name string) {
	v.vars.delete(name)
}

// Substitute variable references in a string (recursively substitutes nested variables)
// Supported formats: $var, ${var}
// Returns the substituted string and list of undefined variables
pub fn (v &VariableStore) substitute(input string) (string, []string) {
	mut result := input
	mut undefined_vars := []string{}
	mut max_iterations := 10 // Prevent infinite recursion

	// Recursively substitute until no more variables to replace
	for max_iterations > 0 {
		max_iterations--

		mut substituted := false
		mut new_result := result

		// First process ${var} format
		mut pos := 0
		for pos < new_result.len {
			dollar_idx := new_result.index_after('\$', pos) or { break }

			// Check if escaped
			if dollar_idx > 0 && new_result[dollar_idx - 1] == 92 { // 92 is ASCII for backslash
				pos = dollar_idx + 1
				continue
			}

			// Check if ${var} format
			if dollar_idx + 1 < new_result.len && new_result[dollar_idx + 1] == `{` {
				// Find matching }
				mut brace_count := 1
				mut end_idx := dollar_idx + 2
				for end_idx < new_result.len && brace_count > 0 {
					if new_result[end_idx] == `{` {
						brace_count++
					} else if new_result[end_idx] == `}` {
						brace_count--
					}
					if brace_count > 0 {
						end_idx++
					} else {
						break
					}
				}

				if brace_count == 0 {
					// Found matching }
					var_name := new_result[dollar_idx + 2..end_idx]

					if value := v.get(var_name) {
						new_result = new_result[0..dollar_idx] + value + new_result[end_idx + 1..]
						substituted = true
						pos = dollar_idx + value.len
					} else {
						// Variable not defined
						if !undefined_vars.contains(var_name) {
							undefined_vars << var_name
						}
						// Keep as-is, but skip this variable to avoid duplicate detection
						pos = end_idx + 1
					}
				} else {
					// Unmatched {, skip
					pos = dollar_idx + 1
				}
			} else {
				// Process $var format
				mut end_idx := dollar_idx + 1
				for end_idx < new_result.len {
					ch := new_result[end_idx]
					if ch.is_alnum() || ch == 95 { // 95 is ASCII for underscore
						end_idx++
					} else {
						break
					}
				}

				if end_idx == dollar_idx + 1 {
					// No variable name after, skip
					pos = dollar_idx + 1
					continue
				}

				var_name := new_result[dollar_idx + 1..end_idx]

				if value := v.get(var_name) {
					new_result = new_result[0..dollar_idx] + value + new_result[end_idx..]
					substituted = true
					pos = dollar_idx + value.len
				} else {
					// Variable not defined
					if !undefined_vars.contains(var_name) {
						undefined_vars << var_name
					}
					// Keep as-is, skip this variable to avoid duplicate detection
					pos = end_idx
				}
			}
		}

		result = new_result
		if !substituted {
			break // No more substitutions, exit loop
		}
	}

	return result, undefined_vars
}

// Process set command, extract variable name and value
// set var_name var_value
pub fn (mut v VariableStore) process_set_command(args []string) {
	if args.len < 1 {
		return
	}

	var_name := args[0]

	if args.len >= 2 {
		// set var_name var_value
		// Concatenate all remaining arguments as value
		mut value := ''
		for i := 1; i < args.len; i++ {
			if i > 1 {
				value += ' '
			}
			value += args[i]
		}
		v.set(var_name, value)
	} else {
		// set var_name (no value, set to empty string)
		v.set(var_name, '')
	}
}

// Get all variable names
pub fn (v &VariableStore) get_all_names() []string {
	mut names := []string{}
	for name, _ in v.vars {
		names << name
	}
	return names
}

// Clear all variables
pub fn (mut v VariableStore) clear() {
	v.vars = map[string]string{}
}