// SDC Command Definition Module
// Defines all supported SDC commands and their parameter specifications

module commands

// Argument type enumeration
pub enum ArgType {
	flag       // Flag argument, e.g., -add, -rise
	key_value  // Key-value pair argument, e.g., -period 10.0
	positional // Positional argument, e.g., filename, pin list
}

// Argument definition structure
pub struct CmdArg {
pub:
	name         string  // Argument name
	arg_type     ArgType // Argument type
	required     bool    // Whether required
	validator    string  // Validator name (for strict mode)
	is_flag_only bool    // Whether it's a pure flag (no value needed)
	example      string  // Example value (for error messages)
}

// SDC Command definition structure
pub struct SdcCommand {
pub:
	name           string   // Command name
	args           []CmdArg // Argument list
	min_positional int      // Minimum positional arguments count
	max_positional int      // Maximum positional arguments count (-1 means unlimited)
	description    string   // Command description
	example        string   // Command example (for error messages)
}

// Command registry
pub struct CommandRegistry {
pub mut:
	commands map[string]SdcCommand
}

// Create new command registry and initialize all commands
pub fn new_command_registry() CommandRegistry {
	mut registry := CommandRegistry{
		commands: map[string]SdcCommand{}
	}
	registry.init_commands()
	return registry
}

// Get command
pub fn (r &CommandRegistry) get_command(name string) ?SdcCommand {
	if name in r.commands {
		return r.commands[name]
	}
	return none
}

// Check if command exists
pub fn (r &CommandRegistry) has_command(name string) bool {
	return name in r.commands
}

// Get command example
pub fn (r &CommandRegistry) get_example(name string) string {
	if cmd := r.commands[name] {
		return cmd.example
	}
	return ''
}

// Determine if a flag for the specified command is a pure flag (no value needed)
// If command is unknown or parameter is unknown, assume pure flag by default
pub fn (r &CommandRegistry) is_flag_without_value(cmd_name string, flag_name string) bool {
	cmd := r.commands[cmd_name] or { return true }
	for arg in cmd.args {
		if arg.name == flag_name {
			return arg.is_flag_only
		}
	}
	// Unknown flag, infer based on naming convention
	// Common pure flags: -max, -min, -rise, -fall, -setup, -hold, etc.
	known_flag_only := ['-max', '-min', '-rise', '-fall', '-setup', '-hold', '-end', '-start',
		'-clock_fall', '-clock_rise', '-invert', '-combinational', '-physically_exclusive',
		'-logically_exclusive', '-asynchronous', '-allow_paths', '-source_latency_included',
		'-network_latency_included', '-no_propagation', '-map_hpins', '-gzip', '-no_timestamp',
		'-echo', '-compatible', '-quiet', '-regexp', '-nocase', '-source', '-early', '-late',
		'-low', '-high', '-probe', '-ignore_clock_latency', '-reset_path', '-cell_delay',
		'-cell_check', '-net_delay', '-add', '-clock_path', '-data_path', '-pin_load',
		'-wire_load', '-dont_scale', '-no_design_rule', '-cells', '-data_pins', '-clock_pins',
		'-slave_clock_pins', '-async_pins', '-output_pins', '-stop_propagation', '-positive',
		'-negative', '-add_delay', '-no_clocks']
	return flag_name in known_flag_only
}

// Get example value for an argument
pub fn (r &CommandRegistry) get_arg_example(cmd_name string, arg_name string) string {
	cmd := r.commands[cmd_name] or { return '' }
	for arg in cmd.args {
		if arg.name == arg_name {
			return arg.example
		}
	}
	return ''
}

