############################################################
## Deterministic MCU RTL order
############################################################

set RTL_INCLUDE_DIRS [list \
    $RTL_ROOT \
    [file join $RTL_ROOT interrupt CLINT] \
    [file join $RTL_ROOT interrupt dma]]

# 2026-09-11: SoC chuyen sang MOT clock. bin_gray_convert.v, fifo_async.v,
# apb_async_bridge.v va axi_async_bridge.v khong con duoc instantiate o dau
# nen da rut khoi danh sach (58 -> 54 file). File van nam tren dia.
# Cung ngay: kenh doc AXI bo ROB, dung FIFO thu tu nhu kenh ghi (xem
# dsp_read_channel), nen utils/ROB.v cung rut ra (54 -> 53).
# 2026-09-11 (muc 6/7/8 review): PLIC thay bang CLIC (3 file plic rut ra, van
# tren dia), them pmp_unit.v, clic.v, apb_timer.v, apb_pinmux.v (53 -> 54).
set RTL_FILES [list \
    [file join $RTL_ROOT utils cdc_bridge.v] \
    [file join $RTL_ROOT utils clock_gate.v] \
    [file join $RTL_ROOT utils fifo_sync.v] \
    [file join $RTL_ROOT utils utils_axi_interconnect.v] \
    [file join $RTL_ROOT utils utils_dma.v] \
    [file join $RTL_ROOT bus apb_interconnect apb_interconnect.v] \
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
    [file join $RTL_ROOT core block_unit pmp_unit.v] \
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
    [file join $RTL_ROOT interrupt clic clic.v] \
    [file join $RTL_ROOT memory asap7_sram_1rw.v] \
    [file join $RTL_ROOT memory cache_sram_array.v] \
    [file join $RTL_ROOT memory axi_ram.v] \
    [file join $RTL_ROOT memory tcm.v] \
    [file join $RTL_ROOT memory axi_rom.v] \
    [file join $RTL_ROOT memory axi_sdram_controller.v] \
    [file join $RTL_ROOT memory axi_spi_flash.v] \
    [file join $RTL_ROOT memory dcache.v] \
    [file join $RTL_ROOT memory icache.v] \
    [file join $RTL_ROOT peripheral apb_cordic.v] \
    [file join $RTL_ROOT peripheral apb_gpio.v] \
    [file join $RTL_ROOT peripheral apb_i2c.v] \
    [file join $RTL_ROOT peripheral apb_pinmux.v] \
    [file join $RTL_ROOT peripheral apb_pwm.v] \
    [file join $RTL_ROOT peripheral apb_spi.v] \
    [file join $RTL_ROOT peripheral apb_syscon.v] \
    [file join $RTL_ROOT peripheral apb_timer.v] \
    [file join $RTL_ROOT peripheral apb_uart.v] \
    [file join $RTL_ROOT peripheral apb_watchdog.v] \
    [file join $RTL_ROOT apb_ascon trng_128b.v] \
    [file join $RTL_ROOT apb_ascon ascon_core.v] \
    [file join $RTL_ROOT apb_ascon apb_ascon.v] \
    [file join $RTL_ROOT top_soc.v]]

foreach rtl_file $RTL_FILES {
    if {![file isfile $rtl_file]} {
        error "Missing RTL source: [file normalize $rtl_file]"
    }
}

