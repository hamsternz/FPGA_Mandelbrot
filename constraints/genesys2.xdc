########################################################
## System clocks
########################################################
set_property -dict {PACKAGE_PIN AD12 IOSTANDARD LVDS} [get_ports clk200_p]
set_property -dict {PACKAGE_PIN AD11 IOSTANDARD LVDS} [get_ports clk200_n]


########################################################
## Buttons
########################################################
########################################################
set_property -dict {PACKAGE_PIN E18 IOSTANDARD LVCMOS33} [get_ports btnC]
set_property -dict {PACKAGE_PIN M19 IOSTANDARD LVCMOS33} [get_ports btnD]
set_property -dict {PACKAGE_PIN M20 IOSTANDARD LVCMOS33} [get_ports btnL]
set_property -dict {PACKAGE_PIN C19 IOSTANDARD LVCMOS33} [get_ports btnR]
set_property -dict {PACKAGE_PIN B19 IOSTANDARD LVCMOS33} [get_ports btnU]

## JA 0 through 7
set_property -dict {PACKAGE_PIN U28 IOSTANDARD LVCMOS33 PULLUP TRUE} [get_ports pmod_enc_a]
set_property -dict {PACKAGE_PIN U27 IOSTANDARD LVCMOS33 PULLUP TRUE} [get_ports pmod_enc_b]
set_property -dict {PACKAGE_PIN T27 IOSTANDARD LVCMOS33 PULLUP TRUE} [get_ports pmod_enc_btn]
set_property -dict {PACKAGE_PIN T26 IOSTANDARD LVCMOS33 PULLUP TRUE} [get_ports pmod_enc_sw]

set_property -dict {PACKAGE_PIN T22 IOSTANDARD LVCMOS33} [get_ports pmod_adc_cs]
set_property -dict {PACKAGE_PIN T23 IOSTANDARD LVCMOS33} [get_ports pmod_adc_data0]
set_property -dict {PACKAGE_PIN T20 IOSTANDARD LVCMOS33} [get_ports pmod_adc_data1]
set_property -dict {PACKAGE_PIN T21 IOSTANDARD LVCMOS33} [get_ports pmod_adc_clk]

########################################################
## HDMI TX
########################################################
set_property -dict {PACKAGE_PIN Y24 IOSTANDARD LVCMOS33} [get_ports hdmi_tx_cec]
set_property -dict {PACKAGE_PIN AB20 IOSTANDARD TMDS_33} [get_ports hdmi_tx_clk_n]
set_property -dict {PACKAGE_PIN AA20 IOSTANDARD TMDS_33} [get_ports hdmi_tx_clk_p]
set_property -dict {PACKAGE_PIN AG29 IOSTANDARD LVCMOS33} [get_ports hdmi_tx_hpd]
set_property -dict {PACKAGE_PIN AF27 IOSTANDARD LVCMOS33} [get_ports hdmi_tx_rscl]
set_property -dict {PACKAGE_PIN AF26 IOSTANDARD LVCMOS33} [get_ports hdmi_tx_rsda]
set_property IOSTANDARD TMDS_33 [get_ports {hdmi_tx_n[0]}]
set_property PACKAGE_PIN AC20 [get_ports {hdmi_tx_p[0]}]
set_property PACKAGE_PIN AC21 [get_ports {hdmi_tx_n[0]}]
set_property IOSTANDARD TMDS_33 [get_ports {hdmi_tx_p[0]}]
set_property IOSTANDARD TMDS_33 [get_ports {hdmi_tx_n[1]}]
set_property PACKAGE_PIN AA22 [get_ports {hdmi_tx_p[1]}]
set_property PACKAGE_PIN AA23 [get_ports {hdmi_tx_n[1]}]
set_property IOSTANDARD TMDS_33 [get_ports {hdmi_tx_p[1]}]
set_property IOSTANDARD TMDS_33 [get_ports {hdmi_tx_n[2]}]
set_property PACKAGE_PIN AB24 [get_ports {hdmi_tx_p[2]}]
set_property PACKAGE_PIN AC25 [get_ports {hdmi_tx_n[2]}]
set_property IOSTANDARD TMDS_33 [get_ports {hdmi_tx_p[2]}]

create_clock -period 5.000 -name tc_clk100_p -waveform {0.000 2.500} [get_ports clk200_p]
create_clock -period 5.000 -name tc_clk100_n -waveform {2.500 5.000} [get_ports clk200_n]

#set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets mmcm_clk_in]