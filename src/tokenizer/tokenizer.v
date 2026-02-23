// TCL/SDC 词法分析器模块
// 将输入文本分解为Token序列

module tokenizer

// 词法单元类型
pub enum TokenType {
	command       // 命令名称
	flag          // 标志参数，如 -period
	string        // 字符串
	number        // 数字
	variable      // 变量引用，如 $var
	list_start    // {
	list_end      // }
	bracket_start // [
	bracket_end   // ]
	semicolon     // ;
	newline       // 换行
	eof           // 文件结束
	error         // 词法错误
}

// 词法单元结构体
pub struct Token {
pub:
	typ   TokenType // Token类型
	value string    // Token值
	line  int       // 所在行号
	col   int       // 所在列号
}

// 词法分析器结构体
pub struct Tokenizer {
	content string // 输入内容
pub mut:
	pos            int     // 当前位置
	line           int     // 当前行号
	col            int     // 当前列号
	tokens         []Token // 生成的Token列表
	brace_depth    int     // 花括号嵌套深度
	bracket_depth  int     // 方括号嵌套深度
	quote_open     bool    // 是否有未闭合的双引号
	errors         []TokenError // 词法错误列表
}

// 词法错误结构体
pub struct TokenError {
pub:
	line    int    // 错误所在行
	col     int    // 错误所在列
	message string // 错误信息
}

// 创建新的词法分析器
pub fn new_tokenizer(content string) Tokenizer {
	return Tokenizer{
		content:       content
		pos:           0
		line:          1
		col:           1
		tokens:        []
		brace_depth:   0
		bracket_depth: 0
		quote_open:    false
		errors:        []
	}
}

// 获取当前字符
fn (t &Tokenizer) peek() u8 {
	if t.pos >= t.content.len {
		return `\0`
	}
	return t.content[t.pos]
}

// 获取下一个字符（不移动位置）
fn (t &Tokenizer) peek_next() u8 {
	if t.pos + 1 >= t.content.len {
		return `\0`
	}
	return t.content[t.pos + 1]
}

// 移动到下一个字符
fn (mut t Tokenizer) advance() u8 {
	if t.pos >= t.content.len {
		return `\0`
	}
	ch := t.content[t.pos]
	t.pos++
	if ch == `\n` {
		t.line++
		t.col = 1
	} else {
		t.col++
	}
	return ch
}

// 跳过空白字符（但不跳过换行）
fn (mut t Tokenizer) skip_whitespace() {
	for {
		ch := t.peek()
		if ch == ` ` || ch == `\t` || ch == `\r` {
			t.advance()
		} else {
			break
		}
	}
}

// 跳过空白字符和换行
fn (mut t Tokenizer) skip_whitespace_and_newlines() {
	for {
		ch := t.peek()
		if ch == ` ` || ch == `\t` || ch == `\r` || ch == `\n` {
			t.advance()
		} else {
			break
		}
	}
}

// 跳过注释
fn (mut t Tokenizer) skip_comment() {
	if t.peek() == `#` {
		// 跳过到行尾
		for t.peek() != `\n` && t.peek() != `\0` {
			t.advance()
		}
	}
}

// 读取字符串（双引号包围）
fn (mut t Tokenizer) read_string() string {
	mut result := ''
	t.advance() // 跳过开头的 "
	t.quote_open = true // 标记引号已打开

	for {
		ch := t.peek()
		if ch == `"` || ch == `\0` {
			break
		}
		if ch == `\\` {
			t.advance()
			next_ch := t.peek()
			match next_ch {
				`n` { result += '\n' }
				`t` { result += '\t' }
				`r` { result += '\r' }
				`\\` { result += '\\' }
				`"` { result += '"' }
				`$` { result += '$' }
				`[` { result += '[' }
				`]` { result += ']' }
				`{` { result += '{' }
				`}` { result += '}' }
				`;` { result += ';' }
				else { result += next_ch.ascii_str() }
			}
			t.advance()
		} else {
			result += ch.ascii_str()
			t.advance()
		}
	}

	if t.peek() == `"` {
		t.advance() // 跳过结尾的 "
		t.quote_open = false // 标记引号已关闭
	} else {
		// 未闭合的引号 - 错误已在 check_unclosed_delimiters 中报告
		t.quote_open = true // 保持打开状态以便最终检查
	}

	return result
}

