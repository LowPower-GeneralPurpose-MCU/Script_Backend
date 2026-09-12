############################################################
## MCU functional timing constraints
##
## MOT CLOCK (2026-09-11). SoC chay hoan toan bang `clk` 250 MHz. Ban truoc co
## 9 clock goc va xu ly moi duong giua chung bang mot `set_clock_groups
## -asynchronous` - tuc BO timing ca nhung duong van can rang buoc (con tro
## Gray cua async FIFO, bus debug tua-tinh dbg_reg_write_addr/data). RTL gio
## khong con CDC noi bo nao, nen file nay khong con clock group nao.
##
## Clock con lai:
##   CLK_SYS        clk, 4000 ps                    - clock goc duy nhat
##   CLK_CPU..TIM1  12 clock sinh tai dau ra clock_gate (-divide_by 1), DONG BO
##                  voi CLK_SYS; tach ra chi de co uncertainty + dong QoR rieng
##   CLK_SDRAM_OUT  sdram_clk = ~clk, forward ra chan
##   CLK_TCK        tck tu debugger - bat dong bo that. Duong TCK <-> DM duoc
##                  rang buoc TUONG MINH o muc "CDC duy nhat" ben duoi.
############################################################

puts "INFO: BEGIN MCU SDC"
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

############################################################
## Clock uncertainty
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

############################################################
## Source latency (tre ngoai chip toi chan clk / tck)
############################################################
# early 100 / late 150: nua chu ky capture thay 100, nua launch thay 150, nen
# moi duong reg2reg bi tru 50 ps bi quan - dong vai OCV cua nguon clock.
#
# 2026-09-13 - PHAI dat CA tren generated clock.  Genus KHONG cho generated
# clock ke thua source latency cua master: run 2026-09-12 15:21 in
# "Src Latency: 0 / 0" cho moi duong CLK_CPU, trong khi CLK_SYS co 100 / 150.
# Hau qua (cung mot clock vat ly):
#   CLK_CPU -> CLK_CPU  : thieu 50 ps bi quan so voi CLK_SYS -> CLK_SYS
#   CLK_SYS -> gated    : launch 150, capture 0 -> bi quan THUA 150 ps
#   gated   -> CLK_SYS  : launch 0, capture 100 -> lac quan 100 ps
# Duong toi han cua core (CLK_CPU) vi vay duoc tinh de hon phan con lai.
#
# Truoc CTS (Genus, Innovus pre-CTS - clock ly tuong) day la dung.  Sau CTS voi
# set_propagated_clock, cong cu tu tinh tre tu chan clk qua ICG; khi do nen
# go -source tren generated clock neu cong cu cong don thay vi thay the (kiem
# report_clock_timing o buoc CTS).
set SRC_LAT_EARLY_PS [sdc_env_number MCU_SRC_LAT_EARLY_PS 100.0]
set SRC_LAT_LATE_PS  [sdc_env_number MCU_SRC_LAT_LATE_PS  150.0]

proc apply_source_latency {clk_obj} {
    global SRC_LAT_EARLY_PS SRC_LAT_LATE_PS
    set_clock_latency -source -early $SRC_LAT_EARLY_PS $clk_obj
    set_clock_latency -source -late  $SRC_LAT_LATE_PS  $clk_obj
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
    apply_clock_uncertainty $clk_obj $period
    apply_source_latency $clk_obj
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
    # Cung ly do voi uncertainty o tren: source latency cung khong ke thua.
    apply_source_latency [get_clocks $name]
}

############################################################
## Clock definitions
############################################################

# Override tu shell khong can sua file, vi du MCU_CLK_SYS_PS=4500.
set P_SYS [sdc_env_number MCU_CLK_SYS_PS    4000.0]
set P_TCK [sdc_env_number MCU_CLK_TCK_PS  100000.0]

make_primary_clock CLK_SYS clk $P_SYS
make_primary_clock CLK_TCK tck $P_TCK

# sdram_clk = ~clk (top_soc.v): chip SDRAM chot o canh XUONG cua clk, tuc giua
# chu ky controller. Thay cho clk_sdram_ext lech pha 180 do cua ban cu.
create_generated_clock \
    -name CLK_SDRAM_OUT \
    -source [require_scalar_port clk] \
    -divide_by 1 \
    -invert \
    [require_scalar_port sdram_clk]
apply_clock_uncertainty [get_clocks CLK_SDRAM_OUT] $P_SYS
apply_source_latency    [get_clocks CLK_SDRAM_OUT]

