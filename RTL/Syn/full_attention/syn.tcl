set NAME "full_attention_core"

set RTL_FILE [list \
    "../../Rtl/qk_dot_product.v" \
    "../../Rtl/full_attention_core.v" \
]
set SDC_FILE   "${NAME}.sdc"
set WRITE_NAME "${NAME}_syn"

source .synopsys_dc.setup
read_verilog ${RTL_FILE}

current_design ${NAME}
link
source ${SDC_FILE}
set_fix_multiple_port_nets -all -buffer_constants [get_designs *]
set verilogout_no_tri true

compile

report_timing -delay_type max >> setup_timing_max.txt
report_timing -delay_type min >> setup_timing_min.txt
report_area >> area.txt

write -hierarchy -format verilog -output ${WRITE_NAME}.v
write_sdf -version 2.5 -context verilog ${WRITE_NAME}.sdf
write -hierarchy -format ddc -output ${WRITE_NAME}.ddc