// 读取花括号包围的内容（不处理转义，保留原样）
fn (mut t Tokenizer) read_braced_string() string {
	mut result := ''
	t.advance() // 跳过开头的 {
	t.brace_depth++ // 增加嵌套深度

	mut brace_count := 1
	for brace_count > 0 && t.peek() != `\0` {
		ch := t.peek()
		if ch == `{` {
			brace_count++
			t.brace_depth++ // 增加嵌套深度
		} else if ch == `}` {
			brace_count--
			t.brace_depth-- // 减少嵌套深度
			if brace_count == 0 {
				t.advance()
				break
			}
		}
		result += ch.ascii_str()
		t.advance()
	}

	return result
}

// 读取变量名（$var 或 ${var}）
fn (mut t Tokenizer) read_variable() string {
	mut result := ''
	t.advance() // 跳过 $

	if t.peek() == `{` {
		// ${var} 格式
		t.advance() // 跳过 {
		for t.peek() != `}` && t.peek() != `\0` {
			result += t.peek().ascii_str()
			t.advance()
		}
		if t.peek() == `}` {
			t.advance() // 跳过 }
		}
	} else {
		// $var 格式
		for {
			ch := t.peek()
			if ch.is_alnum() || ch == `_` {
				result += ch.ascii_str()
				t.advance()
			} else {
				break
			}
		}
	}

	return result
}

// 读取方括号包围的命令（TCL 子命令）
fn (mut t Tokenizer) read_bracket_command() string {
	mut result := ''
	t.advance() // 跳过 [
	t.bracket_depth++ // 增加嵌套深度

	mut bracket_count := 1
	for bracket_count > 0 && t.peek() != `\0` {
		ch := t.peek()
		if ch == `[` {
			bracket_count++
			t.bracket_depth++ // 增加嵌套深度
		} else if ch == `]` {
			bracket_count--
			t.bracket_depth-- // 减少嵌套深度
			if bracket_count == 0 {
				t.advance()
				break
			}
		}
		result += ch.ascii_str()
		t.advance()
	}

	return result
}

// 读取标识符或命令
fn (mut t Tokenizer) read_identifier() string {
	mut result := ''

	for {
		ch := t.peek()
		// 标识符可以包含字母、数字、下划线、冒号（用于层次路径）
		if ch.is_alnum() || ch == `_` || ch == `:` || ch == `/` || ch == `.` || ch == `*`
			|| ch == `?` || ch == `[` || ch == `]` || ch == `|` {
			result += ch.ascii_str()
			t.advance()
		} else {
			break
		}
	}

	return result
}

// 读取数字（支持单位后缀如 1ns, 1.5pF 等）
fn (mut t Tokenizer) read_number() string {
	mut result := ''
	mut has_dot := false
	mut has_exp := false

	// 处理负号
	if t.peek() == `-` && t.peek_next().is_digit() {
		result += t.peek().ascii_str()
		t.advance()
	}

	// 读取数字部分
	for {
		ch := t.peek()
		if ch.is_digit() {
			result += ch.ascii_str()
			t.advance()
		} else if ch == `.` && !has_dot && !has_exp {
			has_dot = true
			result += ch.ascii_str()
			t.advance()
		} else if (ch == `e` || ch == `E`) && !has_exp {
			has_exp = true
			result += ch.ascii_str()
			t.advance()
			// 处理指数符号
			if t.peek() == `-` || t.peek() == `+` {
				result += t.peek().ascii_str()
				t.advance()
			}
		} else {
			break
		}
	}

	// 读取单位后缀（字母）
	for {
		ch := t.peek()
		if ch.is_letter() {
			result += ch.ascii_str()
			t.advance()
		} else {
			break
		}
	}

	return result
}

// 判断是否为数字开始
fn (t &Tokenizer) is_number_start() bool {
	ch := t.peek()
	if ch.is_digit() {
		return true
	}
	if ch == `-` && t.peek_next().is_digit() {
		return true
	}
	if ch == `.` && t.peek_next().is_digit() {
		return true
	}
	return false
}

