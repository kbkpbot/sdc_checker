# =============================================================================
# SDC 全面测试文件（修正版）
# 覆盖 OpenSTA 支持的各种正确 SDC 命令格式
# 使用引号包裹包含单位的值
# =============================================================================

# -----------------------------------------------------------------------------
# 1. 基本环境设置
# -----------------------------------------------------------------------------

# 设置层次分隔符
set_hierarchy_separator "/"
set_hierarchy_separator "."
set_hierarchy_separator "|"

# 设置单位（使用引号包裹带单位的值）
set_units -time "1ns"
set_units -capacitance "1pf"
set_units -resistance "1kohm"
set_units -voltage "1V"
set_units -current "1mA"
set_units -power "1nW"
set_units -distance "1um"

# -----------------------------------------------------------------------------
# 2. 时钟定义
# -----------------------------------------------------------------------------

# 基本时钟创建
create_clock -period 10.0 -name clk [get_ports clk]
create_clock -period 5.0 [get_ports clk_fast]
create_clock -period 20.0 -name clk_slow -waveform "{0 10}" [get_ports clk_slow]

# 添加时钟（-add 标志）
create_clock -period 10.0 -name clk1 [get_pins clk]
create_clock -period 5.0 -name clk2 -add [get_pins clk]

# 生成时钟
create_generated_clock -source [get_ports clk] -divide_by 2 [get_pins div_clk]
create_generated_clock -source clk -multiply_by 2 [get_pins mul_clk]
create_generated_clock -source clk -edges "{1 3 5}" [get_pins edge_clk]
create_generated_clock -source clk -divide_by 2 -invert [get_pins inv_clk]
create_generated_clock -source clk -combinational [get_pins comb_clk]

# 时钟组
set_clock_groups -logically_exclusive -group "{clk1 clk2}" -group "{clk3 clk4}"
set_clock_groups -physically_exclusive -group clk_a -group clk_b
set_clock_groups -asynchronous -group async_clk

# 时钟属性
set_clock_latency 0.5 [get_clocks clk]
set_clock_latency -source 1.0 [get_clocks clk]
set_clock_latency 0.3 [get_pins clk_gen/clk_out]

set_clock_uncertainty 0.2 [get_clocks clk]
set_clock_uncertainty -setup 0.3 [get_clocks clk]
set_clock_uncertainty -hold 0.1 [get_clocks clk]
set_clock_uncertainty 0.25 -from clk1 -to clk2

set_clock_transition 0.1 [get_clocks clk]

set_propagated_clock [get_clocks clk]
set_propagated_clock [get_ports clk_in]

# -----------------------------------------------------------------------------
# 3. I/O 延迟约束
# -----------------------------------------------------------------------------

# 输入延迟
set_input_delay -clock clk 2.0 [get_ports data_in]
set_input_delay -clock clk -max 2.5 [get_ports data_in]
set_input_delay -clock clk -min 0.5 [get_ports data_in]
set_input_delay -clock clk -max 2.5 [get_ports data_in]
set_input_delay -clock clk -min 0.5 [get_ports data_in]
set_input_delay -clock clk -max 2.5 -clock_fall [get_ports data_in]
set_input_delay -clock clk -max 2.5 -add_delay [get_ports data_in]

# 输出延迟
set_output_delay -clock clk 3.0 [get_ports data_out]
set_output_delay -clock clk -max 3.5 [get_ports data_out]
set_output_delay -clock clk -min -0.5 [get_ports data_out]

# -----------------------------------------------------------------------------
# 4. 时序例外
# -----------------------------------------------------------------------------

