# 测试未定义时钟引用
create_clock -period 10.0 -name clk1 [get_ports clk]

# 引用未定义的时钟 clk2（应该报错）
set_input_delay -clock clk2 -max 2.5 [get_ports data_in]

# 定义生成时钟引用未定义的主时钟（应该报错）
create_generated_clock -name clk_div -source clk3 -divide_by 2 [get_pins div/out]