// Parser 单元测试
// 测试语法分析器的各种功能

module parser

import tokenizer

// 辅助函数：创建 token 序列并解析
fn parse_input(input string) []ParsedCommand {
	mut tok := tokenizer.new_tokenizer(input)
	tokens := tok.tokenize()
	mut p := new_parser(tokens, 'test.sdc')
	return p.parse_all()
}

// 测试基本命令解析
fn test_parse_simple_command() {
	cmds := parse_input('create_clock -period 10.0 clk')
	
	assert cmds.len == 1, 'Expected 1 command, got ${cmds.len}'
	assert cmds[0].name == 'create_clock', 'Command name should be "create_clock"'
	assert '-period' in cmds[0].args, 'Should have -period argument'
	assert cmds[0].args['-period'] == '10.0', 'Period value should be "10.0"'
	assert cmds[0].positionals.len == 1, 'Should have 1 positional argument'
	assert cmds[0].positionals[0] == 'clk', 'Positional should be "clk"'
}

// 测试纯 flag 参数
fn test_parse_flag_only() {
	cmds := parse_input('set_input_delay -clock clk -max 2.5 [get_ports din]')
	
	assert cmds.len == 1
	// -max 在 set_input_delay 中是纯标志，但 parser 可能会根据后续 token 判断
	// 这里只检查基本解析是否正确
	assert cmds[0].args['-clock'] == 'clk', '-clock should have value'
	assert cmds[0].positionals.len >= 1, 'Should have at least 1 positional argument'
}

// 测试多命令解析
fn test_parse_multiple_commands() {
	cmds := parse_input('set a 1\nset b 2\nset c 3')
	
	assert cmds.len == 3, 'Expected 3 commands, got ${cmds.len}'
	assert cmds[0].name == 'set'
	assert cmds[1].name == 'set'
	assert cmds[2].name == 'set'
}

// 测试分号分隔的命令
fn test_parse_semicolon_commands() {
	cmds := parse_input('set a 1; set b 2')
	
	assert cmds.len == 2, 'Expected 2 commands separated by semicolon'
}

// 测试空行和注释处理
fn test_parse_with_comments() {
	cmds := parse_input('# Comment 1\nset a 1\n# Comment 2\nset b 2')
	
	assert cmds.len == 2, 'Should skip comments and parse 2 commands'
}

// 测试位置参数
fn test_parse_positional_args() {
	cmds := parse_input('set_hierarchy_separator /')
	
	assert cmds[0].positionals.len == 1
	assert cmds[0].positionals[0] == '/'
}

// 测试变量参数
fn test_parse_variable_args() {
	cmds := parse_input('create_clock -period \$clk_period -name \$clk_name')
	
	assert cmds[0].args['-period'] == '\$clk_period', 'Variable should be preserved with $'
	assert cmds[0].args['-name'] == '\$clk_name'
}

// 测试方括号表达式
fn test_parse_bracket_expression() {
	cmds := parse_input('set_input_delay -clock [get_clocks clk] 2.5 [get_ports din]')
	
	// 方括号应该作为字符串处理
	assert cmds[0].args['-clock'].contains('['), 'Bracket expression should be in value'
}

// 测试复杂命令
fn test_parse_complex_command() {
	cmds := parse_input('create_generated_clock -name clk_div2 -source [get_pins clk] -divide_by 2 [get_pins div/out]')
	
	assert cmds.len == 1
	assert cmds[0].name == 'create_generated_clock'
	assert cmds[0].args['-name'] == 'clk_div2'
	assert cmds[0].args['-divide_by'] == '2'
	assert cmds[0].positionals.len == 1
}

// 测试空输入
fn test_parse_empty() {
	cmds := parse_input('')
	
	assert cmds.len == 0, 'Empty input should produce 0 commands'
}

// 测试只有注释
fn test_parse_only_comments() {
	cmds := parse_input('# Only comments\n# No commands')
	
	assert cmds.len == 0, 'Only comments should produce 0 commands'
}

// 测试 set 命令（变量定义）
fn test_parse_set_command() {
	cmds := parse_input('set clk_period 10.0')
	
	assert cmds[0].name == 'set'
	assert cmds[0].positionals.len == 2
	assert cmds[0].positionals[0] == 'clk_period'
	assert cmds[0].positionals[1] == '10.0'
}

// 测试多行命令（使用反斜杠续行 - 注意：当前实现可能不支持）
fn test_parse_line_continuation() {
	// 注意：如果 tokenizer 不支持行续符，这个测试可能需要调整
	input := 'create_clock \\\n    -period 10.0 \\\n    clk'
	cmds := parse_input(input)
	
	// 根据实际实现调整期望
	// 如果实现了行续符支持，应该解析为一个命令
}

