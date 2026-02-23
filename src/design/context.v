// SDC Design Context Module
// Used to track definitions and references of design objects (clocks, ports, pins, etc.)
// Implements consistency checks between commands

module design

// Design Context Structure
// Tracks all defined objects and constraint relationships during checking
pub struct DesignContext {
pub mut:
	// Defined clocks
	defined_clocks map[string]ClockInfo
	// Defined generated clocks
	defined_generated_clocks map[string]GeneratedClockInfo
	// Defined ports (inferred from set_input_delay/set_output_delay)
	defined_ports map[string]PortInfo
	// Defined pins (inferred from various constraints)
	defined_pins map[string]PinInfo
	// Clock reference relationships (which constraints reference which clocks)
	clock_references map[string][]ReferenceInfo
	// Constraint definition order (used to detect duplicates and overrides)
	constraint_order []ConstraintInfo
	// Clock group relationships
	clock_groups []ClockGroupInfo
}

// Clock Information
pub struct ClockInfo {
pub:
	name       string // Clock name
	period     string // Period
	source     string // Clock source
	line       int    // Line where defined
	col        int    // Column where defined
	is_virtual bool   // Whether it is a virtual clock
}

// Generated Clock Information
pub struct GeneratedClockInfo {
pub:
	name       string // Generated clock name
	source     string // Master clock name
	line       int    // Line where defined
	col        int    // Column where defined
}

// Port Information
pub struct PortInfo {
pub mut:
	name        string // Port name
	direction   string // Direction: input/output/inout
	line        int    // Line where defined
	is_clocked  bool   // Whether it has an associated clock
	clock_names []string // List of associated clock names
}

// Pin Information
pub struct PinInfo {
pub:
	name       string // Pin name
	cell       string // Associated cell (optional)
	line       int    // Line where defined
}

// Reference Information
pub struct ReferenceInfo {
pub:
	command_name string // Command name that references the clock
	arg_name     string // Argument name (e.g., -clock)
	line         int    // Line where referenced
	col          int    // Column where referenced
}

// Constraint Information
pub struct ConstraintInfo {
pub:
	cmd_name    string // Command name
	target      string // Constraint target (port, pin, etc.)
	clock_name  string // Associated clock (if any)
	line        int    // Line number
	constraint_type string // Constraint type: delay/exception/drc
}

// Clock Group Information
pub struct ClockGroupInfo {
pub:
	group_type string   // Type: exclusive/asynchronous
	clocks     []string // List of clocks in the group
	line       int      // Line where defined
}

// Create a new design context
pub fn new_design_context() DesignContext {
	return DesignContext{
		defined_clocks:           map[string]ClockInfo{}
		defined_generated_clocks: map[string]GeneratedClockInfo{}
		defined_ports:            map[string]PortInfo{}
		defined_pins:             map[string]PinInfo{}
		clock_references:         map[string][]ReferenceInfo{}
		constraint_order:         []
		clock_groups:             []
	}
}

// ========== Clock Related Operations ==========

// Register clock definition
pub fn (mut ctx DesignContext) register_clock(name string, period string, source string, line int, col int, is_virtual bool) {
	ctx.defined_clocks[name] = ClockInfo{
		name:       name
		period:     period
		source:     source
		line:       line
		col:        col
		is_virtual: is_virtual
	}
}

// Register generated clock definition
pub fn (mut ctx DesignContext) register_generated_clock(name string, source string, line int, col int) {
	ctx.defined_generated_clocks[name] = GeneratedClockInfo{
		name:   name
		source: source
		line:   line
		col:    col
	}
	
	// Record reference to master clock
	ctx.add_clock_reference(source, 'create_generated_clock', '-source', line, col)
}

// Check if clock is defined (including generated clocks)
pub fn (ctx &DesignContext) is_clock_defined(name string) bool {
	return name in ctx.defined_clocks || name in ctx.defined_generated_clocks
}

// Get clock information
pub fn (ctx &DesignContext) get_clock(name string) ?ClockInfo {
	if name in ctx.defined_clocks {
		return ctx.defined_clocks[name]
	}
	// Generated clocks are also considered clocks
	if name in ctx.defined_generated_clocks {
		gen_clk := ctx.defined_generated_clocks[name]
		return ClockInfo{
			name:   gen_clk.name
			period: ''
			source: gen_clk.source
			line:   gen_clk.line
			col:    gen_clk.col
		}
	}
	return none
}

// Record clock reference
pub fn (mut ctx DesignContext) add_clock_reference(clock_name string, cmd_name string, arg_name string, line int, col int) {
	ref := ReferenceInfo{
		command_name: cmd_name
		arg_name:     arg_name
		line:         line
		col:          col
	}
	
	if clock_name !in ctx.clock_references {
		ctx.clock_references[clock_name] = []ReferenceInfo{}
	}
	ctx.clock_references[clock_name] << ref
}

