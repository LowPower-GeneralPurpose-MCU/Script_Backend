############################################################
## Deterministic MCU RTL order
############################################################

set RTL_INCLUDE_DIRS [list \
    $RTL_ROOT \
    [file join $RTL_ROOT interrupt CLINT] \
    [file join $RTL_ROOT interrupt dma] \
    [file join $RTL_ROOT interrupt plic]]

set RTL_FILES [list \
    [file join $RTL_ROOT utils bin_gray_convert.v] \
    [file join $RTL_ROOT utils cdc_bridge.v] \
    [file join $RTL_ROOT utils clock_gate.v] \
    [file join $RTL_ROOT utils fifo_async.v] \
    [file join $RTL_ROOT utils fifo_sync.v] \
    [file join $RTL_ROOT utils ROB.v] \
    [file join $RTL_ROOT utils utils_axi_interconnect.v] \
    [file join $RTL_ROOT utils utils_dma.v] \
    [file join $RTL_ROOT bus apb_interconnect apb_async_bridge.v] \
    [file join $RTL_ROOT bus apb_interconnect apb_interconnect.v] \
    [file join $RTL_ROOT bus axi_interconnect axi_async_bridge.v] \
    [file join $RTL_ROOT bus axi_interconnect axi_dispatcher_channel.v] \
    [file join $RTL_ROOT bus axi_interconnect axi_slave_arbitration.v] \
    [file join $RTL_ROOT bus axi_interconnect axi_interconnect.v] \
    [file join $RTL_ROOT bus axi_to_apb_bridge.v] \
    [file join $RTL_ROOT core block_unit branch_prediction_unit.v] \
    [file join $RTL_ROOT core block_unit control_unit.v] \
    [file join $RTL_ROOT core block_unit floating_point_unit.v] \
    [file join $RTL_ROOT core block_unit forwarding_unit.v] \
    [file join $RTL_ROOT core block_unit multiplier_divider_unit.v] \
    [file join $RTL_ROOT core block_unit pipeline_control_unit.v] \
    [file join $RTL_ROOT core pipeline_register pipeline_register.v] \
    [file join $RTL_ROOT core pipeline_stage pipeline_stage.v] \
    [file join $RTL_ROOT core register_file register_file.v] \
    [file join $RTL_ROOT core riscv_pipeline.v] \
    [file join $RTL_ROOT debug dtm_axi_master.v] \
    [file join $RTL_ROOT debug rv_debug_module_sba.v] \
    [file join $RTL_ROOT debug rv_jtag_dtm.v] \
    [file join $RTL_ROOT interrupt CLINT clint_core.v] \
    [file join $RTL_ROOT interrupt CLINT clint_reg_bus.v] \
    [file join $RTL_ROOT interrupt CLINT clint.v] \
    [file join $RTL_ROOT interrupt dma dma_axi_master.v] \
    [file join $RTL_ROOT interrupt dma dma_core.v] \
    [file join $RTL_ROOT interrupt dma dma.v] \
    [file join $RTL_ROOT interrupt plic plic_core.v] \
    [file join $RTL_ROOT interrupt plic plic_reg_bus.v] \
    [file join $RTL_ROOT interrupt plic plic.v] \
    [file join $RTL_ROOT memory asap7_sram_128k_1rw.v] \
    [file join $RTL_ROOT memory axi_ram.v] \
    [file join $RTL_ROOT memory axi_rom.v] \
    [file join $RTL_ROOT memory axi_sdram_controller.v] \
    [file join $RTL_ROOT memory axi_spi_flash.v] \
    [file join $RTL_ROOT memory dcache.v] \
    [file join $RTL_ROOT memory icache.v] \
    [file join $RTL_ROOT peripheral apb_cordic.v] \
    [file join $RTL_ROOT peripheral apb_gpio.v] \
    [file join $RTL_ROOT peripheral apb_i2c.v] \
    [file join $RTL_ROOT peripheral apb_pwm.v] \
    [file join $RTL_ROOT peripheral apb_spi.v] \
    [file join $RTL_ROOT peripheral apb_syscon.v] \
    [file join $RTL_ROOT peripheral apb_uart.v] \
    [file join $RTL_ROOT peripheral apb_watchdog.v] \
    [file join $RTL_ROOT top_soc.v]]

foreach rtl_file $RTL_FILES {
    if {![file isfile $rtl_file]} {
        error "Missing RTL source: [file normalize $rtl_file]"
    }
}

