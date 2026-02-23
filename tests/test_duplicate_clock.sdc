# 测试重复时钟定义
create_clock -period 10.0 -name clk [get_ports clk_in]

# 重复定义同名时钟（应该报错）
create_clock -period 20.0 -name clk [get_ports clk_in2]