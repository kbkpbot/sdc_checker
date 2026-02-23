// Configuration System Module
// Unified management of all configuration options

module config

// Application Configuration
pub struct Config {
pub mut:
	verbose          bool     // Verbose output
	json_output      bool     // JSON format output
	strict_mode      bool     // Strict mode
	max_errors       int      // Maximum error limit (0 = unlimited)
	ignore_warns     []string // List of warning types to ignore
	show_suggestions bool     // Show fix suggestions
}

// Create default configuration
pub fn default_config() Config {
	return Config{
		verbose:          false
		json_output:      false
		strict_mode:      false
		max_errors:       0  // Unlimited
		ignore_warns:     []
		show_suggestions: true
	}
}

// Parse configuration from command line arguments
pub fn parse_args(args []string) (Config, string, string) {
	mut cfg := default_config()
	mut file_path := ''
	mut error_msg := ''

	for i := 1; i < args.len; i++ {
		arg := args[i]

		match arg {
			'-h', '--help' {
				return cfg, '', 'help'
			}
			'-v', '--version' {
				return cfg, '', 'version'
			}
			'-V', '--verbose' {
				cfg.verbose = true
			}
			'--json' {
				cfg.json_output = true
			}
			'--strict' {
				cfg.strict_mode = true
			}
			'--no-suggestions' {
				cfg.show_suggestions = false
			}
			else {
				if arg.starts_with('--ignore-warning=') {
					// Parse ignored warning types
					warn_types := arg.all_after('--ignore-warning=').split(',')
					for wt in warn_types {
						cfg.ignore_warns << wt.trim_space()
					}
				} else if arg.starts_with('-') {
					error_msg = 'Unknown option: ${arg}'
					return cfg, '', error_msg
				} else {
					// File path
					if file_path.len == 0 {
						file_path = arg
					} else {
						error_msg = 'Only one file can be specified'
						return cfg, '', error_msg
					}
				}
			}
		}
	}

	return cfg, file_path, error_msg
}

// Show help information
pub fn show_help(program_name string) string {
	return 'SDC File Checker

Usage: ${program_name} [options] <sdc_file>

Options:
  -h, --help              Show help information
  -v, --version           Show version information
  -V, --verbose           Show verbose output
  --json                  Output results in JSON format
  --strict                Enable strict mode (additional checks)
  --no-suggestions        Do not show fix suggestions
  --ignore-warning=TYPES  Ignore specified warning types (comma-separated)

Examples:
  ${program_name} design.sdc
  ${program_name} --json design.sdc
  ${program_name} --strict --ignore-warning=ambiguous_wildcard,unrealistic_period design.sdc'
}

// Check if a warning type should be ignored
pub fn (c &Config) should_ignore_warning(warn_type string) bool {
	return warn_type in c.ignore_warns
}