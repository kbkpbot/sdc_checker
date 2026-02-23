// TCL/SDC parser module
// Parses token sequences into command structures

module parser

import tokenizer
import commands

// Parsed command structure
pub struct ParsedCommand {
pub:
	name        string            // Command name
	args        map[string]string // Key-value pair arguments (flag -> value)
	flags       []string          // Flag argument list
	positionals []string          // Positional argument list
	line        int               // Command line number
	col         int               // Command column number
}

// Parser structure
pub struct Parser {
pub:
	tokens []tokenizer.Token // Token list
pub mut:
	pos      int               // Current token position
	file     string            // File name
	registry commands.CommandRegistry // Command registry (used to query flag attributes)
}

// Creates a new parser
pub fn new_parser(tokens []tokenizer.Token, file string) Parser {
	return Parser{
		tokens:   tokens
		pos:      0
		file:     file
		registry: commands.new_command_registry()
	}
}

// Gets the current token
fn (p &Parser) peek() tokenizer.Token {
	if p.pos >= p.tokens.len {
		return p.tokens[p.tokens.len - 1] // Returns EOF
	}
	return p.tokens[p.pos]
}

// Gets the next token (without moving position)
fn (p &Parser) peek_next() tokenizer.Token {
	if p.pos + 1 >= p.tokens.len {
		return p.tokens[p.tokens.len - 1]
	}
	return p.tokens[p.pos + 1]
}

// Moves to the next token
fn (mut p Parser) advance() tokenizer.Token {
	if p.pos >= p.tokens.len {
		return p.tokens[p.tokens.len - 1]
	}
	token := p.tokens[p.pos]
	p.pos++
	return token
}

// Skips newlines and semicolons
fn (mut p Parser) skip_separators() {
	for {
		token := p.peek()
		if token.typ == .newline || token.typ == .semicolon {
			p.advance()
		} else {
			break
		}
	}
}

// Parses a single command
fn (mut p Parser) parse_command() ?ParsedCommand {
	// Skips separators
	p.skip_separators()

	// Checks if end of file is reached
	if p.peek().typ == .eof {
		return none
	}

	// First token must be a command
	cmd_token := p.peek()
	if cmd_token.typ != .command {
		// If not a command, skip this line (may be empty line or comment)
		// Moves to next newline or EOF
		for {
			token := p.advance()
			if token.typ == .newline || token.typ == .eof {
				break
			}
		}
		return none
	}

	// Gets command name and position
	cmd_name := cmd_token.value
	cmd_line := cmd_token.line
	cmd_col := cmd_token.col

	// Moves past command name
	p.advance()

	mut args := map[string]string{}
	mut flags := []string{}
	mut positionals := []string{}

	// Parses command arguments
	for {
		token := p.peek()

		// If separator or EOF is encountered, end command parsing
		if token.typ == .newline || token.typ == .semicolon || token.typ == .eof {
			break
		}

		match token.typ {
			.flag {
				flag_name := token.value
				p.advance()

				// Checks if next token is the value for this flag
				next_token := p.peek()

				// Uses registry to determine if flag is a pure flag (no value needed)
				is_flag_without_value := p.registry.is_flag_without_value(cmd_name, flag_name)

				if is_flag_without_value {
					// Pure flag, does not consume following value
					flags << flag_name
				} else if next_token.typ == .string || next_token.typ == .number {
					// Flag followed by value, stored as key-value pair
					args[flag_name] = next_token.value
					p.advance()
				} else if next_token.typ == .variable {
					// Variable token, needs $ prefix
					args[flag_name] = '$' + next_token.value
					p.advance()
				} else if next_token.typ == .flag {
					// Next is also a flag, current flag has no value
					flags << flag_name
				} else if next_token.typ == .newline || next_token.typ == .semicolon
					|| next_token.typ == .eof {
					// End of line, current flag has no value
					flags << flag_name
				} else {
					// Other cases, treat as having no value
					flags << flag_name
				}
			}
			.string, .number {
				// Positional argument
				positionals << token.value
				p.advance()
			}
			.variable {
				// Variable reference, temporarily treated as string (to be replaced by variable module later)
				positionals << '${token.value}'
				p.advance()
			}
			.bracket_end, .list_end {
				// Unexpected end marker, skip
				p.advance()
			}
			else {
				// Other token types, skip
				p.advance()
			}
		}
	}

	return ParsedCommand{
		name:        cmd_name
		args:        args
		flags:       flags
		positionals: positionals
		line:        cmd_line
		col:         cmd_col
	}
}

// Parses all commands
pub fn (mut p Parser) parse_all() []ParsedCommand {
	mut cmds := []ParsedCommand{}

	for {
		cmd := p.parse_command() or { break }
		cmds << cmd
	}

	return cmds
}

// Gets current token position (for error reporting)
pub fn (p &Parser) get_position() (int, int) {
	token := p.peek()
	return token.line, token.col
}