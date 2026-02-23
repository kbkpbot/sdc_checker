// Tokenizer 单元测试
// 测试词法分析器的各种功能

module tokenizer

// 测试基本命令识别
fn test_tokenize_simple_command() {
	mut tok := new_tokenizer('create_clock -period 10.0 clk')
	tokens := tok.tokenize()
	
	// 实际产生 5 个 token: command, flag, number, string, eof
	assert tokens.len >= 4, 'Expected at least 4 tokens, got ${tokens.len}'
	assert tokens[0].typ == .command, 'First token should be command, got ${tokens[0].typ}'
	assert tokens[0].value == 'create_clock', 'Command name should be "create_clock", got "${tokens[0].value}"'
	assert tokens[1].typ == .flag, 'Second token should be flag'
	assert tokens[1].value == '-period', 'Flag should be "-period"'
	assert tokens[2].typ == .number, 'Third token should be number'
	assert tokens[2].value == '10.0', 'Number should be "10.0"'
}

// 测试字符串处理（双引号）
fn test_tokenize_quoted_string() {
	mut tok := new_tokenizer('set clk_name "sys_clk"')
	tokens := tok.tokenize()
	
	assert tokens[0].typ == .command
	assert tokens[1].typ == .string
	assert tokens[1].value == 'clk_name'
	assert tokens[2].typ == .string
	assert tokens[2].value == 'sys_clk', 'Quoted string should be unquoted, got "${tokens[2].value}"'
}

// 测试花括号字符串
fn test_tokenize_braced_string() {
	mut tok := new_tokenizer('set waveform {0 5.0 10.0}')
	tokens := tok.tokenize()
	
	assert tokens[0].typ == .command
	assert tokens[2].typ == .string
	assert tokens[2].value == '0 5.0 10.0', 'Braced content should be extracted'
}

// 测试变量引用
fn test_tokenize_variable() {
	mut tok := new_tokenizer('create_clock -period \$clk_period')
	tokens := tok.tokenize()
	
	// 找到 variable token
	mut found_var := false
	for token in tokens {
		if token.typ == .variable {
			found_var = true
			assert token.value == 'clk_period', 'Variable name should be "clk_period"'
			break
		}
	}
	assert found_var, 'Should find a variable token'
}

// 测试方括号命令
fn test_tokenize_bracket_command() {
	mut tok := new_tokenizer('[get_ports clk]')
	tokens := tok.tokenize()
	
	// 方括号内容应该作为 string token
	mut found_bracket := false
	for token in tokens {
		if token.typ == .string && token.value.contains('get_ports') {
			found_bracket = true
			break
		}
	}
	assert found_bracket, 'Should find bracket command as string'
}

// 测试注释跳过
fn test_tokenize_comment() {
	mut tok := new_tokenizer('# This is a comment\ncreate_clock -period 10.0 clk')
	tokens := tok.tokenize()
	
	// 第一个非换行 token 应该是命令
	for token in tokens {
		if token.typ == .command {
			assert token.value == 'create_clock', 'Should skip comment and find command'
			return
		}
	}
	assert false, 'Should find create_clock command after comment'
}

// 测试数字识别（带单位）
fn test_tokenize_number_with_unit() {
	mut tok := new_tokenizer('set delay 10.5ns')
	tokens := tok.tokenize()
	
	mut found_number := false
	for token in tokens {
		if token.typ == .number && token.value == '10.5ns' {
			found_number = true
			break
		}
	}
	assert found_number, 'Should recognize number with unit'
}

// 测试多行命令
fn test_tokenize_multiline() {
	mut tok := new_tokenizer('set_input_delay -clock clk 2.5\nset_output_delay -clock clk 3.0')
	tokens := tok.tokenize()
	
	mut command_count := 0
	for token in tokens {
		if token.typ == .command {
			command_count++
		}
	}
	assert command_count == 2, 'Should find 2 commands, found ${command_count}'
}

// 测试分号分隔
fn test_tokenize_semicolon() {
	mut tok := new_tokenizer('set a 1; set b 2')
	tokens := tok.tokenize()
	
	mut semicolon_count := 0
	for token in tokens {
		if token.typ == .semicolon {
			semicolon_count++
		}
	}
	assert semicolon_count == 1, 'Should find 1 semicolon'
}

// 测试空输入
fn test_tokenize_empty() {
	mut tok := new_tokenizer('')
	tokens := tok.tokenize()
	
	assert tokens.len > 0, 'Should have at least EOF token'
	assert tokens[tokens.len - 1].typ == .eof, 'Last token should be EOF'
}