// Initialize all SDC commands
fn (mut r CommandRegistry) init_commands() {
	// ========== Clock Commands ==========

	// create_clock
	// OpenSTA: check_argc_eq0or1 - pins argument is optional
	r.commands['create_clock'] = SdcCommand{
		name:           'create_clock'
		args:           [
			CmdArg{
				name:         '-name'
				arg_type:     .key_value
				required:     false
				validator:    ''
				is_flag_only: false
				example:      'clk'
			},
			CmdArg{
				name:         '-period'
				arg_type:     .key_value
				required:     true
				validator:    'clock_period'
				is_flag_only: false
				example:      '10.0'
			},
			CmdArg{
				name:         '-waveform'
				arg_type:     .key_value
				required:     false
				validator:    'waveform_list'
				is_flag_only: false
				example:      '{0 5.0}'
			},
			CmdArg{
				name:         '-add'
				arg_type:     .flag
				required:     false
				validator:    ''
				is_flag_only: true
				example:      ''
			},
		]
		min_positional: 0
		max_positional: 1
		description:    'Create clock'
		example:        'create_clock -period 10.0 -name clk [get_ports clk]'
	}

	// create_generated_clock
	// OpenSTA: check_argc_eq1 - requires one port_pin_list argument
	r.commands['create_generated_clock'] = SdcCommand{
		name:           'create_generated_clock'
		args:           [
			CmdArg{
				name:         '-name'
				arg_type:     .key_value
				required:     false
				validator:    ''
				is_flag_only: false
				example:      'clk_div2'
			},
			CmdArg{
				name:         '-source'
				arg_type:     .key_value
				required:     true
				validator:    ''
				is_flag_only: false
				example:      '[get_pins clk]'
			},
			CmdArg{
				name:         '-master_clock'
				arg_type:     .key_value
				required:     false
				validator:    ''
				is_flag_only: false
				example:      'clk'
			},
			CmdArg{
				name:         '-divide_by'
				arg_type:     .key_value
				required:     false
				validator:    'positive_integer'
				is_flag_only: false
				example:      '2'
			},
			CmdArg{
				name:         '-multiply_by'
				arg_type:     .key_value
				required:     false
				validator:    'positive_integer'
				is_flag_only: false
				example:      '2'
			},
			CmdArg{
				name:         '-duty_cycle'
				arg_type:     .key_value
				required:     false
				validator:    'percentage'
				is_flag_only: false
				example:      '50'
			},
			CmdArg{
				name:         '-invert'
				arg_type:     .flag
				required:     false
				validator:    ''
				is_flag_only: true
				example:      ''
			},
			CmdArg{
				name:         '-combinational'
				arg_type:     .flag
				required:     false
				validator:    ''
				is_flag_only: true
				example:      ''
			},
			CmdArg{
				name:         '-edges'
				arg_type:     .key_value
				required:     false
				validator:    'edge_list'
				is_flag_only: false
				example:      '{1 3 5}'
			},
			CmdArg{
				name:         '-edge_shift'
				arg_type:     .key_value
				required:     false
				validator:    'number_list'
				is_flag_only: false
				example:      '{0.0 0.5}'
			},
			CmdArg{
				name:         '-add'
				arg_type:     .flag
				required:     false
				validator:    ''
				is_flag_only: true
				example:      ''
			},
		]
		min_positional: 1
		max_positional: 1
		description:    'Create generated clock'
		example:        'create_generated_clock -source clk -divide_by 2 gen_clk'
	}

	// delete_clock
	r.commands['delete_clock'] = SdcCommand{
		name:           'delete_clock'
		args:           [
			CmdArg{
				name:      '-all'
				arg_type:  .flag
				required:  false
				validator: ''
			},
		]
		min_positional: 0
		max_positional: -1
		description:    'Delete clock'
	}

	// delete_generated_clock
	r.commands['delete_generated_clock'] = SdcCommand{
		name:           'delete_generated_clock'
		args:           [
			CmdArg{
				name:      '-all'
				arg_type:  .flag
				required:  false
				validator: ''
			},
		]
		min_positional: 0
		max_positional: -1
		description:    'Delete generated clock'
	}

	// set_clock_latency
	r.commands['set_clock_latency'] = SdcCommand{
		name:           'set_clock_latency'
		args:           [
			CmdArg{
				name:      '-source'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-early'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-late'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-rise'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-fall'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-min'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-max'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-clock'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
		]
		min_positional: 2
		max_positional: 2
		description:    'Set clock latency'
	}

	// set_clock_uncertainty
	r.commands['set_clock_uncertainty'] = SdcCommand{
		name:           'set_clock_uncertainty'
		args:           [
			CmdArg{
				name:      '-setup'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-hold'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-rise'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-fall'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-from'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-to'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
		]
		min_positional: 1
		max_positional: 2
		description:    'Set clock uncertainty'
	}

	// set_clock_transition
	r.commands['set_clock_transition'] = SdcCommand{
		name:           'set_clock_transition'
		args:           [
			CmdArg{
				name:      '-rise'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-fall'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-min'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-max'
				arg_type:  .flag
				required:  false
				validator: ''
			},
		]
		min_positional: 2
		max_positional: 2
		description:    'Set clock transition'
	}

	// set_clock_groups
	r.commands['set_clock_groups'] = SdcCommand{
		name:           'set_clock_groups'
		args:           [
			CmdArg{
				name:      '-logically_exclusive'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-physically_exclusive'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-asynchronous'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-allow_paths'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-name'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-group'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
		]
		min_positional: 0
		max_positional: 0
		description:    'Set clock groups'
	}

	// set_clock_sense
	r.commands['set_clock_sense'] = SdcCommand{
		name:           'set_clock_sense'
		args:           [
			CmdArg{
				name:      '-positive'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-negative'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-stop_propagation'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-pulse'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-clock'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
		]
		min_positional: 1
		max_positional: -1
		description:    'Set clock sense'
	}

	// set_clock_gating_check
	r.commands['set_clock_gating_check'] = SdcCommand{
		name:           'set_clock_gating_check'
		args:           [
			CmdArg{
				name:      '-setup'
				arg_type:  .key_value
				required:  false
				validator: 'number'
			},
			CmdArg{
				name:      '-hold'
				arg_type:  .key_value
				required:  false
				validator: 'number'
			},
			CmdArg{
				name:      '-rise'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-fall'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-high'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-low'
				arg_type:  .flag
				required:  false
				validator: ''
			},
		]
		min_positional: 0
		max_positional: -1
		description:    'Set clock gating check'
	}

	// ========== I/O Constraint Commands ==========

	// set_input_delay
	r.commands['set_input_delay'] = SdcCommand{
		name:           'set_input_delay'
		args:           [
			CmdArg{
				name:      '-clock'
				arg_type:  .key_value
				required:  true
				validator: ''
			},
			CmdArg{
				name:      '-clock_fall'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-rise'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-fall'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-max'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-min'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-add_delay'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-source_latency_included'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-network_latency_included'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-reference_pin'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
		]
		min_positional: 2
		max_positional: 2
		description:    'Set input delay'
	}

	// set_output_delay
	r.commands['set_output_delay'] = SdcCommand{
		name:           'set_output_delay'
		args:           [
			CmdArg{
				name:      '-clock'
				arg_type:  .key_value
				required:  true
				validator: ''
			},
			CmdArg{
				name:      '-clock_fall'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-rise'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-fall'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-max'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-min'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-add_delay'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-source_latency_included'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-network_latency_included'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-reference_pin'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
		]
		min_positional: 2
		max_positional: 2
		description:    'Set output delay'
	}

	// ========== Timing Exception Commands ==========

	// set_false_path
	r.commands['set_false_path'] = SdcCommand{
		name:           'set_false_path'
		args:           [
			CmdArg{
				name:      '-setup'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-hold'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-rise'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-fall'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-from'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-to'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-through'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
		]
		min_positional: 0
		max_positional: 0
		description:    'Set false path'
	}

	// set_multicycle_path
	r.commands['set_multicycle_path'] = SdcCommand{
		name:           'set_multicycle_path'
		args:           [
			CmdArg{
				name:      '-setup'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-hold'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-rise'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-fall'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-start'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-end'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-from'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-to'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-through'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
		]
		min_positional: 1
		max_positional: 1
		description:    'Set multicycle path'
	}

	// set_max_delay
	r.commands['set_max_delay'] = SdcCommand{
		name:           'set_max_delay'
		args:           [
			CmdArg{
				name:      '-rise'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-fall'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-from'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-to'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-through'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-ignore_clock_latency'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-comment'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
		]
		min_positional: 1
		max_positional: 1
		description:    'Set max delay'
	}

	// set_min_delay
	r.commands['set_min_delay'] = SdcCommand{
		name:           'set_min_delay'
		args:           [
			CmdArg{
				name:      '-rise'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-fall'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-from'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-to'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-through'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-ignore_clock_latency'
				arg_type:  .flag
				required:  false
				validator: ''
			},
		]
		min_positional: 1
		max_positional: 1
		description:    'Set min delay'
	}

	// ========== Environment Setup Commands ==========

	// set_units
	r.commands['set_units'] = SdcCommand{
		name:           'set_units'
		args:           [
			CmdArg{
				name:      '-time'
				arg_type:  .key_value
				required:  false
				validator: 'time_unit'
			},
			CmdArg{
				name:      '-capacitance'
				arg_type:  .key_value
				required:  false
				validator: 'cap_unit'
			},
			CmdArg{
				name:      '-resistance'
				arg_type:  .key_value
				required:  false
				validator: 'res_unit'
			},
			CmdArg{
				name:      '-voltage'
				arg_type:  .key_value
				required:  false
				validator: 'volt_unit'
			},
			CmdArg{
				name:      '-current'
				arg_type:  .key_value
				required:  false
				validator: 'current_unit'
			},
			CmdArg{
				name:      '-power'
				arg_type:  .key_value
				required:  false
				validator: 'power_unit'
			},
			CmdArg{
				name:      '-distance'
				arg_type:  .key_value
				required:  false
				validator: 'dist_unit'
			},
		]
		min_positional: 0
		max_positional: 0
		description:    'Set units'
	}

	// set_hierarchy_separator
	r.commands['set_hierarchy_separator'] = SdcCommand{
		name:           'set_hierarchy_separator'
		args:           []
		min_positional: 1
		max_positional: 1
		description:    'Set hierarchy separator'
	}

	// set_operating_conditions
	r.commands['set_operating_conditions'] = SdcCommand{
		name:           'set_operating_conditions'
		args:           [
			CmdArg{
				name:      '-library'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-analysis_type'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-max'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-min'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-max_library'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-min_library'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
		]
		min_positional: 1
		max_positional: 1
		description:    'Set operating conditions'
	}

	// set_wire_load_mode
	r.commands['set_wire_load_mode'] = SdcCommand{
		name:           'set_wire_load_mode'
		args:           []
		min_positional: 1
		max_positional: 1
		description:    'Set wire load mode'
	}

	// set_wire_load_model
	r.commands['set_wire_load_model'] = SdcCommand{
		name:           'set_wire_load_model'
		args:           [
			CmdArg{
				name:      '-name'
				arg_type:  .key_value
				required:  true
				validator: ''
			},
			CmdArg{
				name:      '-library'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
		]
		min_positional: 0
		max_positional: -1
		description:    'Set wire load model'
	}

	// ========== Design Rule Commands ==========

	// set_max_transition
	r.commands['set_max_transition'] = SdcCommand{
		name:           'set_max_transition'
		args:           [
			CmdArg{
				name:      '-rise'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-fall'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-clock_path'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-data_path'
				arg_type:  .flag
				required:  false
				validator: ''
			},
		]
		min_positional: 1
		max_positional: -1
		description:    'Set max transition'
	}

	// set_max_capacitance
	r.commands['set_max_capacitance'] = SdcCommand{
		name:           'set_max_capacitance'
		args:           []
		min_positional: 2
		max_positional: 2
		description:    'Set max capacitance'
	}

	// set_max_fanout
	r.commands['set_max_fanout'] = SdcCommand{
		name:           'set_max_fanout'
		args:           []
		min_positional: 2
		max_positional: 2
		description:    'Set max fanout'
	}

	// set_min_capacitance
	r.commands['set_min_capacitance'] = SdcCommand{
		name:           'set_min_capacitance'
		args:           []
		min_positional: 2
		max_positional: 2
		description:    'Set min capacitance'
	}

	// set_min_pulse_width
	r.commands['set_min_pulse_width'] = SdcCommand{
		name:           'set_min_pulse_width'
		args:           [
			CmdArg{
				name:      '-low'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-high'
				arg_type:  .flag
				required:  false
				validator: ''
			},
		]
		min_positional: 1
		max_positional: -1
		description:    'Set min pulse width'
	}

	// set_case_analysis
	r.commands['set_case_analysis'] = SdcCommand{
		name:           'set_case_analysis'
		args:           []
		min_positional: 2
		max_positional: -1
		description:    'Set case analysis'
	}

	// set_disable_timing
	r.commands['set_disable_timing'] = SdcCommand{
		name:           'set_disable_timing'
		args:           [
			CmdArg{
				name:      '-from'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-to'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
		]
		min_positional: 1
		max_positional: 1
		description:    'Disable timing arc'
	}

	// set_data_check
	// OpenSTA: check_argc_eq1 - requires 1 positional argument (margin)
	r.commands['set_data_check'] = SdcCommand{
		name:           'set_data_check'
		args:           [
			CmdArg{
				name:      '-from'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-to'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-setup'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-hold'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-rise_from'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-fall_from'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-rise_to'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-fall_to'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-clock'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
		]
		min_positional: 1
		max_positional: 1
		description:    'Set data check'
	}

	// ========== Object Access Commands (Simplified Check) ==========

	// get_pins
	r.commands['get_pins'] = SdcCommand{
		name:           'get_pins'
		args:           [
			CmdArg{
				name:      '-regexp'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-nocase'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-quiet'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-filter'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
		]
		min_positional: 1
		max_positional: -1
		description:    'Get pins'
	}

	// get_ports
	r.commands['get_ports'] = SdcCommand{
		name:           'get_ports'
		args:           [
			CmdArg{
				name:      '-regexp'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-nocase'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-quiet'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-filter'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
		]
		min_positional: 1
		max_positional: -1
		description:    'Get ports'
	}

	// get_cells
	r.commands['get_cells'] = SdcCommand{
		name:           'get_cells'
		args:           [
			CmdArg{
				name:      '-regexp'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-nocase'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-quiet'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-filter'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
		]
		min_positional: 1
		max_positional: -1
		description:    'Get cells'
	}

	// get_nets
	r.commands['get_nets'] = SdcCommand{
		name:           'get_nets'
		args:           [
			CmdArg{
				name:      '-regexp'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-nocase'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-quiet'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-filter'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
		]
		min_positional: 1
		max_positional: -1
		description:    'Get nets'
	}

	// get_clocks
	r.commands['get_clocks'] = SdcCommand{
		name:           'get_clocks'
		args:           [
			CmdArg{
				name:      '-regexp'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-nocase'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-quiet'
				arg_type:  .flag
				required:  false
				validator: ''
			},
		]
		min_positional: 1
		max_positional: -1
		description:    'Get clocks'
	}

	// all_inputs, all_outputs, all_clocks
	r.commands['all_inputs'] = SdcCommand{
		name:           'all_inputs'
		args:           [
			CmdArg{
				name:      '-no_clocks'
				arg_type:  .flag
				required:  false
				validator: ''
			},
		]
		min_positional: 0
		max_positional: 0
		description:    'Get all input ports'
	}

	r.commands['all_outputs'] = SdcCommand{
		name:           'all_outputs'
		args:           []
		min_positional: 0
		max_positional: 0
		description:    'Get all output ports'
	}

	r.commands['all_clocks'] = SdcCommand{
		name:           'all_clocks'
		args:           []
		min_positional: 0
		max_positional: 0
		description:    'Get all clocks'
	}

	r.commands['all_registers'] = SdcCommand{
		name:           'all_registers'
		args:           [
			CmdArg{
				name:      '-clock'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-rise_clock'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-fall_clock'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-cells'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-data_pins'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-clock_pins'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-slave_clock_pins'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-async_pins'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-output_pins'
				arg_type:  .flag
				required:  false
				validator: ''
			},
		]
		min_positional: 0
		max_positional: 0
		description:    'Get all registers'
	}

	// ========== Other Commands ==========

	// read_sdc
	r.commands['read_sdc'] = SdcCommand{
		name:           'read_sdc'
		args:           [
			CmdArg{
				name:      '-echo'
				arg_type:  .flag
				required:  false
				validator: ''
			},
		]
		min_positional: 1
		max_positional: 1
		description:    'Read SDC file'
	}

	// write_sdc
	r.commands['write_sdc'] = SdcCommand{
		name:           'write_sdc'
		args:           [
			CmdArg{
				name:      '-map_hpins'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-digits'
				arg_type:  .key_value
				required:  false
				validator: 'positive_integer'
			},
			CmdArg{
				name:      '-gzip'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-no_timestamp'
				arg_type:  .flag
				required:  false
				validator: ''
			},
		]
		min_positional: 1
		max_positional: 1
		description:    'Write SDC file'
	}

	// source
	r.commands['source'] = SdcCommand{
		name:           'source'
		args:           [
			CmdArg{
				name:      '-echo'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-compatible'
				arg_type:  .flag
				required:  false
				validator: ''
			},
		]
		min_positional: 1
		max_positional: 1
		description:    'Execute TCL script'
	}

	// current_instance
	r.commands['current_instance'] = SdcCommand{
		name:           'current_instance'
		args:           []
		min_positional: 0
		max_positional: 1
		description:    'Set current instance'
	}

	// current_design
	r.commands['current_design'] = SdcCommand{
		name:           'current_design'
		args:           []
		min_positional: 0
		max_positional: 1
		description:    'Get current design'
	}

	// set_driving_cell
	r.commands['set_driving_cell'] = SdcCommand{
		name:           'set_driving_cell'
		args:           [
			CmdArg{
				name:      '-lib_cell'
				arg_type:  .key_value
				required:  true
				validator: ''
			},
			CmdArg{
				name:      '-library'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-rise'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-fall'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-min'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-max'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-pin'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-from_pin'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-multiply_by'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-dont_scale'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-no_design_rule'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-input_transition_rise'
				arg_type:  .key_value
				required:  false
				validator: 'number'
			},
			CmdArg{
				name:      '-input_transition_fall'
				arg_type:  .key_value
				required:  false
				validator: 'number'
			},
		]
		min_positional: 1
		max_positional: -1
		description:    'Set driving cell'
	}

	// set_load
	r.commands['set_load'] = SdcCommand{
		name:           'set_load'
		args:           [
			CmdArg{
				name:      '-min'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-max'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-rise'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-fall'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-pin_load'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-wire_load'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-subtract_pin_load'
				arg_type:  .flag
				required:  false
				validator: ''
			},
		]
		min_positional: 2
		max_positional: 2
		description:    'Set load'
	}

	// set_input_transition
	r.commands['set_input_transition'] = SdcCommand{
		name:           'set_input_transition'
		args:           [
			CmdArg{
				name:      '-rise'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-fall'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-min'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-max'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-clock'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-clock_fall'
				arg_type:  .flag
				required:  false
				validator: ''
			},
		]
		min_positional: 2
		max_positional: 2
		description:    'Set input transition'
	}

	// set_propagated_clock
	r.commands['set_propagated_clock'] = SdcCommand{
		name:           'set_propagated_clock'
		args:           []
		min_positional: 1
		max_positional: -1
		description:    'Set propagated clock'
	}

	// set_fanout_load
	r.commands['set_fanout_load'] = SdcCommand{
		name:           'set_fanout_load'
		args:           []
		min_positional: 2
		max_positional: 2
		description:    'Set fanout load'
	}

	// set_resistance
	r.commands['set_resistance'] = SdcCommand{
		name:           'set_resistance'
		args:           [
			CmdArg{
				name:      '-min'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-max'
				arg_type:  .flag
				required:  false
				validator: ''
			},
		]
		min_positional: 2
		max_positional: 2
		description:    'Set resistance'
	}

	// set_voltage
	r.commands['set_voltage'] = SdcCommand{
		name:           'set_voltage'
		args:           [
			CmdArg{
				name:      '-min'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-max'
				arg_type:  .flag
				required:  false
				validator: ''
			},
		]
		min_positional: 1
		max_positional: 2
		description:    'Set voltage'
	}

	// set_timing_derate
	// OpenSTA: check_argc_eq1or2 - requires 1-2 positional arguments (derate [objects])
	r.commands['set_timing_derate'] = SdcCommand{
		name:           'set_timing_derate'
		args:           [
			CmdArg{
				name:      '-rise'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-fall'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-early'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-late'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-clock'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-data'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-cell_delay'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-cell_check'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-net_delay'
				arg_type:  .flag
				required:  false
				validator: ''
			},
		]
		min_positional: 1
		max_positional: 2
		description:    'Set timing derate'
	}

	// set_max_area
	r.commands['set_max_area'] = SdcCommand{
		name:           'set_max_area'
		args:           []
		min_positional: 1
		max_positional: 1
		description:    'Set max area'
	}

	// set
	r.commands['set'] = SdcCommand{
		name:           'set'
		args:           []
		min_positional: 2
		max_positional: 2
		description:    'Set variable'
	}

	// echo (for debugging)
	r.commands['echo'] = SdcCommand{
		name:           'echo'
		args:           []
		min_positional: 0
		max_positional: -1
		description:    'Output message'
	}

	// puts (for debugging)
	r.commands['puts'] = SdcCommand{
		name:           'puts'
		args:           [
			CmdArg{
				name:      '-nonewline'
				arg_type:  .flag
				required:  false
				validator: ''
			},
		]
		min_positional: 0
		max_positional: -1
		description:    'Output message'
	}

	// ========== Drive and Load Commands ==========

	// set_drive
	r.commands['set_drive'] = SdcCommand{
		name:           'set_drive'
		args:           [
			CmdArg{
				name:      '-rise'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-fall'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-min'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-max'
				arg_type:  .flag
				required:  false
				validator: ''
			},
		]
		min_positional: 2
		max_positional: 2
		description:    'Set drive resistance'
	}

	// ========== Logic Value Commands ==========

	// set_logic_zero
	r.commands['set_logic_zero'] = SdcCommand{
		name:           'set_logic_zero'
		args:           []
		min_positional: 1
		max_positional: -1
		description:    'Set logic zero'
	}

	// set_logic_one
	r.commands['set_logic_one'] = SdcCommand{
		name:           'set_logic_one'
		args:           []
		min_positional: 1
		max_positional: -1
		description:    'Set logic one'
	}

	// set_logic_dc
	r.commands['set_logic_dc'] = SdcCommand{
		name:           'set_logic_dc'
		args:           []
		min_positional: 1
		max_positional: -1
		description:    'Set logic dont care'
	}

	// ========== Power Commands ==========

	// set_max_dynamic_power
	r.commands['set_max_dynamic_power'] = SdcCommand{
		name:           'set_max_dynamic_power'
		args:           []
		min_positional: 1
		max_positional: 2
		description:    'Set max dynamic power'
	}

	// set_max_leakage_power
	r.commands['set_max_leakage_power'] = SdcCommand{
		name:           'set_max_leakage_power'
		args:           []
		min_positional: 1
		max_positional: 2
		description:    'Set max leakage power'
	}

	// ========== Wire Load Commands ==========

	// set_wire_load_min_block_size
	r.commands['set_wire_load_min_block_size'] = SdcCommand{
		name:           'set_wire_load_min_block_size'
		args:           []
		min_positional: 1
		max_positional: 1
		description:    'Set wire load min block size'
	}

	// set_wire_load_selection_group
	r.commands['set_wire_load_selection_group'] = SdcCommand{
		name:           'set_wire_load_selection_group'
		args:           [
			CmdArg{
				name:      '-library'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
		]
		min_positional: 1
		max_positional: -1
		description:    'Set wire load selection group'
	}

	// ========== Path Grouping and Timing Analysis Commands ==========

	// group_path
	r.commands['group_path'] = SdcCommand{
		name:           'group_path'
		args:           [
			CmdArg{
				name:      '-name'
				arg_type:  .key_value
				required:  true
				validator: ''
			},
			CmdArg{
				name:      '-weight'
				arg_type:  .key_value
				required:  false
				validator: 'positive_number'
			},
			CmdArg{
				name:      '-from'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-to'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-through'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-rise_from'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-fall_from'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-rise_to'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-fall_to'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
		]
		min_positional: 0
		max_positional: 0
		description:    'Group path'
	}

	// set_path_margin
	r.commands['set_path_margin'] = SdcCommand{
		name:           'set_path_margin'
		args:           [
			CmdArg{
				name:      '-from'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-to'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-through'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-rise_from'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-fall_from'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-rise_to'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-fall_to'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-rise'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-fall'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-setup'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-hold'
				arg_type:  .flag
				required:  false
				validator: ''
			},
		]
		min_positional: 1
		max_positional: 1
		description:    'Set path margin'
	}

	// set_noise_margin
	r.commands['set_noise_margin'] = SdcCommand{
		name:           'set_noise_margin'
		args:           [
			CmdArg{
				name:      '-above'
				arg_type:  .key_value
				required:  false
				validator: 'non_negative_number'
			},
			CmdArg{
				name:      '-below'
				arg_type:  .key_value
				required:  false
				validator: 'non_negative_number'
			},
			CmdArg{
				name:      '-high'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-low'
				arg_type:  .flag
				required:  false
				validator: ''
			},
		]
		min_positional: 1
		max_positional: -1
		description:    'Set noise margin'
	}

	// set_sense
	r.commands['set_sense'] = SdcCommand{
		name:           'set_sense'
		args:           [
			CmdArg{
				name:      '-type'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-positive'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-negative'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-stop_propagation'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-clock'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
		]
		min_positional: 1
		max_positional: -1
		description:    'Set timing sense'
	}

	// set_clock_exclusivity
	r.commands['set_clock_exclusivity'] = SdcCommand{
		name:           'set_clock_exclusivity'
		args:           [
			CmdArg{
				name:      '-from'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-to'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-rise_from'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-fall_from'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-rise_to'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-fall_to'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
		]
		min_positional: 1
		max_positional: -1
		description:    'Set clock exclusivity'
	}

	// set_level_shifter_strategy
	r.commands['set_level_shifter_strategy'] = SdcCommand{
		name:           'set_level_shifter_strategy'
		args:           [
			CmdArg{
				name:      '-rule'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
		]
		min_positional: 1
		max_positional: 1
		description:    'Set level shifter strategy'
	}

	// set_level_shifter_threshold
	r.commands['set_level_shifter_threshold'] = SdcCommand{
		name:           'set_level_shifter_threshold'
		args:           [
			CmdArg{
				name:      '-voltage'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-rule'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
		]
		min_positional: 1
		max_positional: 1
		description:    'Set level shifter threshold'
	}

	// set_port_fanout_number
	r.commands['set_port_fanout_number'] = SdcCommand{
		name:           'set_port_fanout_number'
		args:           []
		min_positional: 2
		max_positional: 2
		description:    'Set port fanout number'
	}

	// set_routing_rule
	r.commands['set_routing_rule'] = SdcCommand{
		name:           'set_routing_rule'
		args:           [
			CmdArg{
				name:      '-min'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-max'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-default'
				arg_type:  .flag
				required:  false
				validator: ''
			},
		]
		min_positional: 1
		max_positional: -1
		description:    'Set routing rule'
	}

	// set_scan_chain
	r.commands['set_scan_chain'] = SdcCommand{
		name:           'set_scan_chain'
		args:           [
			CmdArg{
				name:      '-name'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
		]
		min_positional: 1
		max_positional: 1
		description:    'Set scan chain'
	}

	// set_clock_jitter
	r.commands['set_clock_jitter'] = SdcCommand{
		name:           'set_clock_jitter'
		args:           [
			CmdArg{
				name:      '-clock'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-jitter'
				arg_type:  .key_value
				required:  false
				validator: 'non_negative_number'
			},
		]
		min_positional: 1
		max_positional: -1
		description:    'Set clock jitter'
	}

	// set_clock_pulse_width
	r.commands['set_clock_pulse_width'] = SdcCommand{
		name:           'set_clock_pulse_width'
		args:           [
			CmdArg{
				name:      '-low'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-high'
				arg_type:  .flag
				required:  false
				validator: ''
			},
		]
		min_positional: 2
		max_positional: 2
		description:    'Set clock pulse width'
	}

	// set_max_time_borrow
	r.commands['set_max_time_borrow'] = SdcCommand{
		name:           'set_max_time_borrow'
		args:           []
		min_positional: 2
		max_positional: 2
		description:    'Set max time borrow'
	}

	// ========== Library Related Commands (LLM Common) ==========

	// get_lib_cells
	r.commands['get_lib_cells'] = SdcCommand{
		name:           'get_lib_cells'
		args:           [
			CmdArg{
				name:      '-regexp'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-nocase'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-quiet'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-filter'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
		]
		min_positional: 1
		max_positional: -1
		description:    'Get library cells'
	}

	// get_lib_pins
	r.commands['get_lib_pins'] = SdcCommand{
		name:           'get_lib_pins'
		args:           [
			CmdArg{
				name:      '-regexp'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-nocase'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-quiet'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-filter'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
		]
		min_positional: 1
		max_positional: -1
		description:    'Get library pins'
	}

	// get_libs
	r.commands['get_libs'] = SdcCommand{
		name:           'get_libs'
		args:           [
			CmdArg{
				name:      '-regexp'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-nocase'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-quiet'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-filter'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
		]
		min_positional: 0
		max_positional: -1
		description:    'Get library list'
	}

	// ========== PVT and Corner Commands (LLM Common) ==========

	// define_corners
	r.commands['define_corners'] = SdcCommand{
		name:           'define_corners'
		args:           []
		min_positional: 1
		max_positional: -1
		description:    'Define PVT corners'
	}

	// set_pvt
	r.commands['set_pvt'] = SdcCommand{
		name:           'set_pvt'
		args:           [
			CmdArg{
				name:      '-corner'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-process'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-voltage'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-temperature'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
		]
		min_positional: 0
		max_positional: 0
		description:    'Set PVT parameters'
	}

	// ========== Voltage Area Commands (LLM Common) ==========

	// create_voltage_area
	r.commands['create_voltage_area'] = SdcCommand{
		name:           'create_voltage_area'
		args:           [
			CmdArg{
				name:      '-name'
				arg_type:  .key_value
				required:  true
				validator: ''
			},
			CmdArg{
				name:      '-power_domain'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-guard_band_x'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-guard_band_y'
				arg_type:  .key_value
				required:  false
				validator: ''
			},
		]
		min_positional: 1
		max_positional: -1
		description:    'Create voltage area'
	}

	// ========== Ideal Network Commands (OpenSTA Supported but Ignored) ==========

	// set_ideal_latency
	r.commands['set_ideal_latency'] = SdcCommand{
		name:           'set_ideal_latency'
		args:           [
			CmdArg{
				name:      '-rise'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-fall'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-min'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-max'
				arg_type:  .flag
				required:  false
				validator: ''
			},
		]
		min_positional: 2
		max_positional: -1
		description:    'Set ideal latency (OpenSTA ignores)'
	}

	// set_ideal_net
	r.commands['set_ideal_net'] = SdcCommand{
		name:           'set_ideal_net'
		args:           []
		min_positional: 1
		max_positional: -1
		description:    'Set ideal net (OpenSTA ignores)'
	}

	// set_ideal_network
	r.commands['set_ideal_network'] = SdcCommand{
		name:           'set_ideal_network'
		args:           [
			CmdArg{
				name:      '-no_propagation'
				arg_type:  .flag
				required:  false
				validator: ''
			},
		]
		min_positional: 1
		max_positional: -1
		description:    'Set ideal network (OpenSTA ignores)'
	}

	// set_ideal_transition
	r.commands['set_ideal_transition'] = SdcCommand{
		name:           'set_ideal_transition'
		args:           [
			CmdArg{
				name:      '-rise'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-fall'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-min'
				arg_type:  .flag
				required:  false
				validator: ''
			},
			CmdArg{
				name:      '-max'
				arg_type:  .flag
				required:  false
				validator: ''
			},
		]
		min_positional: 2
		max_positional: -1
		description:    'Set ideal transition (OpenSTA ignores)'
	}
}

// Get all command names (for displaying help)
pub fn (r &CommandRegistry) get_all_commands() []string {
	mut names := []string{}
	for name, _ in r.commands {
		names << name
	}
	names.sort()
	return names
}