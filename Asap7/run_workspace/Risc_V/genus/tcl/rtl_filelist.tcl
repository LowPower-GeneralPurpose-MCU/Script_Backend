# Deterministic RTL order for riscv_pipeline synthesis.
set RTL_FILES [list \
    ./rtl/control_unit.v \
    ./rtl/forwarding_unit.v \
    ./rtl/multiplier_divider_unit.v \
    ./rtl/floating_point_unit.v \
    ./rtl/branch_prediction_unit.v \
    ./rtl/pipeline_control_unit.v \
    ./rtl/pipeline_register.v \
    ./rtl/pipeline_stage.v \
    ./rtl/register_file.v \
    ./rtl/riscv_pipeline.v]

foreach rtl_file $RTL_FILES {
    if {![file isfile $rtl_file]} {
        error "Missing RTL source: $rtl_file"
    }
}
