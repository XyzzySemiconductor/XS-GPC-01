set_global_assignment -entity "out_reg" -library "lib_out_reg" -name IP_TOOL_NAME "altera_gpio_lite"
set_global_assignment -entity "out_reg" -library "lib_out_reg" -name IP_TOOL_VERSION "23.1"
set_global_assignment -entity "out_reg" -library "lib_out_reg" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_out_reg" -name SPD_FILE [file join $::quartus(sip_path) "out_reg.spd"]

set_global_assignment -library "lib_out_reg" -name MISC_FILE [file join $::quartus(sip_path) "out_reg_sim/out_reg.v"]
set_global_assignment -library "lib_out_reg" -name MISC_FILE [file join $::quartus(sip_path) "out_reg_sim/altera_gpio_lite/altera_gpio_lite.sv"]