// ========== Port Related Operations ==========

// Register port definition
pub fn (mut ctx DesignContext) register_port(name string, direction string, line int) {
	ctx.defined_ports[name] = PortInfo{
		name:      name
		direction: direction
		line:      line
		is_clocked: false
		clock_names: []
	}
}

// Associate port with clock
pub fn (mut ctx DesignContext) associate_port_clock(port_name string, clock_name string) {
	if port_name in ctx.defined_ports {
		mut port := ctx.defined_ports[port_name]
		port.is_clocked = true
		if clock_name !in port.clock_names {
			port.clock_names << clock_name
		}
		ctx.defined_ports[port_name] = port
	}
}

// Check if port is defined
pub fn (ctx &DesignContext) is_port_defined(name string) bool {
	return name in ctx.defined_ports
}

// ========== Pin Related Operations ==========

// Register pin definition
pub fn (mut ctx DesignContext) register_pin(name string, cell string, line int) {
	ctx.defined_pins[name] = PinInfo{
		name: name
		cell: cell
		line: line
	}
}

// Check if pin is defined
pub fn (ctx &DesignContext) is_pin_defined(name string) bool {
	return name in ctx.defined_pins
}

// ========== Constraint Tracking ==========

// Record constraint definition
pub fn (mut ctx DesignContext) record_constraint(cmd_name string, target string, clock_name string, line int, constraint_type string) {
	constraint := ConstraintInfo{
		cmd_name:        cmd_name
		target:          target
		clock_name:      clock_name
		line:            line
		constraint_type: constraint_type
	}
	ctx.constraint_order << constraint
}

// Check for duplicate constraints (same target, same clock)
pub fn (ctx &DesignContext) find_duplicate_constraints(cmd_name string, target string, clock_name string) []ConstraintInfo {
	mut duplicates := []ConstraintInfo{}
	for constraint in ctx.constraint_order {
		if constraint.cmd_name == cmd_name 
			&& constraint.target == target 
			&& constraint.clock_name == clock_name {
			duplicates << constraint
		}
	}
	return duplicates
}

// ========== Clock Group Operations ==========

// Register clock group
pub fn (mut ctx DesignContext) register_clock_group(group_type string, clocks []string, line int) {
	ctx.clock_groups << ClockGroupInfo{
		group_type: group_type
		clocks:     clocks
		line:       line
	}
	
	// Verify all clocks in the group exist
	for clock_name in clocks {
		ctx.add_clock_reference(clock_name, 'set_clock_groups', '-group', line, 0)
	}
}

// ========== Consistency Check Methods ==========

// Get all references to undefined clocks
pub fn (ctx &DesignContext) get_undefined_clock_references() map[string][]ReferenceInfo {
	mut undefined := map[string][]ReferenceInfo{}
	
	for clock_name, refs in ctx.clock_references {
		if !ctx.is_clock_defined(clock_name) {
			undefined[clock_name] = refs
		}
	}
	
	return undefined
}

// Get duplicate defined objects
pub fn (ctx &DesignContext) get_duplicate_definitions() map[string][]int {
	mut duplicates := map[string][]int{}
	
	// Check for duplicate clock definitions
	mut clock_seen := map[string]int{}
	for name, info in ctx.defined_clocks {
		if name in clock_seen {
			if name !in duplicates {
				duplicates[name] = [clock_seen[name]]
			}
			duplicates[name] << info.line
		} else {
			clock_seen[name] = info.line
		}
	}
	
	return duplicates
}

// Get constrained but undefined objects
pub fn (ctx &DesignContext) get_constrained_undefined_objects() map[string][]ConstraintInfo {
	mut undefined := map[string][]ConstraintInfo{}
	
	for constraint in ctx.constraint_order {
		// Simplified check: only check obviously undefined objects
		// In practice, should parse get_ports/get_pins commands
		target := constraint.target
		if target.starts_with('get_ports') {
			// Extract port name (simplified handling)
			port_name := target.replace('get_ports', '').trim_space()
			if port_name !in ctx.defined_ports && !port_name.contains('*') {
				// Possibly undefined, record as warning
				if target !in undefined {
					undefined[target] = []ConstraintInfo{}
				}
				undefined[target] << constraint
			}
		}
	}
	
	return undefined
}

// Clear context (used for processing new files)
pub fn (mut ctx DesignContext) clear() {
	ctx.defined_clocks.clear()
	ctx.defined_generated_clocks.clear()
	ctx.defined_ports.clear()
	ctx.defined_pins.clear()
	ctx.clock_references.clear()
	ctx.constraint_order.clear()
	ctx.clock_groups.clear()
}
