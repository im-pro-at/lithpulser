#------------------------------------------------------------------------------------
#-- Company: im-pro.at
#-- Engineer: Patrick Knöbel
#--
#--   GNU GENERAL PUBLIC LICENSE Version 3
#--
#------------------------------------------------------------------------------------

### CLK in
create_clock -period 8.000 -name adc_clk [get_ports clk_i_p]
set_property IOSTANDARD DIFF_HSTL_I_18 [get_ports clk_i_p]
set_property IOSTANDARD DIFF_HSTL_I_18 [get_ports clk_i_n]
set_property PACKAGE_PIN U18 [get_ports clk_i_p]
set_property PACKAGE_PIN U19 [get_ports clk_i_n]

# ADC minimal config
set_property IOSTANDARD LVCMOS18 [get_ports {adc_clk_o[*]}]
set_property SLEW FAST [get_ports {adc_clk_o[*]}]
set_property DRIVE 8 [get_ports {adc_clk_o[*]}]
set_property PACKAGE_PIN N20 [get_ports {adc_clk_o[0]}]
set_property PACKAGE_PIN P20 [get_ports {adc_clk_o[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports adc_cdcs_o]
set_property PACKAGE_PIN V18 [get_ports adc_cdcs_o]
set_property SLEW FAST [get_ports adc_cdcs_o]
set_property DRIVE 8 [get_ports adc_cdcs_o]

### inputs
set_property IOSTANDARD LVCMOS33 [get_ports {inputs[*]}]
set_property IOB TRUE [get_ports {inputs[*]}]
set_property PULLDOWN TRUE [get_ports {inputs[*]}]
set_property PACKAGE_PIN G18 [get_ports {inputs[0]}]
set_property PACKAGE_PIN H17 [get_ports {inputs[1]}]

### outputs
set_property IOSTANDARD LVCMOS33 [get_ports {outputs[*]}]
set_property SLEW FAST [get_ports {outputs[*]}]
set_property DRIVE 8 [get_ports {outputs[*]}]
set_property PACKAGE_PIN G17 [get_ports {outputs[0]}]
set_property PACKAGE_PIN H16 [get_ports {outputs[1]}]
set_property PACKAGE_PIN J18 [get_ports {outputs[2]}]
set_property PACKAGE_PIN K17 [get_ports {outputs[3]}]
set_property PACKAGE_PIN L14 [get_ports {outputs[4]}]
set_property PACKAGE_PIN L16 [get_ports {outputs[5]}]
set_property PACKAGE_PIN K16 [get_ports {outputs[6]}]
set_property PACKAGE_PIN M14 [get_ports {outputs[7]}]
set_property PACKAGE_PIN H18 [get_ports {outputs[8]}]
set_property PACKAGE_PIN K18 [get_ports {outputs[9]}]
set_property PACKAGE_PIN L15 [get_ports {outputs[10]}]
set_property PACKAGE_PIN L17 [get_ports {outputs[11]}]
set_property PACKAGE_PIN J16 [get_ports {outputs[12]}]
set_property PACKAGE_PIN M15 [get_ports {outputs[13]}]

### LEDs
set_property IOSTANDARD LVCMOS33 [get_ports {led_o[*]}]
set_property SLEW SLOW [get_ports {led_o[*]}]
set_property DRIVE 4 [get_ports {led_o[*]}]
set_property PACKAGE_PIN F16 [get_ports {led_o[0]}]
set_property PACKAGE_PIN F17 [get_ports {led_o[1]}]
set_property PACKAGE_PIN G15 [get_ports {led_o[2]}]
set_property PACKAGE_PIN H15 [get_ports {led_o[3]}]
set_property PACKAGE_PIN K14 [get_ports {led_o[4]}]
set_property PACKAGE_PIN G14 [get_ports {led_o[5]}]
set_property PACKAGE_PIN J15 [get_ports {led_o[6]}]
set_property PACKAGE_PIN J14 [get_ports {led_o[7]}]