// 测试复杂表达式
fn test_tokenize_complex_expression() {
	input := 'create_generated_clock -name clk_div2 -source [get_pins clk] -divide_by 2 [get_pins div/out]'
	mut tok := new_tokenizer(input)
	tokens := tok.tokenize()
	
	// 验证基本结构
	assert tokens[0].typ == .command
	assert tokens[0].value == 'create_generated_clock'
	
	// 验证 flags
	mut flag_count := 0
	for token in tokens {
		if token.typ == .flag {
			flag_count++
		}
	}
	assert flag_count >= 3, 'Should have at least 3 flags (-name, -source, -divide_by)'
}

// 测试转义字符
fn test_tokenize_escape_sequences() {
	mut tok := new_tokenizer('set msg "Line1\nLine2\tTab"')
	tokens := tok.tokenize()
	
	for token in tokens {
		if token.typ == .string && token.value.contains('Line1') {
			// 验证转义被正确处理
			assert token.value.contains('\n'), '\\n should be converted to newline'
			assert token.value.contains('\t'), '\\t should be converted to tab'
			return
		}
	}
	assert false, 'Should find string with escape sequences'
}

// 测试位置信息
fn test_token_position() {
	mut tok := new_tokenizer('create_clock\n  -period 10.0')
	tokens := tok.tokenize()
	
	// 第二个命令应该在第2行
	for i, token in tokens {
		if token.typ == .flag && token.value == '-period' {
			assert token.line == 2, 'Flag should be on line 2, got line ${token.line}'
			assert token.col == 3, 'Flag should start at column 3, got ${token.col}'
			return
		}
	}
}

// 测试通配符路径
fn test_tokenize_wildcard_path() {
	mut tok := new_tokenizer('set_false_path -from [get_pins */clk] -to [get_pins */d]')
	tokens := tok.tokenize()
	
	mut found_wildcard := false
	for token in tokens {
		if token.typ == .string && (token.value.contains('*/clk') || token.value.contains('*/d')) {
			found_wildcard = true
			break
		}
	}
	assert found_wildcard, 'Should handle wildcard paths'
}

// 测试嵌套花括号
fn test_tokenize_nested_braces() {
	mut tok := new_tokenizer('set nested {outer {inner} end}')
	tokens := tok.tokenize()
	
	for token in tokens {
		if token.typ == .string && token.value.contains('outer') {
			assert token.value == 'outer {inner} end', 'Should handle nested braces'
			return
		}
	}
	assert false, 'Should find nested braced content'
}

// 测试所有 token 类型都被正确处理
fn test_tokenize_all_types() {
	input := 'cmd -flag 123 "string" \$var {brace} [bracket] ; \n'
	mut tok := new_tokenizer(input)
	tokens := tok.tokenize()
	
	mut has_command := false
	mut has_flag := false
	mut has_number := false
	mut has_string := false
	mut has_variable := false
	mut has_semicolon := false
	mut has_newline := false
	
	for token in tokens {
		match token.typ {
			.command { has_command = true }
			.flag { has_flag = true }
			.number { has_number = true }
			.string { has_string = true }
			.variable { has_variable = true }
			.semicolon { has_semicolon = true }
			.newline { has_newline = true }
			else {}
		}
	}
	
	assert has_command, 'Should have command token'
	assert has_flag, 'Should have flag token'
	assert has_number, 'Should have number token'
	assert has_string, 'Should have string token'
	assert has_variable, 'Should have variable token'
	assert has_semicolon, 'Should have semicolon token'
	assert has_newline, 'Should have newline token'
}

// ========== 括号/引号匹配检查测试 ==========

// 测试未闭合的花括号
fn test_unclosed_brace() {
	input := 'create_clock -period 10.0 {clk'
	mut tok := new_tokenizer(input)
	tok.tokenize()

	assert tok.has_errors(), 'Should detect unclosed brace'
	errs := tok.get_errors()
	assert errs.len > 0, 'Should have at least one error'
	assert errs[0].message.contains('未闭合'), 'Error message should mention unclosed brace'
}

// 测试未闭合的方括号
fn test_unclosed_bracket() {
	input := 'get_ports [all_clocks'
	mut tok := new_tokenizer(input)
	tok.tokenize()

	assert tok.has_errors(), 'Should detect unclosed bracket'
	errs := tok.get_errors()
	assert errs.len > 0, 'Should have at least one error'
}

// 测试未闭合的双引号
fn test_unclosed_quote() {
	input := 'set clk_name "sys_clk'
	mut tok := new_tokenizer(input)
	tok.tokenize()

	assert tok.has_errors(), 'Should detect unclosed quote'
	errs := tok.get_errors()
	assert errs.len > 0, 'Should have at least one error'
}

// 测试正确的闭合
fn test_properly_closed_delimiters() {
	input := 'create_clock -name "clk" -period 10.0 [get_ports {clk_port}]'
	mut tok := new_tokenizer(input)
	tok.tokenize()

	assert !tok.has_errors(), 'Should not report errors for properly closed delimiters'
}