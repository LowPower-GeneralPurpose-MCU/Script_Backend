############################################################
## MCU functional timing constraints
## Genus units: ps / fF
############################################################

set_units -time 1.0ps -capacitance 1.0fF

proc sdc_env_number {name default_value} {
    if {![info exists ::env($name)] || $::env($name) eq ""} {
        return $default_value
    }
    if {![string is double -strict $::env($name)] ||
        $::env($name) <= 0.0} {
        error "SDC environment variable $name must be positive"
    }
    return [expr {double($::env($name))}]
}

proc sdc_env_number_nonneg {name default_value} {
    if {![info exists ::env($name)] || $::env($name) eq ""} {
        return $default_value
    }
    if {![string is double -strict $::env($name)] ||
        $::env($name) < 0.0} {
        error "SDC environment variable $name must not be negative"
    }
    return [expr {double($::env($name))}]
}

proc require_scalar_port {name} {
    set obj [get_ports $name]
    if {[sizeof_collection $obj] != 1} {
        error "SDC requires scalar top port $name"
    }
    return $obj
}

############################################################
## Clock uncertainty
##
## Setup uncertainty scales with the period but is capped. Hold uncertainty
## must NOT scale with the period: it models clock skew + jitter only.
## The previous single 'set_clock_uncertainty [0.05 * period]' applied to
## setup AND hold produced
##   CLK_UART      1000 ps hold uncertainty
##   CLK_I2C       5000 ps hold uncertainty
##   CLK_RTC    1526670 ps (1.53 us) hold uncertainty
## which no amount of buffer insertion in Innovus can ever meet.
############################################################

set UNC_SETUP_RATIO  [sdc_env_number MCU_UNC_SETUP_RATIO    0.05]
set UNC_SETUP_CAP_PS [sdc_env_number MCU_UNC_SETUP_CAP_PS  150.0]
set UNC_HOLD_PS      [sdc_env_number MCU_UNC_HOLD_PS        40.0]

proc apply_clock_uncertainty {clk_obj period} {
    global UNC_SETUP_RATIO UNC_SETUP_CAP_PS UNC_HOLD_PS
    set setup_unc [expr {$UNC_SETUP_RATIO * $period}]
    if {$setup_unc > $UNC_SETUP_CAP_PS} {
        set setup_unc $UNC_SETUP_CAP_PS
    }
    set_clock_uncertainty -setup $setup_unc  $clk_obj
    set_clock_uncertainty -hold  $UNC_HOLD_PS $clk_obj
}

proc make_primary_clock {name port period {phase 0.0}} {
    set port_obj [require_scalar_port $port]
    create_clock \
        -name $name \
        -period $period \
        -waveform [list $phase [expr {$phase + $period / 2.0}]] \
        $port_obj
    set clk_obj [get_clocks $name]
    set_clock_transition -min 10.0 $clk_obj
    set_clock_transition -max 40.0 $clk_obj
    apply_clock_uncertainty $clk_obj $period
    set_clock_latency -source -early 100.0 $clk_obj
    set_clock_latency -source -late 150.0 $clk_obj
}

proc make_gated_clock {name source_port output_pin period} {
    set source_obj [require_scalar_port $source_port]
    set pin_obj [get_pins $output_pin]
    if {[sizeof_collection $pin_obj] != 1} {
        error "Cannot find clock-gate output pin $output_pin"
    }
    create_generated_clock \
        -name $name \
        -source $source_obj \
        -divide_by 1 \
        $pin_obj
    # A generated clock does NOT inherit the master clock uncertainty. Without
    # this the whole CLK_CPU domain - which owns the critical path - was
    # analysed with zero uncertainty.
    apply_clock_uncertainty [get_clocks $name] $period
}

# Source-synchronous forwarded clock: the chip only re-drives an externally
# supplied clock onto an output pad, it clocks no flop of its own.
proc make_forwarded_clock {name source_port output_port period} {
    set source_obj [require_scalar_port $source_port]
    set out_obj    [require_scalar_port $output_port]
    create_generated_clock \
        -name $name \
        -source $source_obj \
        -divide_by 1 \
        $out_obj
    apply_clock_uncertainty [get_clocks $name] $period
}

############################################################
## Clock definitions
############################################################

# Defaults follow the frequency comments on top_soc. Override from the shell
# without editing this file, for example MCU_CLK_CORE_PS=3000.
set P_CORE  [sdc_env_number MCU_CLK_CORE_PS       2500.0]
set P_AXI   [sdc_env_number MCU_CLK_AXI_PS        5000.0]
set P_APB   [sdc_env_number MCU_CLK_APB_PS       10000.0]
set P_SDRAM [sdc_env_number MCU_CLK_SDRAM_PS      5000.0]
set P_UART  [sdc_env_number MCU_CLK_UART_PS      20000.0]
set P_SPI   [sdc_env_number MCU_CLK_SPI_PS       20000.0]
set P_I2C   [sdc_env_number MCU_CLK_I2C_PS      100000.0]
set P_RTC   [sdc_env_number MCU_CLK_RTC_PS    30517578.0]
set P_TCK   [sdc_env_number MCU_CLK_TCK_PS      100000.0]