// 词法分析主函数
pub fn (mut t Tokenizer) tokenize() []Token {
	mut is_command_start := true // 新行或分号后开始新命令

	for t.pos < t.content.len {
		mut ch := t.peek()
		mut start_line := t.line
		mut start_col := t.col

		// 跳过空白和注释
		t.skip_whitespace()
		t.skip_comment()

		if t.pos >= t.content.len {
			break
		}

		ch = t.peek()
		start_line = t.line
		start_col = t.col

		// 处理不同类型的Token
		match ch {
			`\n` {
				t.tokens << Token{
					typ:   .newline
					value: '\n'
					line:  start_line
					col:   start_col
				}
				t.advance()
				is_command_start = true
			}
			`;` {
				t.tokens << Token{
					typ:   .semicolon
					value: ';'
					line:  start_line
					col:   start_col
				}
				t.advance()
				is_command_start = true
			}
			`{` {
				value := t.read_braced_string()
				t.tokens << Token{
					typ:   .string
					value: value
					line:  start_line
					col:   start_col
				}
				is_command_start = false
			}
			`}` {
				// 单独的 } 通常表示错误，但在某些上下文中是有效的
				t.tokens << Token{
					typ:   .list_end
					value: '}'
					line:  start_line
					col:   start_col
				}
				t.advance()
				is_command_start = false
			}
			`[` {
				value := t.read_bracket_command()
				t.tokens << Token{
					typ:   .string
					value: '[' + value + ']'
					line:  start_line
					col:   start_col
				}
				is_command_start = false
			}
			`]` {
				t.tokens << Token{
					typ:   .bracket_end
					value: ']'
					line:  start_line
					col:   start_col
				}
				t.advance()
				is_command_start = false
			}
			`"` {
				value := t.read_string()
				t.tokens << Token{
					typ:   .string
					value: value
					line:  start_line
					col:   start_col
				}
				is_command_start = false
			}
			`$` {
				value := t.read_variable()
				t.tokens << Token{
					typ:   .variable
					value: value
					line:  start_line
					col:   start_col
				}
				is_command_start = false
			}
			`-` {
				// 可能是负数或标志参数
				if t.is_number_start() {
					value := t.read_number()
					t.tokens << Token{
						typ:   .number
						value: value
						line:  start_line
						col:   start_col
					}
				} else if is_command_start {
					// 命令开始处不能是 -（除非是负数）
					// 这通常是语法错误，但我们继续处理
					t.advance() // 消耗 -
					value := t.read_identifier()
					t.tokens << Token{
						typ:   .flag
						value: '-' + value
						line:  start_line
						col:   start_col
					}
				} else {
					// 标志参数
					t.advance() // 消耗 -
					value := t.read_identifier()
					t.tokens << Token{
						typ:   .flag
						value: '-' + value
						line:  start_line
						col:   start_col
					}
				}
				is_command_start = false
			}
			else {
				if t.is_number_start() {
					value := t.read_number()
					t.tokens << Token{
						typ:   .number
						value: value
						line:  start_line
						col:   start_col
					}
					is_command_start = false
				} else if ch.is_letter() || ch == `_` || ch == `/` || ch == `.` || ch == `*`
					|| ch == `|` {
					// 标识符或路径（包括 / . * | 等字符）
					value := t.read_identifier() // 第一个单词是命令，其余是参数
					t.tokens << Token{
						typ:   if is_command_start { .command } else { .string }
						value: value
						line:  start_line
						col:   start_col
					}
					is_command_start = false
				} else {
					// 其他字符，跳过
					t.advance()
				}
			}
		}
	}

	// 添加EOF标记
	t.tokens << Token{
		typ:   .eof
		value: ''
		line:  t.line
		col:   t.col
	}

	// 检查是否有未闭合的分隔符
	t.check_unclosed_delimiters()

	return t.tokens
}

// 获取Token列表
pub fn (t &Tokenizer) get_tokens() []Token {
	return t.tokens
}

// 获取词法错误列表
pub fn (t &Tokenizer) get_errors() []TokenError {
	return t.errors
}

// 检查是否有词法错误
pub fn (t &Tokenizer) has_errors() bool {
	return t.errors.len > 0
}

// 检查未闭合的分隔符
fn (mut t Tokenizer) check_unclosed_delimiters() {
	// 检查未闭合的花括号
	if t.brace_depth > 0 {
		t.errors << TokenError{
			line:    t.line
			col:     t.col
			message: '未闭合的花括号，缺少 ${t.brace_depth} 个 }'
		}
		t.tokens << Token{
			typ:   .error
			value: 'unclosed_brace'
			line:  t.line
			col:   t.col
		}
	}

	// 检查未闭合的方括号
	if t.bracket_depth > 0 {
		t.errors << TokenError{
			line:    t.line
			col:     t.col
			message: '未闭合的方括号，缺少 ${t.bracket_depth} 个 ]'
		}
		t.tokens << Token{
			typ:   .error
			value: 'unclosed_bracket'
			line:  t.line
			col:   t.col
		}
	}

	// 检查未闭合的引号
	if t.quote_open {
		t.errors << TokenError{
			line:    t.line
			col:     t.col
			message: '未闭合的双引号'
		}
		t.tokens << Token{
			typ:   .error
			value: 'unclosed_quote'
			line:  t.line
			col:   t.col
		}
	}
}
