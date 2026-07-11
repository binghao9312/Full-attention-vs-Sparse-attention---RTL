set NAME "sparse_attention_core"

set RTL_FILE [list \
    "../../Rtl/qk_dot_accumulator.v" \
    "../../Rtl/qkv_feature_mem.v" \
    "../../Rtl/pattern_controller.v" \
    "../../Rtl/KV_LBV2.v" \
    "../../Rtl/qk_pair_streamer.v" \
    "../../Rtl/stats_counter.v" \
    "../../Rtl/sparse_attention_core.v" \
]
set SDC_FILE   "${NAME}.sdc"
set WRITE_NAME "${NAME}_syn"
set ELAB_NAME  "${NAME}_SEQ_LEN128"

source .synopsys_dc.setup
analyze -format verilog ${RTL_FILE}
elaborate ${NAME} -parameters "SEQ_LEN=128"
current_design ${ELAB_NAME}
if {![link]} {
    echo "ERROR: Failed to resolve all design references."
    exit 1
}
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
