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

proc require_scalar_port {name} {
    set obj [get_ports $name]
    if {[sizeof_collection $obj] != 1} {
        error "SDC requires scalar top port $name"
    }
    return $obj
}

proc make_primary_clock {name port period} {
    set port_obj [require_scalar_port $port]
    create_clock \
        -name $name \
        -period $period \
        -waveform [list 0.0 [expr {$period / 2.0}]] \
        $port_obj
    set clk_obj [get_clocks $name]
    set_clock_transition -min 10.0 $clk_obj
    set_clock_transition -max 40.0 $clk_obj
    set_clock_uncertainty [expr {0.05 * $period}] $clk_obj
    set_clock_latency -source -early 100.0 $clk_obj
    set_clock_latency -source -late 150.0 $clk_obj
}

proc make_gated_clock {name source_port output_pin} {
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
}

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

make_primary_clock CLK_CORE  clk_core      $P_CORE
make_primary_clock CLK_AXI   clk_axi       $P_AXI
make_primary_clock CLK_APB   clk_apb       $P_APB
make_primary_clock CLK_SDRAM clk_sdram_ext $P_SDRAM
make_primary_clock CLK_UART  uart_clk      $P_UART
make_primary_clock CLK_SPI   spi_clk       $P_SPI
make_primary_clock CLK_I2C   i2c_clk       $P_I2C
make_primary_clock CLK_RTC   rtc_clk       $P_RTC
make_primary_clock CLK_TCK   tck           $P_TCK

make_gated_clock CLK_CPU    clk_core cg_cpu/clk_out
make_gated_clock CLK_DBG    clk_axi  cg_dbg/clk_out
make_gated_clock CLK_PWM    clk_apb  cg_pwm/clk_out
make_gated_clock CLK_GPIO   clk_apb  cg_gpio/clk_out
make_gated_clock CLK_CORDIC clk_apb  cg_cordic/clk_out
make_gated_clock CLK_UART_G uart_clk cg_uart/clk_out
make_gated_clock CLK_SPI_G  spi_clk  cg_spi/clk_out
make_gated_clock CLK_I2C_G  i2c_clk  cg_i2c/clk_out

set_clock_gating_check -setup 50.0 -hold 50.0 \
    [get_clocks {CLK_CPU CLK_DBG CLK_PWM CLK_GPIO CLK_CORDIC \
        CLK_UART_G CLK_SPI_G CLK_I2C_G}]

# No phase relationship is guaranteed at the top-level clock ports. The RTL
# contains explicit CDC bridges/synchronizers between these domains.
set_clock_groups -asynchronous \
    -group [get_clocks {CLK_CORE CLK_CPU}] \
    -group [get_clocks {CLK_AXI CLK_DBG}] \
    -group [get_clocks {CLK_APB CLK_PWM CLK_GPIO CLK_CORDIC}] \
    -group [get_clocks {CLK_SDRAM}] \
    -group [get_clocks {CLK_UART CLK_UART_G}] \
    -group [get_clocks {CLK_SPI CLK_SPI_G}] \
    -group [get_clocks {CLK_I2C CLK_I2C_G}] \
    -group [get_clocks {CLK_RTC}] \
    -group [get_clocks {CLK_TCK}]

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
constrain_output_ports {spi_sck spi_mosi spi_ss}          CLK_SPI  $P_SPI
constrain_input_ports  {i2c_scl i2c_sda}                 CLK_I2C  $P_I2C
constrain_output_ports {i2c_scl i2c_sda}                 CLK_I2C  $P_I2C
constrain_input_ports  {gpio_in*}                        CLK_APB  $P_APB
constrain_output_ports {gpio_out* gpio_oe* pwm_out}       CLK_APB  $P_APB
constrain_input_ports  {flash_io* sdram_dq*}              CLK_AXI  $P_AXI
constrain_output_ports {flash_sck flash_cs_n flash_io*}   CLK_AXI  $P_AXI
constrain_output_ports {sdram_clk sdram_cke sdram_cs_n \
    sdram_ras_n sdram_cas_n sdram_we_n sdram_ba* \
    sdram_addr* sdram_dq* sdram_dqm*}                     CLK_AXI  $P_AXI

if {[sizeof_collection [all_outputs]] > 0} {
    set_load 10.0 -pin_load [all_outputs]
}

set_max_fanout 20 [current_design]
set_max_transition 300.0 [current_design]

puts "INFO: MCU SDC loaded with 9 primary and 8 generated clocks"