# 9 nhanh da gate cua CLK_SYS. Khong nam trong clock group nao: moi duong giua
# chung va CLK_SYS deu duoc tinh timing day du.
make_gated_clock CLK_CPU    clk cg_cpu/clk_out    $P_SYS
make_gated_clock CLK_DBG    clk cg_dbg/clk_out    $P_SYS
make_gated_clock CLK_PWM    clk cg_pwm/clk_out    $P_SYS
make_gated_clock CLK_GPIO   clk cg_gpio/clk_out   $P_SYS
make_gated_clock CLK_CORDIC clk cg_cordic/clk_out $P_SYS
make_gated_clock CLK_ASCON  clk cg_ascon/clk_out  $P_SYS
make_gated_clock CLK_UART   clk cg_uart/clk_out   $P_SYS
make_gated_clock CLK_SPI    clk cg_spi/clk_out    $P_SYS
make_gated_clock CLK_I2C    clk cg_i2c/clk_out    $P_SYS
# 2026-09-11 - UART1, TIM0, TIM1 (muc 8). Cung mien CLK_SYS nhu 9 nhanh tren;
# chi la them doi tuong clock cho uncertainty va nhom QoR rieng.
make_gated_clock CLK_UART1  clk cg_uart1/clk_out  $P_SYS
make_gated_clock CLK_TIM0   clk cg_tim0/clk_out   $P_SYS
make_gated_clock CLK_TIM1   clk cg_tim1/clk_out   $P_SYS

set SYS_FAMILY [get_clocks {CLK_SYS CLK_CPU CLK_DBG CLK_PWM CLK_GPIO \
    CLK_CORDIC CLK_ASCON CLK_UART CLK_SPI CLK_I2C \
    CLK_UART1 CLK_TIM0 CLK_TIM1}]

set_clock_gating_check -setup 50.0 -hold 50.0 \
    [get_clocks {CLK_CPU CLK_DBG CLK_PWM CLK_GPIO CLK_CORDIC CLK_ASCON \
        CLK_UART CLK_SPI CLK_I2C CLK_UART1 CLK_TIM0 CLK_TIM1}]

############################################################
## CDC duy nhat: JTAG DMI (CLK_TCK <-> CLK_DBG)
##
## rv_jtag_dtm (tck) va rv_debug_module_sba (clk_dbg) bat tay qua dmi_req_valid
## / dmi_resp_valid, moi ben 3FF; bus dmi_req_addr/data/op va dmi_resp_data/op
## giu on dinh suot handshake. Rang buoc:
##   setup: max_delay = 1 chu ky CLK_SYS tren MOI duong giua hai mien, ca bus
##          du lieu lan tang sync dau. Bus toi dich truoc khi tin hieu valid qua
##          xong 3FF (>= 2 chu ky dich) -> tinh on dinh cua bus duoc STA dam bao
##          sau P&R, khong con la gia dinh.
##   hold:  khong co quan he pha giua hai clock -> tat kiem hold.
## KHONG dung set_clock_groups -asynchronous (no se bo luon max_delay).
############################################################

set DM_CLOCKS [get_clocks {CLK_SYS CLK_DBG}]
set_max_delay $P_SYS -from [get_clocks CLK_TCK] -to $DM_CLOCKS
set_max_delay $P_SYS -from $DM_CLOCKS -to [get_clocks CLK_TCK]
set_false_path -hold -from [get_clocks CLK_TCK] -to $DM_CLOCKS
set_false_path -hold -from $DM_CLOCKS -to [get_clocks CLK_TCK]

############################################################
## Port environment
############################################################

set CLOCK_PORTS [get_ports {clk tck}]
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

############################################################
## Rang buoc I/O theo tung giao dien
############################################################

set SDC_CONSTRAINED_INPUTS  {}
set SDC_CONSTRAINED_OUTPUTS {}

proc sdc_require_ports {patterns} {
    set collected {}
    foreach pattern $patterns {
        set ports [get_ports $pattern]
        if {[sizeof_collection $ports] == 0} {
            error "SDC: khong top port nao khop '$pattern' - danh sach port trong constraint.sdc da lech voi top_soc.v"
        }
        if {$collected eq ""} {
            set collected $ports
        } else {
            set collected [add_to_collection $collected $ports]
        }
    }
    return $collected
}

proc sdc_record_ports {var_name ports} {
    upvar #0 $var_name accumulated
    if {$accumulated eq ""} {
        set accumulated $ports
    } else {
        set accumulated [add_to_collection $accumulated $ports]
    }
}

proc constrain_input_ports {patterns clock_name period} {
    set ports [sdc_require_ports $patterns]
    set_input_delay -clock $clock_name -max [expr {0.25 * $period}] $ports
    set_input_delay -clock $clock_name -min [expr {0.10 * $period}] $ports
    sdc_record_ports SDC_CONSTRAINED_INPUTS $ports
}

proc constrain_output_ports {patterns clock_name period} {
    set ports [sdc_require_ports $patterns]
    set_output_delay -clock $clock_name -max [expr {0.30 * $period}] $ports
    set_output_delay -clock $clock_name -min [expr {0.15 * $period}] $ports
    sdc_record_ports SDC_CONSTRAINED_OUTPUTS $ports
}

