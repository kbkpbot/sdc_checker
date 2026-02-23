# 测试有效的交叉引用
# 定义主时钟
create_clock -period 10.0 -name sys_clk [get_ports clk]

# 定义生成时钟（引用已定义的时钟）
create_generated_clock -name clk_div -source sys_clk -divide_by 2 [get_pins u_div/clk_out]

# 设置输入延迟（引用已定义的时钟）
set_input_delay -clock sys_clk -max 2.5 [get_ports data_in]
set_input_delay -clock sys_clk -min 0.5 [get_ports data_in]

# 设置输出延迟
set_output_delay -clock sys_clk -max 3.0 [get_ports data_out]