# clk_sdram_ext is a board-supplied copy of the AXI clock, phase shifted so
# the external SDRAM samples in the middle of the data eye. top_soc clocks no
# flop with it; it only forwards it to the sdram_clk pad (top_soc.v line 63),
# which is why CLK_SDRAM reported 'No paths' in reports/qor_syn.rpt and showed
# up as an ineffective exception in reports/timing_intent_post_syn.rpt.
#
# ASSUMPTION: the board derives clk_axi and clk_sdram_ext from the same PLL.
# That is the only configuration in which a phase shift is meaningful and the
# only one in which this interface can be timed at all, so CLK_SDRAM shares a
# synchronous clock group with CLK_AXI below. If the two sources are genuinely
# independent, put CLK_SDRAM/CLK_SDRAM_OUT back into their own -group and
# close the interface with a resynchronising PHY instead.
#
# Default shift is half a period (180 deg), the usual choice for SDR SDRAM.
# Set MCU_CLK_SDRAM_PHASE_PS to whatever the board actually generates.
set SDRAM_PHASE [sdc_env_number_nonneg MCU_CLK_SDRAM_PHASE_PS \
    [expr {$P_SDRAM / 2.0}]]

make_primary_clock CLK_CORE  clk_core      $P_CORE
make_primary_clock CLK_AXI   clk_axi       $P_AXI
make_primary_clock CLK_APB   clk_apb       $P_APB
make_primary_clock CLK_SDRAM clk_sdram_ext $P_SDRAM $SDRAM_PHASE
make_primary_clock CLK_UART  uart_clk      $P_UART
make_primary_clock CLK_SPI   spi_clk       $P_SPI
make_primary_clock CLK_I2C   i2c_clk       $P_I2C
make_primary_clock CLK_RTC   rtc_clk       $P_RTC
make_primary_clock CLK_TCK   tck           $P_TCK

make_forwarded_clock CLK_SDRAM_OUT clk_sdram_ext sdram_clk $P_SDRAM

make_gated_clock CLK_CPU    clk_core cg_cpu/clk_out    $P_CORE
make_gated_clock CLK_DBG    clk_axi  cg_dbg/clk_out    $P_AXI
make_gated_clock CLK_PWM    clk_apb  cg_pwm/clk_out    $P_APB
make_gated_clock CLK_GPIO   clk_apb  cg_gpio/clk_out   $P_APB
make_gated_clock CLK_CORDIC clk_apb  cg_cordic/clk_out $P_APB
make_gated_clock CLK_UART_G uart_clk cg_uart/clk_out   $P_UART
make_gated_clock CLK_SPI_G  spi_clk  cg_spi/clk_out    $P_SPI
make_gated_clock CLK_I2C_G  i2c_clk  cg_i2c/clk_out    $P_I2C

set_clock_gating_check -setup 50.0 -hold 50.0 \
    [get_clocks {CLK_CPU CLK_DBG CLK_PWM CLK_GPIO CLK_CORDIC \
        CLK_UART_G CLK_SPI_G CLK_I2C_G}]

# No phase relationship is guaranteed between the remaining top-level clock
# ports. The RTL contains explicit CDC bridges/synchronizers between them.
# CLK_SDRAM and CLK_SDRAM_OUT sit in the CLK_AXI group on purpose - see the
# assumption documented above.
set_clock_groups -asynchronous \
    -group [get_clocks {CLK_CORE CLK_CPU}] \
    -group [get_clocks {CLK_AXI CLK_DBG CLK_SDRAM CLK_SDRAM_OUT}] \
    -group [get_clocks {CLK_APB CLK_PWM CLK_GPIO CLK_CORDIC}] \
    -group [get_clocks {CLK_UART CLK_UART_G}] \
    -group [get_clocks {CLK_SPI CLK_SPI_G}] \
    -group [get_clocks {CLK_I2C CLK_I2C_G}] \
    -group [get_clocks {CLK_RTC}] \
    -group [get_clocks {CLK_TCK}]

############################################################
## Port environment
############################################################

set CLOCK_PORTS [get_ports {
    clk_core clk_axi clk_apb clk_sdram_ext
    uart_clk spi_clk i2c_clk rtc_clk tck
}]
set RESET_PORTS [get_ports {rst_n trst_n}]
set NON_DATA_INPUTS [add_to_collection $CLOCK_PORTS $RESET_PORTS]
set DATA_INPUTS [remove_from_collection [all_inputs] $NON_DATA_INPUTS]

if {[sizeof_collection $DATA_INPUTS] > 0} {
    set_input_transition -min 10.0 $DATA_INPUTS
    set_input_transition -max 40.0 $DATA_INPUTS
}
set_input_transition -min 10.0 $RESET_PORTS
set_input_transition -max 40.0 $RESET_PORTS

# rst_n and trst_n are external asynchronous resets: no timing relationship to
# any clock exists at the port. This exception only removes port -> reset
# synchronizer paths. Recovery/removal from the synchronizer outputs into the
# rest of the design starts at a flop, not at the port, so it stays timed.
set_false_path -from $RESET_PORTS