# 伪路径
set_false_path -from [get_clocks clk1] -to [get_clocks clk2]
set_false_path -from [get_pins reg1/clk] -to [get_pins reg2/d]
set_false_path -through [get_pins u_mux/*]
set_false_path -from [get_ports rst]
set_false_path -to [get_ports test_out]
set_false_path -setup -from [get_pins a] -to [get_pins b]
set_false_path -hold -from [get_pins a] -to [get_pins b]
set_false_path -rise -from [get_pins a] -to [get_pins b]
set_false_path -fall -from [get_pins a] -to [get_pins b]

# 多周期路径
set_multicycle_path 2 -from [get_pins reg1/*] -to [get_pins reg2/*]
set_multicycle_path 3 -setup -from [get_pins a] -to [get_pins b]
set_multicycle_path 2 -hold -from [get_pins a] -to [get_pins b]
set_multicycle_path 2 -start -from [get_pins a] -to [get_pins b]
set_multicycle_path 2 -end -from [get_pins a] -to [get_pins b]

# 最大/最小延迟
set_max_delay 10.0 -from [get_pins a] -to [get_pins b]
set_max_delay 5.0 -from [get_clocks clk1] -to [get_clocks clk2]
set_min_delay 1.0 -from [get_pins a] -to [get_pins b]
set_max_delay -ignore_clock_latency 8.0 -from [get_pins a] -to [get_pins b]

# -----------------------------------------------------------------------------
# 5. 设计规则约束
# -----------------------------------------------------------------------------

# 转换时间
set_max_transition 0.5 [get_ports *]
set_max_transition 0.3 -rise [get_pins *]
set_max_transition 0.3 -fall [get_pins *]
set_max_transition 0.4 [all_inputs]
set_max_transition 0.4 [all_outputs]

# 电容
set_max_capacitance 0.2 [get_ports *]
set_max_capacitance 0.15 [all_outputs]

# 扇出
set_max_fanout 20 [get_ports *]
set_max_fanout 10 [all_inputs]

# 最小脉宽
set_min_pulse_width 2.0 [get_clocks clk]
set_min_pulse_width -low 1.5 [get_clocks clk]
set_min_pulse_width -high 1.5 [get_clocks clk]

# 输入转换时间
set_input_transition 0.1 [all_inputs]
set_input_transition -max 0.2 [get_ports data*]
set_input_transition -min 0.05 [get_ports data*]

# -----------------------------------------------------------------------------
# 6. 负载和驱动
# -----------------------------------------------------------------------------

# 负载
set_load 0.05 [get_ports out*]
set_load -min 0.02 [get_ports out*]
set_load -max 0.08 [get_ports out*]

# 驱动单元
set_driving_cell -lib_cell BUFX2 [get_ports *]
set_driving_cell -lib_cell BUFX4 -pin Z [get_ports clk]
set_driving_cell -lib_cell INVX1 -from_pin A -to_pin Y [get_ports rst]

# 驱动（电阻驱动）
set_drive 1000 [get_ports in*]
set_drive -rise 800 [get_ports data*]
set_drive -fall 1200 [get_ports data*]

# 扇出负载
set_fanout_load 1.0 [get_ports *]

# 电阻
set_resistance 10.0 [get_nets net*]
set_resistance -min 5.0 [get_nets critical_net]
set_resistance -max 15.0 [get_nets critical_net]

# -----------------------------------------------------------------------------
# 7. 时序检查和禁用
# -----------------------------------------------------------------------------

# 禁用时序弧
set_disable_timing -from A -to Y [get_cells u_buf*]
set_disable_timing [get_pins u_test/scan_enable]

# 数据检查（setup/hold 检查）
set_data_check -from [get_pins clk] -to [get_pins data] -setup 0.2
set_data_check -from [get_pins clk] -to [get_pins data] -hold 0.1

# -----------------------------------------------------------------------------
# 8. 案例分析和常量
# -----------------------------------------------------------------------------

# 案例分析
set_case_analysis 0 [get_ports rst]
set_case_analysis 1 [get_ports test_mode]
set_case_analysis 0 [get_pins u_cfg/mode_sel]

# 逻辑值
set_logic_zero [get_ports grounded*]
set_logic_one [get_ports tied*]
set_logic_dc [get_ports dont_care*]

# -----------------------------------------------------------------------------
# 9. 面积和功率
# -----------------------------------------------------------------------------

set_max_area 10000

set_max_dynamic_power 100
set_max_leakage_power 10

# -----------------------------------------------------------------------------
# 10. 工作条件和电压
# -----------------------------------------------------------------------------

set_operating_conditions -library stdcells typical
set_operating_conditions -analysis_type on_chip_variation typical

set_voltage 0.8 -object_list [get_supply_nets VDD]

# -----------------------------------------------------------------------------
# 11. 线负载模型
# -----------------------------------------------------------------------------

set_wire_load_mode top
set_wire_load_mode enclosed
set_wire_load_mode segmented

set_wire_load_model -name medium [get_designs *]
set_wire_load_model -name small -library stdcells [get_designs sub*]

set_wire_load_min_block_size 1000

set_wire_load_selection_group standard [get_designs *]

# -----------------------------------------------------------------------------
# 12. 时钟门控检查
# -----------------------------------------------------------------------------

set_clock_gating_check -setup 0.2 [get_cells u_gate*]
set_clock_gating_check -hold 0.1 [get_cells u_gate*]
set_clock_gating_check -high [get_cells u_gate*]
set_clock_gating_check -low [get_cells u_gate*]

# -----------------------------------------------------------------------------
# 13. 时序减额
# -----------------------------------------------------------------------------

set_timing_derate -early 0.95
set_timing_derate -late 1.05
set_timing_derate -early 0.98 -cell_delay
set_timing_derate -late 1.02 -cell_delay
set_timing_derate -early 0.97 -net_delay
set_timing_derate -late 1.03 -net_delay

# =============================================================================
# 测试文件结束
# =============================================================================
