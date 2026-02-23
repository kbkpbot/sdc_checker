module main

import os
import config
import constants
import tokenizer
import parser
import checker
import errors
import time
import x.json2

// Show help information
fn show_help(program_name string) {
	println(config.show_help(program_name))
}

// Show version information
fn show_version() {
	println('SDC Checker v' + constants.version)
}

// Check single file
fn check_file(file_path string, cfg config.Config) {
	start_time := time.now()
	
	// Read file
	content := os.read_file(file_path) or {
		if cfg.json_output {
			println('{\n  "version": "${constants.version}",\n  "status": "failed",\n  "errors": [{\n    "error_code": ${int(constants.ErrorCode.file_read_error)},\n    "message": "Failed to read file: ${escape_string(file_path)}"\n  }],\n  "summary": {\n    "error_count": 1,\n    "warning_count": 0\n  }\n}')
		} else {
			eprintln('Error: Failed to read file "' + file_path + '": ' + err.str())
		}
		exit(1)
	}

	// Tokenization
	mut tok := tokenizer.new_tokenizer(content)
	tokens := tok.tokenize()

	// Check lexical errors (bracket/quote matching, etc.)
	if tok.has_errors() {
		tok_errs := tok.get_errors()
		if cfg.json_output {
			mut json_errs := []errors.JsonError{}
			for err in tok_errs {
				json_errs << errors.JsonError{
					file:       file_path
					line:       err.line
					column:     err.col
					error_code:  int(constants.ErrorCode.unmatched_brace)
					error_type:   'tcl_syntax_error'
					message:    err.message
					suggestion: 'Check and fix corresponding brackets or quotes'
					severity:   'error'
				}
			}
			stats := errors.Statistics{
				total_commands:    0
				checked_commands:  0
				error_count:       tok_errs.len
				warning_count:     0
				check_duration_ms: int(time.since(start_time).milliseconds())
			}
			output := errors.JsonOutput{
				version:    constants.version
				status:     'failed'
				errors:     json_errs
				warnings:   []
				summary:    errors.Summary{error_count: tok_errs.len}
				statistics: stats
				metadata:   errors.Metadata{
					tool_name:   'sdc_checker'
					version:     constants.version
					strict_mode: cfg.strict_mode
					timestamp:   ''
				}
			}
			println(json2.encode(output, prettify: true))
		} else {
			for err in tok_errs {
				println('${file_path}:${err.line}:${err.col}: error: ${err.message}')
			}
			println('-'.repeat(50))
			println('Found ${tok_errs.len} lexical error(s)')
		}
		exit(1)
	}

	if cfg.verbose && !cfg.json_output {
		println('Tokenization completed, generated ' + tokens.len.str() + ' token(s)')
	}
	
	// Parsing
	mut p := parser.new_parser(tokens, file_path)
	commands := p.parse_all()

	if cfg.verbose && !cfg.json_output {
		println('Parsing completed, parsed ' + commands.len.str() + ' command(s)')
	}

	// Semantic checking
	mut chk := checker.new_checker(file_path, cfg.strict_mode, cfg.ignore_warns)
	chk.check_all(commands)

	// Calculate duration
	duration := time.since(start_time).milliseconds()

	// Output check results
	reporter := chk.get_reporter()
	if cfg.json_output {
		stats := errors.Statistics{
			total_commands:     commands.len
			checked_commands:   commands.len
			error_count:        reporter.error_count()
			warning_count:      reporter.warning_count()
			check_duration_ms:  int(duration)
		}
		println(reporter.to_json(stats, cfg.strict_mode))
	} else {
		reporter.report()
	}

	// Set exit code based on check results
	if chk.has_errors() {
		exit(1)
	}
}

// Simple string escape
fn escape_string(s string) string {
	mut result := ''
	for ch in s {
		match ch {
			`"` { result += '\\"' }
			`\\` { result += '\\\\' }
			`\n` { result += '\\n' }
			else { result += ch.ascii_str() }
		}
	}
	return result
}

// Main function
fn main() {
	args := os.args
	program_name := os.base(args[0])

	// Parse arguments using new config system
	cfg, file_path, error_msg := config.parse_args(args)

	// Handle special directives
	if error_msg == 'help' {
		show_help(program_name)
		exit(0)
	}

	if error_msg == 'version' {
		show_version()
		exit(0)
	}

	// Handle parse errors
	if error_msg.len > 0 {
		if cfg.json_output {
			println('{\n  "version": "${constants.version}",\n  "status": "failed",\n  "errors": [{\n    "message": "${escape_string(error_msg)}"\n  }],\n  "summary": {\n    "error_count": 1,\n    "warning_count": 0\n  }\n}')
		} else {
			eprintln('Error: ' + error_msg)
			eprintln('Use -h or --help for help information')
		}
		exit(1)
	}

	// Check if file is provided
	if file_path.len == 0 {
		if cfg.json_output {
			println('{\n  "version": "${constants.version}",\n  "status": "failed",\n  "errors": [{\n    "error_code": ${int(constants.ErrorCode.file_not_found)},\n    "message": "No SDC file specified"\n  }],\n  "summary": {\n    "error_count": 1,\n    "warning_count": 0\n  }\n}')
		} else {
			eprintln('Error: No SDC file specified')
			eprintln('Use -h or --help for help information')
		}
		exit(1)
	}

	// Execute check
	check_file(file_path, cfg)
}