proc constrain_input_ports {patterns clock_name period} {
    set ports [get_ports $patterns]
    if {[sizeof_collection $ports] == 0} {
        return
    }
    set_input_delay -clock $clock_name -max [expr {0.25 * $period}] $ports
    set_input_delay -clock $clock_name -min [expr {0.10 * $period}] $ports
}

proc constrain_output_ports {patterns clock_name period} {
    set ports [get_ports $patterns]
    if {[sizeof_collection $ports] == 0} {
        return
    }
    set_output_delay -clock $clock_name -max [expr {0.30 * $period}] $ports
    set_output_delay -clock $clock_name -min [expr {0.15 * $period}] $ports
}

constrain_input_ports  {tms tdi}                         CLK_TCK  $P_TCK
constrain_output_ports {tdo}                             CLK_TCK  $P_TCK
constrain_input_ports  {uart_rx}                         CLK_UART $P_UART
constrain_output_ports {uart_tx}                         CLK_UART $P_UART
constrain_input_ports  {spi_miso}                        CLK_SPI  $P_SPI
constrain_output_ports {spi_sck spi_mosi spi_ss}         CLK_SPI  $P_SPI
constrain_input_ports  {i2c_scl_i i2c_sda_i}             CLK_I2C  $P_I2C
constrain_output_ports {i2c_scl_o i2c_scl_oe \
    i2c_sda_o i2c_sda_oe}                                CLK_I2C  $P_I2C
constrain_input_ports  {gpio_in*}                        CLK_APB  $P_APB
constrain_output_ports {gpio_out* gpio_oe* pwm_out}      CLK_APB  $P_APB
constrain_input_ports  {flash_io_i*}                     CLK_AXI  $P_AXI
constrain_output_ports {flash_sck flash_cs_n flash_io_o* \
    flash_io_oe*}                                        CLK_AXI  $P_AXI

# External SDRAM interface. Command, address and write data are launched by
# clk_axi inside the chip but captured by the SDRAM device on the forwarded
# sdram_clk, so they are referenced to CLK_SDRAM_OUT and not to CLK_AXI.
# sdram_clk itself is a clock port and no longer carries a set_output_delay.
#
# PLACEHOLDER RATIOS: 0.30/0.15 and 0.25/0.10 of the period are the same
# provisional numbers this file uses for every other interface. Replace them
# with the real tSU/tH (outputs) and tAC/tOH (sdram_dq_i) from the SDRAM
# datasheet before signoff; at 200 MHz a real SDR part normally also needs a
# multicycle read capture.
constrain_output_ports {sdram_cke sdram_cs_n sdram_ras_n \
    sdram_cas_n sdram_we_n sdram_ba* sdram_addr* \
    sdram_dq_o* sdram_dq_oe sdram_dqm*}                  CLK_SDRAM_OUT $P_SDRAM
constrain_input_ports  {sdram_dq_i*}                     CLK_SDRAM_OUT $P_SDRAM

if {[sizeof_collection [all_outputs]] > 0} {
    set_load 10.0 -pin_load [all_outputs]
}

############################################################
## Design rules
##
## The SRAM macro data/control pins carry a 320 ps Liberty max-transition, so
## 300 ps is the ceiling the whole design must respect. It is NOT a sensible
## target for the fast domains: at CLK_CPU = 2500 ps it let synthesis leave
## 218 ps and 220 ps transitions on two consecutive NOR2xp33 gates of the
## divider critical path (reports/timing_syn.rpt), burning 251 ps of the
## 2489 ps budget on two minimum-size cells.
############################################################

set MAX_TRAN_CEIL_PS [sdc_env_number MCU_MAX_TRAN_CEIL_PS 300.0]
set MAX_TRAN_FAST_PS [sdc_env_number MCU_MAX_TRAN_FAST_PS 100.0]
set MAX_TRAN_MED_PS  [sdc_env_number MCU_MAX_TRAN_MED_PS  150.0]
set MAX_TRAN_SLOW_PS [sdc_env_number MCU_MAX_TRAN_SLOW_PS 250.0]

set_max_fanout 20 [current_design]
set_max_transition $MAX_TRAN_CEIL_PS [current_design]

# Per-domain tightening. If this Genus version rejects set_max_transition on
# clock objects it lands in reports/failed_sdc_commands.rpt; the fallback is a
# single tighter value on [current_design].
set_max_transition $MAX_TRAN_FAST_PS [get_clocks {CLK_CORE CLK_CPU}]
set_max_transition $MAX_TRAN_MED_PS \
    [get_clocks {CLK_AXI CLK_DBG CLK_SDRAM CLK_SDRAM_OUT}]
set_max_transition $MAX_TRAN_SLOW_PS \
    [get_clocks {CLK_APB CLK_PWM CLK_GPIO CLK_CORDIC \
        CLK_UART CLK_UART_G CLK_SPI CLK_SPI_G \
        CLK_I2C CLK_I2C_G CLK_RTC CLK_TCK}]

puts "INFO: MCU SDC loaded with 9 primary, 1 forwarded and 8 gated clocks"