constrain_input_ports  {tms tdi}                         CLK_TCK  $P_TCK
constrain_output_ports {tdo}                             CLK_TCK  $P_TCK

# 2026-09-11: UART/SPI/I2C/PWM/GPIO khong con chan rieng - tat ca di qua 32
# pad cua apb_pinmux (pad_in/pad_out/pad_oe). Duong pad -> ngoai vi van la dau
# vao bat dong bo qua 2FF trong RTL (uart_rx, spi miso, i2c, capture timer,
# GPIO); input delay chi cho STA diem bat dau. Duong ra di qua mux AF to hop
# tu flop cua ngoai vi.
constrain_input_ports  {pad_in*}                         CLK_SYS  $P_SYS
constrain_output_ports {pad_out* pad_oe*}                CLK_SYS  $P_SYS
constrain_input_ports  {flash_io_i*}                     CLK_SYS  $P_SYS
constrain_output_ports {flash_sck flash_cs_n flash_io_o* \
    flash_io_oe*}                                        CLK_SYS  $P_SYS
constrain_input_ports  {rtc_clk}                         CLK_SYS  $P_SYS

constrain_output_ports {sdram_cke sdram_cs_n sdram_ras_n \
    sdram_cas_n sdram_we_n sdram_ba* sdram_addr* \
    sdram_dq_o* sdram_dq_oe sdram_dqm*}                  CLK_SDRAM_OUT $P_SYS
constrain_input_ports  {sdram_dq_i*}                     CLK_SDRAM_OUT $P_SYS

############################################################
## Kiem tra phu kin I/O
############################################################

proc sdc_describe_ports {label port_collection} {
    set names {}
    if {[catch {
        foreach_in_collection port_obj $port_collection {
            lappend names [get_db $port_obj .name]
        }
    }]} {
        return "$label: [sizeof_collection $port_collection] port (phien ban nay khong liet ke duoc ten)"
    }
    return "$label: [join [lsort $names] { }]"
}

set CLOCK_OUTPUT_PORTS [get_ports {sdram_clk}]
set DATA_OUTPUTS       [remove_from_collection [all_outputs] $CLOCK_OUTPUT_PORTS]

set SDC_UNCONSTRAINED_INPUTS $DATA_INPUTS
if {$SDC_CONSTRAINED_INPUTS ne ""} {
    set SDC_UNCONSTRAINED_INPUTS         [remove_from_collection $DATA_INPUTS $SDC_CONSTRAINED_INPUTS]
}

set SDC_UNCONSTRAINED_OUTPUTS $DATA_OUTPUTS
if {$SDC_CONSTRAINED_OUTPUTS ne ""} {
    set SDC_UNCONSTRAINED_OUTPUTS         [remove_from_collection $DATA_OUTPUTS $SDC_CONSTRAINED_OUTPUTS]
}

if {[sizeof_collection $SDC_UNCONSTRAINED_INPUTS] > 0 ||
    [sizeof_collection $SDC_UNCONSTRAINED_OUTPUTS] > 0} {
    error "SDC: con port du lieu chua co I/O delay. [sdc_describe_ports {input} $SDC_UNCONSTRAINED_INPUTS] | [sdc_describe_ports {output} $SDC_UNCONSTRAINED_OUTPUTS]"
}

puts "INFO: I/O delay phu kin [sizeof_collection $DATA_INPUTS] port vao va [sizeof_collection $DATA_OUTPUTS] port ra"

if {[sizeof_collection [all_outputs]] > 0} {
    set_load 10.0 -pin_load [all_outputs]
}

############################################################
## Design rules
############################################################

set MAX_TRAN_CEIL_PS [sdc_env_number MCU_MAX_TRAN_CEIL_PS 300.0]
set MAX_TRAN_SYS_PS  [sdc_env_number MCU_MAX_TRAN_SYS_PS  150.0]
set MAX_TRAN_SLOW_PS [sdc_env_number MCU_MAX_TRAN_SLOW_PS 250.0]

set_max_fanout 20 [current_design]
set_max_transition $MAX_TRAN_CEIL_PS [current_design]

# Mot tan so cho ca ho CLK_SYS nen mot gia tri; truoc day CPU 100 ps (400 MHz),
# AXI 150 ps (200 MHz), APB 250 ps (100 MHz). Neu Genus tu choi
# set_max_transition tren clock thi lenh roi vao failed_sdc_commands.rpt.
set_max_transition $MAX_TRAN_SYS_PS  [add_to_collection $SYS_FAMILY [get_clocks CLK_SDRAM_OUT]]
set_max_transition $MAX_TRAN_SLOW_PS [get_clocks CLK_TCK]

puts "INFO: MCU SDC loaded with 2 primary, 1 forwarded and 12 gated clocks (single 250 MHz system clock)"