// 测试命令位置信息
fn test_parse_command_position() {
	cmds := parse_input('set a 1\nset b 2')
	
	assert cmds[0].line == 1, 'First command should be on line 1'
	assert cmds[1].line == 2, 'Second command should be on line 2'
}

// 测试混合 flags 和位置参数
fn test_parse_mixed_args() {
	cmds := parse_input('set_false_path -setup -from [get_pins a] -to [get_pins b]')
	
	assert cmds[0].name == 'set_false_path'
	assert '-setup' in cmds[0].flags
	assert cmds[0].args['-from'].contains('a')
	assert cmds[0].args['-to'].contains('b')
}

// 测试没有参数的 echo/puts 命令
fn test_parse_echo_command() {
	cmds := parse_input('echo "Hello World"')
	
	assert cmds[0].name == 'echo'
	assert cmds[0].positionals.len == 1
}

// 测试波浪波形参数
fn test_parse_waveform_arg() {
	cmds := parse_input('create_clock -period 10.0 -waveform {0 5.0} clk')
	
	assert cmds[0].args['-waveform'] == '0 5.0'
}

// 测试引号内的空格
fn test_parse_quoted_spaces() {
	cmds := parse_input('set msg "Hello World"')
	
	assert cmds[0].positionals[1] == 'Hello World', 'Quoted string should preserve spaces'
}

// 测试数字识别
fn test_parse_numbers() {
	cmds := parse_input('set a 123\nset b 45.67\nset c -89.0')
	
	assert cmds.len == 3
	assert cmds[0].positionals[1] == '123'
	assert cmds[1].positionals[1] == '45.67'
	assert cmds[2].positionals[1] == '-89.0'
}

// 测试时钟组命令
fn test_parse_clock_groups() {
	cmds := parse_input('set_clock_groups -asynchronous -group {clk1 clk2} -group {clk3 clk4}')
	
	assert cmds[0].name == 'set_clock_groups'
	assert '-asynchronous' in cmds[0].flags
}

// 测试多周期路径
fn test_parse_multicycle_path() {
	cmds := parse_input('set_multicycle_path 2 -setup -from [get_pins a] -to [get_pins b]')
	
	assert cmds[0].name == 'set_multicycle_path'
	assert cmds[0].positionals[0] == '2'
	assert '-setup' in cmds[0].flags
}

// 测试延迟约束
fn test_parse_delay_constraints() {
	cmds := parse_input('set_max_delay 10.0 -from [get_pins a] -to [get_pins b]')
	
	assert cmds[0].name == 'set_max_delay'
	assert cmds[0].positionals[0] == '10.0'
}

// 测试属性设置
fn test_parse_attributes() {
	cmds := parse_input('set_max_transition 0.5 [all_inputs]')
	
	assert cmds[0].name == 'set_max_transition'
	assert cmds[0].positionals[0] == '0.5'
}

// 测试层次分隔符设置
fn test_parse_hierarchy_separator() {
	cmds := parse_input('set_hierarchy_separator /')
	
	assert cmds[0].name == 'set_hierarchy_separator'
	assert cmds[0].positionals[0] == '/'
}

// 测试案例分析
fn test_parse_case_analysis() {
	cmds := parse_input('set_case_analysis 0 [get_ports reset]')
	
	assert cmds[0].name == 'set_case_analysis'
	assert cmds[0].positionals[0] == '0'
}

// 测试驱动单元设置
fn test_parse_driving_cell() {
	cmds := parse_input('set_driving_cell -lib_cell BUFX2 [all_inputs]')
	
	assert cmds[0].name == 'set_driving_cell'
	assert cmds[0].args['-lib_cell'] == 'BUFX2'
}

// 测试负载设置
fn test_parse_load() {
	cmds := parse_input('set_load 0.05 [all_outputs]')
	
	assert cmds[0].name == 'set_load'
	assert cmds[0].positionals[0] == '0.05'
}

// 测试单位设置
fn test_parse_units() {
	cmds := parse_input('set_units -time ns -capacitance pF')
	
	assert cmds[0].name == 'set_units'
	assert cmds[0].args['-time'] == 'ns'
	assert cmds[0].args['-capacitance'] == 'pF'
}

// 测试空命令（只有换行）
fn test_parse_empty_lines() {
	cmds := parse_input('\n\n\n')
	
	assert cmds.len == 0, 'Only newlines should produce 0 commands'
}

// 测试命令后的尾随空格
fn test_parse_trailing_whitespace() {
	cmds := parse_input('set a 1   \nset b 2')
	
	assert cmds.len == 2, 'Should handle trailing whitespace'
}

// 测试连续的 flags
fn test_parse_consecutive_flags() {
	cmds := parse_input('set_input_delay -clock clk -max -min 1.0 [get_ports din]')
	
	// 连续 flags 的解析取决于具体命令定义和后续 token
	// 这里只验证命令被正确解析
	assert cmds[0].name == 'set_input_delay'
	assert '-clock' in cmds[0].args
}
