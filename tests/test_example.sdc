# 测试 SDC 文件
# 这个文件包含一些常见约束，用于测试检查工具

# 设置层次分隔符
set_hierarchy_separator /

# 设置单位
set_units -time ns -capacitance pF -resistance kOhm

# 定义变量
set clk_period 10.0
set clk_name "sys_clk"

# 创建时钟
create_clock -name $clk_name -period $clk_period [get_ports clk]

# 创建生成时钟
create_generated_clock -name clk_div2 -source [get_ports clk] -divide_by 2 [get_pins u_div/clk_out]

# 设置输入延迟
set_input_delay -clock $clk_name -max 2.5 [get_ports data_in*]
set_input_delay -clock $clk_name -min 0.5 [get_ports data_in*]

# 设置输出延迟
set_output_delay -clock $clk_name -max 3.0 [get_ports data_out*]
set_output_delay -clock $clk_name -min -0.5 [get_ports data_out*]

# 设置时钟不确定性
set_clock_uncertainty -setup 0.2 [get_clocks $clk_name]
set_clock_uncertainty -hold 0.1 [get_clocks $clk_name]

# 设置伪路径
set_false_path -from [get_ports reset_n] -to [all_registers]

# 设置多周期路径
set_multicycle_path -setup 2 -from [get_pins u_fifo/wr_en] -to [get_pins u_fifo/rd_en]

# 设置最大转换时间
set_max_transition 0.5 [all_inputs]

# 设置最大电容
set_max_capacitance 0.2 [all_outputs]

# 设置案例分析
set_case_analysis 0 [get_ports test_mode]

# 设置时钟门控检查
set_clock_gating_check -setup 0.5 -hold 0.2 [get_cells *clk_gate*]

# 设置驱动单元
set_driving_cell -lib_cell BUFX2 [all_inputs]

# 设置负载
set_load 0.05 [all_outputs]

# 设置输入转换时间
set_input_transition -max 0.2 [all_inputs]

# 禁用时序弧
set_disable_timing -from A -to Y [get_lib_cells */INV*]
