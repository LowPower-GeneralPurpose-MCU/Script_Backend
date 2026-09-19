`timescale 1ns / 1ps
`include "dma_defines.vh"

// ============================================================
// tb_dma.sv — testbench tu kiem cho DMA v2
//
// Kiem ba module MOI them o DMA v2:
//   dma_align   — hang doi byte co dich lan
//   dma_iopmp   — kiem dia chi/quyen tren duong AXI
//   dma_channel — mot kenh DMA (ban tach ra tu dma_core.v)
//
// KHONG dung dma_core.v: file do van giu ban `dma_channel` CU,
// trung ten module. Che do `dma` cua run_soc_sim.sh vi vay chi
// bien dich dung cac file can thiet.
//
// Mo hinh slave o day KHONG phai AXI day du — dma_channel noi ra
// giao dien lenh/du lieu/phan hoi noi bo (rd_cmd_*, rd_dat_*,
// rd_rsp_*); dma_axi_master moi la phan doi sang AXI that. Nen
// testbench nay lai dung o ranh gioi do.
//
// Quy uoc thoi gian: MOI tin hieu cua testbench duoc lai o SUON
// XUONG. DUT lay mau o suon len, nen doc mot tin hieu cua DUT o
// suon xuong cho dung gia tri ma DUT se lay mau o suon len ke
// tiep — khong co dua tranh.
// ============================================================

module tb_dma;

    // ------------------------------------------------------------
    // Hang
    // ------------------------------------------------------------
    localparam ADDR_W      = 32;
    localparam LEN_W       = 4;
    localparam ID_W        = 4;
    localparam N_CH_W      = 2;
    localparam BURST_W     = 7;
    localparam TOKEN_W     = 4;
    localparam OUT_W       = 4;
    localparam LEN_FIELD_W = 32;
    localparam MEM_BYTES   = 65536;

    localparam CLK_P = 4;               // 250 MHz, giong chip

    integer pass_cnt = 0;
    integer fail_cnt = 0;

    task chk(input string nm, input integer cond);
        begin
            if (cond) begin
                pass_cnt = pass_cnt + 1;
            end else begin
                fail_cnt = fail_cnt + 1;
                $display("[FAIL] %0s  (t=%0t)", nm, $time);
            end
        end
    endtask

    // ------------------------------------------------------------
    // Dong ho / reset
    // ------------------------------------------------------------
    reg clk = 1'b0;
    always #(CLK_P/2) clk = ~clk;

    reg rst_n = 1'b0;

    task do_reset;
        begin
            rst_n = 1'b0;
            repeat (4) @(negedge clk);
            rst_n = 1'b1;
            @(negedge clk);
        end
    endtask

    // ============================================================
    // PHAN A — dma_align
    // ============================================================
    reg         a_flush      = 1'b0;
    reg         a_push_valid = 1'b0;
    reg  [31:0] a_push_data  = 32'h0;
    reg  [1:0]  a_push_lane  = 2'd0;
    reg  [2:0]  a_push_cnt   = 3'd4;
    reg         a_pop_ready  = 1'b0;
    reg  [1:0]  a_pop_lane   = 2'd0;
    reg  [2:0]  a_pop_cnt    = 3'd4;

    wire        a_push_ready, a_pop_valid;
    wire [31:0] a_pop_data;
    wire [3:0]  a_pop_strb;
    wire [4:0]  a_level;

    dma_align #(.DEPTH_BYTES(8)) u_align (
        .clk(clk), .rst_n(rst_n), .flush(a_flush),
        .push_valid(a_push_valid), .push_ready(a_push_ready),
        .push_data(a_push_data), .push_lane(a_push_lane),
        .push_cnt(a_push_cnt),
        .pop_valid(a_pop_valid), .pop_ready(a_pop_ready),
        .pop_lane(a_pop_lane), .pop_cnt(a_pop_cnt),
        .pop_data(a_pop_data), .pop_strb(a_pop_strb),
        .level(a_level)
    );

    // Dat lane/cnt TRUOC, cho to hop on dinh mot suon, roi moi bat
    // valid/ready. Neu bat truoc thi giao dich co the chot ngay o
    // suon len ke tiep — task van dang cho va se cho mai mai.
    task al_push(input [31:0] d, input [1:0] lane, input [2:0] cnt);
        begin
            a_push_valid = 1'b0;
            a_push_data  = d;
            a_push_lane  = lane;
            a_push_cnt   = cnt;
            @(negedge clk);
            while (!a_push_ready) @(negedge clk);
            a_push_valid = 1'b1;
            @(negedge clk);             // chot o suon len o giua
            a_push_valid = 1'b0;
        end
    endtask

    task al_pop(input [1:0] lane, input [2:0] cnt,
                output [31:0] d, output [3:0] s);
        begin
            a_pop_ready = 1'b0;
            a_pop_lane  = lane;
            a_pop_cnt   = cnt;
            @(negedge clk);
            while (!a_pop_valid) @(negedge clk);
            a_pop_ready = 1'b1;
            d = a_pop_data;
            s = a_pop_strb;
            @(negedge clk);             // chot o suon len o giua
            a_pop_ready = 1'b0;
        end
    endtask

    // ============================================================
    // PHAN B — dma_iopmp
    // ============================================================
    localparam N_RGN = `DMA_IOPMP_N;

    reg  [N_RGN*32-1:0] p_w0 = {(N_RGN*32){1'b0}};
    reg  [N_RGN*32-1:0] p_w1 = {(N_RGN*32){1'b0}};
    reg  [31:0]         p_addr  = 32'h0;
    reg  [12:0]         p_bytes = 13'd1;
    reg                 p_is_wr = 1'b0;
    reg  [3:0]          p_ch_oh = 4'b0001;
    wire                p_allow;

    dma_iopmp #(.ADDR_W(32), .N_CH(4), .N_RGN(N_RGN)) u_iopmp (
        .cfg_word0(p_w0), .cfg_word1(p_w1),
        .req_addr(p_addr), .req_bytes(p_bytes),
        .req_is_wr(p_is_wr), .req_ch_oh(p_ch_oh),
        .allow(p_allow)
    );

    // word0 = {BASE[31:4], CH_MASK[3:0]}
    // word1 = {LIMIT[31:4], 1'b0, EN, PERM_W, PERM_R}
    task rgn_set(input integer i, input [31:0] base, input [31:0] limit,
                 input [3:0] chm, input en, input pw, input pr);
        begin
            p_w0[i*32 +: 32] = {base[31:4], chm};
            p_w1[i*32 +: 32] = {limit[31:4], 1'b0, en, pw, pr};
        end
    endtask

    // ============================================================
    // PHAN C — dma_channel + mo hinh bo nho
    // ============================================================
    reg [7:0] mem [0:MEM_BYTES-1];
    reg [7:0] gold[0:MEM_BYTES-1];      // anh vang de so sanh

    function [31:0] rd_word(input [31:0] a);
        begin
            rd_word = {mem[(a+3) % MEM_BYTES], mem[(a+2) % MEM_BYTES],
                       mem[(a+1) % MEM_BYTES], mem[a % MEM_BYTES]};
        end
    endfunction

    // --- cau hinh kenh ---
    reg [ADDR_W-1:0]      cfg_src_addr = 32'h0;
    reg [ADDR_W-1:0]      cfg_dst_addr = 32'h0;
    reg [LEN_FIELD_W-1:0] cfg_len      = 32'h0;
    reg [31:0]            cfg_ctrl     = 32'h0;
    reg [ADDR_W-1:0]      cfg_desc_ptr = 32'h0;
    reg [31:0]            cfg_src_stride = 32'h0;
    reg [31:0]            cfg_dst_stride = 32'h0;
    reg [15:0]            cfg_num_lines  = 16'd1;
    reg [ADDR_W-1:0]      cfg_sh_src   = 32'h0;
    reg [ADDR_W-1:0]      cfg_sh_dst   = 32'h0;
    reg [LEN_FIELD_W-1:0] cfg_sh_len   = 32'h0;
    reg [31:0]            cfg_sh_ctrl  = 32'h0;
    reg [TOKEN_W-1:0]     cfg_tokens   = 4'd0;
    reg [OUT_W-1:0]       cfg_rd_out   = 4'd0;
    reg [OUT_W-1:0]       cfg_wr_out   = 4'd0;

    reg                   ch_start = 1'b0;
    wire                  ch_done, ch_active, ch_susp, ch_chain;
    wire [`DMA_ERR_W-1:0] ch_err;
    wire [ADDR_W-1:0]     ch_err_addr;
    wire [LEN_FIELD_W-1:0] ch_xfer_cnt;
    wire                  ch_half_pulse, ch_chain_pulse;

    // --- cong descriptor ---
    wire                  desc_req;
    wire [ADDR_W-1:0]     desc_addr;
    reg                   desc_ack  = 1'b0;
    reg  [`DESC_BEATS*32-1:0] desc_data = {(`DESC_BEATS*32){1'b0}};
    reg                   desc_fail = 1'b0;

    // --- trigger ngoai vi ---
    reg [31:1]            periph_req = 31'h0;
    wire [31:1]           periph_clr;

    // --- lenh doc ---
    wire                  rd_cmd_valid;
    reg                   rd_cmd_ready = 1'b1;
    wire [ADDR_W-1:0]     rd_cmd_addr;
    wire [LEN_W-1:0]      rd_cmd_len;
    wire [2:0]            rd_cmd_size;
    wire [1:0]            rd_cmd_burst;
    wire [ID_W-1:0]       rd_cmd_id;
    wire [12:0]           rd_cmd_bytes;
    reg                   rd_viol = 1'b0;

    reg                   rd_dat_valid = 1'b0;
    wire                  rd_dat_ready;
    reg  [31:0]           rd_dat_data  = 32'h0;
    reg                   rd_dat_last  = 1'b0;

    reg                   rd_rsp_valid = 1'b0;
    reg  [1:0]            rd_rsp_err   = 2'b00;

    // --- lenh ghi ---
    wire                  wr_cmd_valid;
    reg                   wr_cmd_ready = 1'b1;
    wire [ADDR_W-1:0]     wr_cmd_addr;
    wire [LEN_W-1:0]      wr_cmd_len;
    wire [2:0]            wr_cmd_size;
    wire [1:0]            wr_cmd_burst;
    wire [ID_W-1:0]       wr_cmd_id;
    wire [12:0]           wr_cmd_bytes;
    reg                   wr_viol = 1'b0;

    wire                  wr_dat_valid;
    reg                   wr_dat_ready = 1'b0;
    wire [31:0]           wr_dat_data;
    wire [3:0]            wr_dat_strb;

    reg                   wr_rsp_valid = 1'b0;
    reg  [1:0]            wr_rsp_err   = 2'b00;

    wire [2:0]            axi_prot;
    wire [3:0]            axi_cache;

    reg                   timeout_rd    = 1'b0;
    reg                   timeout_wr_aw = 1'b0;
    reg                   timeout_wr_w  = 1'b0;

    dma_channel #(
        .ADDR_W(ADDR_W), .LEN_W(LEN_W), .ID_W(ID_W), .N_CH_W(N_CH_W),
        .CH_IDX(0), .FIFO_DEPTH(16), .MAX_BURST(64), .BURST_W(BURST_W),
        .TOKEN_W(TOKEN_W), .OUT_W(OUT_W), .PERIPH_NUM_W(5),
        .LEN_FIELD_W(LEN_FIELD_W)
    ) u_ch (
        .clk(clk), .rst_n(rst_n),
        .cfg_src_addr(cfg_src_addr), .cfg_dst_addr(cfg_dst_addr),
        .cfg_len(cfg_len), .cfg_ctrl(cfg_ctrl), .cfg_desc_ptr(cfg_desc_ptr),
        .cfg_src_stride(cfg_src_stride), .cfg_dst_stride(cfg_dst_stride),
        .cfg_num_lines(cfg_num_lines),
        .cfg_sh_src(cfg_sh_src), .cfg_sh_dst(cfg_sh_dst),
        .cfg_sh_len(cfg_sh_len), .cfg_sh_ctrl(cfg_sh_ctrl),
        .cfg_tokens(cfg_tokens), .cfg_rd_out_max(cfg_rd_out),
        .cfg_wr_out_max(cfg_wr_out),
        .start(ch_start), .done(ch_done), .active(ch_active),
        .suspended(ch_susp), .chain_active(ch_chain),
        .err(ch_err), .err_addr(ch_err_addr), .xfer_cnt(ch_xfer_cnt),
        .half_pulse(ch_half_pulse), .chain_pulse(ch_chain_pulse),
        .desc_req(desc_req), .desc_addr(desc_addr), .desc_ack(desc_ack),
        .desc_data(desc_data), .desc_fail(desc_fail),
        .periph_req(periph_req), .periph_clr(periph_clr),
        .rd_cmd_valid(rd_cmd_valid), .rd_cmd_ready(rd_cmd_ready),
        .rd_cmd_addr(rd_cmd_addr), .rd_cmd_len(rd_cmd_len),
        .rd_cmd_size(rd_cmd_size), .rd_cmd_burst(rd_cmd_burst),
        .rd_cmd_id(rd_cmd_id), .rd_cmd_bytes(rd_cmd_bytes), .rd_viol(rd_viol),
        .rd_dat_valid(rd_dat_valid), .rd_dat_ready(rd_dat_ready),
        .rd_dat_data(rd_dat_data), .rd_dat_last(rd_dat_last),
        .rd_rsp_valid(rd_rsp_valid), .rd_rsp_err(rd_rsp_err),
        .wr_cmd_valid(wr_cmd_valid), .wr_cmd_ready(wr_cmd_ready),
        .wr_cmd_addr(wr_cmd_addr), .wr_cmd_len(wr_cmd_len),
        .wr_cmd_size(wr_cmd_size), .wr_cmd_burst(wr_cmd_burst),
        .wr_cmd_id(wr_cmd_id), .wr_cmd_bytes(wr_cmd_bytes), .wr_viol(wr_viol),
        .wr_dat_valid(wr_dat_valid), .wr_dat_ready(wr_dat_ready),
        .wr_dat_data(wr_dat_data), .wr_dat_strb(wr_dat_strb),
        .wr_rsp_valid(wr_rsp_valid), .wr_rsp_err(wr_rsp_err),
        .axi_prot(axi_prot), .axi_cache(axi_cache),
        .timeout_rd(timeout_rd), .timeout_wr_aw(timeout_wr_aw),
        .timeout_wr_w(timeout_wr_w)
    );

    // ------------------------------------------------------------
    // Hang doi lenh (bat o suon xuong: lenh chot o suon len ke tiep)
    // ------------------------------------------------------------
    typedef struct packed {
        logic [31:0] addr;
        logic [3:0]  len;
        logic [1:0]  burst;
        logic [2:0]  size;
        logic [12:0] bytes;
    } cmd_t;

    cmd_t rq[$];
    cmd_t wq[$];

    // Giam sat giao thuc: burst khong duoc cat bien 4 KB.
    integer cross4k_err = 0;
    integer bytes_err   = 0;

    task check_cmd(input cmd_t c);
        reg [31:0] lastb;
        reg [31:0] span;
        begin
            if (c.burst == `AXI_BURST_INCR) begin
                span  = (c.len + 1) * 4;
                lastb = c.addr + span - 1;
                if (c.addr[31:12] != lastb[31:12]) begin
                    cross4k_err = cross4k_err + 1;
                    $display("[FAIL] burst cat bien 4KB: addr=%08h len=%0d (t=%0t)",
                             c.addr, c.len, $time);
                end
            end
            if (c.bytes == 13'd0) begin
                bytes_err = bytes_err + 1;
                $display("[FAIL] cmd_bytes = 0 (t=%0t)", $time);
            end
        end
    endtask

    cmd_t cap_r, cap_w;

    always @(negedge clk) begin
        if (rst_n && rd_cmd_valid && rd_cmd_ready) begin
            cap_r.addr  = rd_cmd_addr;
            cap_r.len   = rd_cmd_len;
            cap_r.burst = rd_cmd_burst;
            cap_r.size  = rd_cmd_size;
            cap_r.bytes = rd_cmd_bytes;
            check_cmd(cap_r);
            rq.push_back(cap_r);
        end
        if (rst_n && wr_cmd_valid && wr_cmd_ready) begin
            cap_w.addr  = wr_cmd_addr;
            cap_w.len   = wr_cmd_len;
            cap_w.burst = wr_cmd_burst;
            cap_w.size  = wr_cmd_size;
            cap_w.bytes = wr_cmd_bytes;
            check_cmd(cap_w);
            wq.push_back(cap_w);
        end
    end

    // ------------------------------------------------------------
    // Tiem loi: burst thu N (tinh tu 0) tra ve ma loi
    // ------------------------------------------------------------
    integer rd_err_at = -1;  reg [1:0] rd_err_code = `AXI_RESP_SLVERR;
    integer wr_err_at = -1;  reg [1:0] wr_err_code = `AXI_RESP_SLVERR;
    integer rd_burst_n = 0;
    integer wr_burst_n = 0;

    // ------------------------------------------------------------
    // Slave doc
    // ------------------------------------------------------------
    // Lenh duoc bat o suon xuong nhung chi thuc su chot o suon len
    // ngay sau do. Phai cho qua suon do roi moi tra du lieu: AXI
    // khong cho phep beat R ve truoc khi AR duoc nhan, va neu ve
    // som thi kenh day beat vao FIFO luc rx_remain con 0 -> rx_cnt
    // = 0, `avail` hut 4 byte va duong ghi ket cung.
    task serve_read(input cmd_t c);
        integer i;
        reg [31:0] a;
        begin
            @(negedge clk);
            a = {c.addr[31:2], 2'b00};
            for (i = 0; i <= c.len; i = i + 1) begin
                rd_dat_valid = 1'b1;
                rd_dat_data  = rd_word(a);
                rd_dat_last  = (i == c.len);
                while (!rd_dat_ready) @(negedge clk);
                @(negedge clk);
                if (c.burst == `AXI_BURST_INCR) a = a + 4;
            end
            rd_dat_valid = 1'b0;
            rd_dat_last  = 1'b0;
            rd_rsp_valid = 1'b1;
            rd_rsp_err   = (rd_burst_n == rd_err_at) ? rd_err_code
                                                     : `AXI_RESP_OKAY;
            @(negedge clk);
            rd_rsp_valid = 1'b0;
            rd_rsp_err   = `AXI_RESP_OKAY;
            rd_burst_n   = rd_burst_n + 1;
        end
    endtask

    initial begin : read_slave
        forever begin
            @(negedge clk);
            while (rq.size() > 0) serve_read(rq.pop_front());
        end
    end

    // ------------------------------------------------------------
    // Slave ghi
    // ------------------------------------------------------------
    task serve_write(input cmd_t c);
        integer i, b;
        reg [31:0] a;
        begin
            @(negedge clk);             // cho lenh chot that su
            a = {c.addr[31:2], 2'b00};
            for (i = 0; i <= c.len; i = i + 1) begin
                // Chi bat WREADY SAU khi da thay WVALID o mot suon
                // xuong. Bat truoc thi beat chot som mot chu ky va
                // testbench lay nham du lieu cua beat ke tiep.
                wr_dat_ready = 1'b0;
                while (!wr_dat_valid) @(negedge clk);
                wr_dat_ready = 1'b1;
                for (b = 0; b < 4; b = b + 1)
                    if (wr_dat_strb[b])
                        mem[(a + b) % MEM_BYTES] = wr_dat_data[8*b +: 8];
                @(negedge clk);
                if (c.burst == `AXI_BURST_INCR) a = a + 4;
            end
            wr_dat_ready = 1'b0;
            wr_rsp_valid = 1'b1;
            wr_rsp_err   = (wr_burst_n == wr_err_at) ? wr_err_code
                                                     : `AXI_RESP_OKAY;
            @(negedge clk);
            wr_rsp_valid = 1'b0;
            wr_rsp_err   = `AXI_RESP_OKAY;
            wr_burst_n   = wr_burst_n + 1;
        end
    endtask

    initial begin : write_slave
        forever begin
            @(negedge clk);
            while (wq.size() > 0) serve_write(wq.pop_front());
        end
    end

    // ------------------------------------------------------------
    // Slave descriptor — doc 8 word tu mem[desc_addr]
    // ------------------------------------------------------------
    integer desc_lat = 3;

    initial begin : desc_slave
        integer k;
        forever begin
            @(negedge clk);
            if (desc_req && !desc_ack) begin
                repeat (desc_lat) @(negedge clk);
                for (k = 0; k < `DESC_BEATS; k = k + 1)
                    desc_data[32*k +: 32] = rd_word(desc_addr + 4*k);
                desc_ack = 1'b1;
                @(negedge clk);
                desc_ack = 1'b0;
            end
        end
    end

    // ------------------------------------------------------------
    // Bat xung half / chain
    // ------------------------------------------------------------
    integer half_seen  = 0;
    integer chain_seen = 0;
    always @(posedge clk) if (rst_n) begin
        if (ch_half_pulse)  half_seen  = half_seen + 1;
        if (ch_chain_pulse) chain_seen = chain_seen + 1;
    end

    // ------------------------------------------------------------
    // Tien ich
    // ------------------------------------------------------------
    task wr_w(input [31:0] a, input [31:0] v);
        begin
            mem[a+0] = v[7:0];   gold[a+0] = v[7:0];
            mem[a+1] = v[15:8];  gold[a+1] = v[15:8];
            mem[a+2] = v[23:16]; gold[a+2] = v[23:16];
            mem[a+3] = v[31:24]; gold[a+3] = v[31:24];
        end
    endtask

    // Ghi mot descriptor 32 byte vao mo hinh bo nho
    task wr_desc(input [31:0] at, input [31:0] s, input [31:0] d,
                 input [31:0] len, input [31:0] c, input [31:0] nxt,
                 input [31:0] ss, input [31:0] dstr, input [31:0] nl);
        begin
            wr_w(at + 4*`DESC_W_SRC,     s);
            wr_w(at + 4*`DESC_W_DST,     d);
            wr_w(at + 4*`DESC_W_LEN,     len);
            wr_w(at + 4*`DESC_W_CTRL,    c);
            wr_w(at + 4*`DESC_W_NEXT,    nxt);
            wr_w(at + 4*`DESC_W_SSTRIDE, ss);
            wr_w(at + 4*`DESC_W_DSTRIDE, dstr);
            wr_w(at + 4*`DESC_W_NLINES,  nl);
        end
    endtask

    task mem_init;
        integer i;
        begin
            for (i = 0; i < MEM_BYTES; i = i + 1) begin
                mem[i]  = i[7:0] ^ i[15:8];
                gold[i] = mem[i];
            end
        end
    endtask

    task cfg_clear;
        begin
            cfg_src_addr = 32'h0; cfg_dst_addr = 32'h0;
            cfg_len = 32'h0; cfg_ctrl = 32'h0; cfg_desc_ptr = 32'h0;
            cfg_src_stride = 32'h0; cfg_dst_stride = 32'h0;
            cfg_num_lines = 16'd1;
            cfg_sh_src = 32'h0; cfg_sh_dst = 32'h0;
            cfg_sh_len = 32'h0; cfg_sh_ctrl = 32'h0;
            cfg_tokens = 4'd0; cfg_rd_out = 4'd0; cfg_wr_out = 4'd0;
            rd_viol = 1'b0; wr_viol = 1'b0;
            timeout_rd = 1'b0; timeout_wr_aw = 1'b0; timeout_wr_w = 1'b0;
            rd_err_at = -1; wr_err_at = -1;
            rd_burst_n = 0; wr_burst_n = 0;
            half_seen = 0; chain_seen = 0;
        end
    endtask

    // Bat start ngay, khong cho gi — dung de kiem chot start_pend.
    task pulse_start_raw;
        begin
            ch_start = 1'b1;
            @(negedge clk);
            ch_start = 1'b0;
            @(negedge clk);
        end
    endtask

    // Doi FIFO doc xa het rac cua lan truoc.
    task wait_fifo_clean(input integer max_cyc, output integer hung);
        integer n;
        begin
            n = 0;
            hung = 0;
            while ((u_ch.fifo_count !== 0) && (n < max_cyc)) begin
                @(negedge clk);
                n = n + 1;
            end
            if (u_ch.fifo_count !== 0) hung = 1;
        end
    endtask

    // Kenh chi nhan start khi FIFO da sach, nen neu bat start luc
    // con rac thi no bat dau tre — `wait_idle` se thay active = 0
    // va tra ve ngay, do nham la transfer xong. Cho sach truoc cho
    // thoi diem bat dau xac dinh.
    integer fifo_hung;

    task pulse_start;
        begin
            wait_fifo_clean(64, fifo_hung);
            pulse_start_raw;
        end
    endtask

    // Doi kenh ve IDLE; hung = 1 neu treo qua han
    task wait_idle(input integer max_cyc, output integer hung);
        integer n;
        begin
            n = 0;
            hung = 0;
            while (ch_active && (n < max_cyc)) begin
                @(negedge clk);
                n = n + 1;
            end
            if (ch_active) hung = 1;
            repeat (2) @(negedge clk);
        end
    endtask

    // So sanh vung dich voi nguon
    task cmp_copy(input string nm, input [31:0] s, input [31:0] d,
                  input integer len);
        integer i, bad;
        begin
            bad = 0;
            for (i = 0; i < len; i = i + 1)
                if (mem[d+i] !== gold[s+i]) bad = bad + 1;
            chk(nm, bad == 0);
            if (bad != 0)
                $display("       -> %0d/%0d byte sai, src=%08h dst=%08h",
                         bad, len, s, d);
        end
    endtask

    // Vung dich khong duoc dinh ra ngoai [d, d+len)
    task cmp_guard(input string nm, input [31:0] d, input integer len);
        integer i, bad;
        begin
            bad = 0;
            for (i = 1; i <= 8; i = i + 1) begin
                if (mem[d-i]       !== gold[d-i])       bad = bad + 1;
                if (mem[d+len+i-1] !== gold[d+len+i-1]) bad = bad + 1;
            end
            chk(nm, bad == 0);
        end
    endtask

    // CTRL co ban: INCR ca hai chieu, bmax = 0 (toi da), pnum = 0
    function [31:0] ctrl_mm;
        input integer dummy;
        begin
            ctrl_mm = (32'h1 << `CTRL_SI) | (32'h1 << `CTRL_DI);
        end
    endfunction

    // Chay mot lan copy bo nho -> bo nho roi kiem
    task run_copy(input string nm, input [31:0] s, input [31:0] d,
                  input integer len, input [31:0] ctrl_v);
        integer hung;
        begin
            cfg_clear;
            cfg_src_addr = s;
            cfg_dst_addr = d;
            cfg_len      = len;
            cfg_ctrl     = ctrl_v;
            pulse_start;
            wait_idle(20000, hung);
            if (hung) begin
                chk({nm, " (treo)"}, 0);
                do_reset;
            end else begin
                cmp_copy(nm, s, d, len);
                cmp_guard({nm, " bien"}, d, len);
                chk({nm, " err=NONE"}, ch_err === `DMA_ERR_NONE);
                chk({nm, " xfer_cnt"}, ch_xfer_cnt === len);
            end
        end
    endtask

    // ============================================================
    // Chuong trinh chinh
    // ============================================================
    integer i, hung, bad, ln, bi;
    reg [31:0] dw;
    reg [3:0]  ds;
    reg [31:0] ctrl;

    initial begin
        mem_init;
        do_reset;

        // --------------------------------------------------------
        $display("=== A. dma_align ===");
        al_push(32'hDEADBEEF, 2'd0, 3'd4);
        al_pop(2'd0, 3'd4, dw, ds);
        chk("A1 pass-through data", dw === 32'hDEADBEEF);
        chk("A1 pass-through strb", ds === 4'b1111);

        // nap lan 1 lay 3 byte (CC BB AA) -> nha lan 0, 3 byte
        al_push(32'hAABBCCDD, 2'd1, 3'd3);
        al_pop(2'd0, 3'd3, dw, ds);
        chk("A2 dich xuong data", dw[23:0] === 24'hAABBCC);
        chk("A2 dich xuong strb", ds === 4'b0111);

        // nap 4 byte lan 0 -> nha 2 byte o lan 2, roi 2 byte o lan 0
        al_push(32'h11223344, 2'd0, 3'd4);
        al_pop(2'd2, 3'd2, dw, ds);
        chk("A3 nha lan 2 data", dw[31:16] === 16'h3344);
        chk("A3 nha lan 2 strb", ds === 4'b1100);
        al_pop(2'd0, 3'd2, dw, ds);
        chk("A3 phan con lai", dw[15:0] === 16'h1122);
        chk("A3 strb phan con lai", ds === 4'b0011);

        a_flush = 1'b1; @(negedge clk); a_flush = 1'b0; @(negedge clk);
        chk("A4 flush -> level 0", a_level === 5'd0);
        al_push(32'h01020304, 2'd0, 3'd4);
        al_push(32'h05060708, 2'd0, 3'd4);
        chk("A4 level = 8", a_level === 5'd8);
        chk("A4 day -> push_ready = 0", a_push_ready === 1'b0);
        a_flush = 1'b1; @(negedge clk); a_flush = 1'b0; @(negedge clk);

        // --------------------------------------------------------
        $display("=== B. dma_iopmp ===");
        p_addr = 32'h2000; p_bytes = 13'd64; p_is_wr = 1'b0; p_ch_oh = 4'b0001;
        #1;
        chk("B1 khong vung nao bat -> allow", p_allow === 1'b1);

        rgn_set(0, 32'h0000_2000, 32'h0000_2FF0, 4'b0001, 1'b1, 1'b1, 1'b1);
        #1;
        chk("B2 trong vung -> allow", p_allow === 1'b1);

        p_addr = 32'h3000; #1;
        chk("B3 ngoai vung -> chan", p_allow === 1'b0);

        p_addr = 32'h2FF0; p_bytes = 13'd64; #1;
        chk("B4 cuoi burst ra ngoai -> chan", p_allow === 1'b0);
        p_bytes = 13'd16; #1;
        chk("B4 vua du trong vung -> allow", p_allow === 1'b1);

        p_addr = 32'h2000; p_bytes = 13'd16; p_ch_oh = 4'b0010; #1;
        chk("B5 sai kenh -> chan", p_allow === 1'b0);
        p_ch_oh = 4'b0001; #1;

        rgn_set(0, 32'h0000_2000, 32'h0000_2FF0, 4'b0001, 1'b1, 1'b0, 1'b1);
        p_is_wr = 1'b1; #1;
        chk("B6 thieu PERM_W -> chan", p_allow === 1'b0);
        p_is_wr = 1'b0; #1;
        chk("B6 doc van duoc", p_allow === 1'b1);

        rgn_set(0, 32'h0, 32'h0, 4'b0000, 1'b0, 1'b0, 1'b0);
        p_addr = 32'h9999; #1;
        chk("B7 tat het -> allow", p_allow === 1'b1);

        // --------------------------------------------------------
        $display("=== C. dma_channel: copy co ban ===");
        ctrl = ctrl_mm(0);
        run_copy("C1 copy 64B can word", 32'h1000, 32'h4000,   64, ctrl);
        run_copy("C2 copy 4B",           32'h1100, 32'h4100,    4, ctrl);
        run_copy("C3 copy 1B",           32'h1200, 32'h4200,    1, ctrl);
        run_copy("C4 copy 1024B",        32'h1400, 32'h6000, 1024, ctrl);

        $display("=== C. dma_channel: lech byte ===");
        run_copy("C5 src lech 1, len 13",  32'h1801, 32'h4400,  13, ctrl);
        run_copy("C6 dst lech 2, len 7",   32'h1900, 32'h4502,   7, ctrl);
        run_copy("C7 ca hai lech, len 17", 32'h1A03, 32'h4601,  17, ctrl);
        run_copy("C8 lech + dai 300B",     32'h1B02, 32'h4703, 300, ctrl);

        $display("=== C. dma_channel: bien 4 KB ===");
        // Dich phai nam ngoai 0x4703..0x482E ma C8 vua ghi, neu khong
        // phep kiem bien cua C9 se thay dau chan cua C8.
        run_copy("C9 cat bien 4KB", 32'h0FF0, 32'h6800, 64, ctrl);
        chk("C9 khong burst nao cat bien 4KB", cross4k_err == 0);

        // --------------------------------------------------------
        $display("=== D. FIXED burst (ngoai vi) ===");
        cfg_clear;
        cfg_src_addr = 32'h2001;                  // lan 1, dia chi co dinh
        cfg_dst_addr = 32'h4900;
        cfg_len      = 8;
        cfg_ctrl     = (32'h1 << `CTRL_DI);       // src FIXED, W8 = 2'b00
        pulse_start;
        wait_idle(20000, hung);
        chk("D1 FIXED src khong treo", hung == 0);
        if (hung) do_reset;
        else begin
            bad = 0;
            for (i = 0; i < 8; i = i + 1)
                if (mem[32'h4900+i] !== gold[32'h2001]) bad = bad + 1;
            chk("D1 8 byte deu = byte tai dia chi co dinh", bad == 0);
            chk("D1 err = NONE", ch_err === `DMA_ERR_NONE);
        end

        cfg_clear;
        cfg_src_addr = 32'h2100;
        cfg_dst_addr = 32'h4A02;                  // lan 2, dia chi co dinh
        cfg_len      = 4;
        cfg_ctrl     = (32'h1 << `CTRL_SI);       // dst FIXED, W8
        pulse_start;
        wait_idle(20000, hung);
        chk("D2 FIXED dst khong treo", hung == 0);
        if (hung) do_reset;
        else begin
            chk("D2 byte cuoi ghi vao dia chi co dinh",
                mem[32'h4A02] === gold[32'h2103]);
            chk("D2 err = NONE", ch_err === `DMA_ERR_NONE);
        end

        // --------------------------------------------------------
        $display("=== E. Loi ===");
        cfg_clear;
        cfg_src_addr = 32'h1000; cfg_dst_addr = 32'h4B00;
        cfg_len = 256; cfg_ctrl = ctrl_mm(0);
        rd_err_at = 0; rd_err_code = `AXI_RESP_SLVERR;
        pulse_start;
        wait_idle(20000, hung);
        chk("E1 SLVERR doc khong treo", hung == 0);
        chk("E1 err = SLVERR", ch_err === `DMA_ERR_SLVERR);
        if (hung) do_reset;

        cfg_clear;
        cfg_src_addr = 32'h1000; cfg_dst_addr = 32'h4C00;
        cfg_len = 256; cfg_ctrl = ctrl_mm(0);
        wr_err_at = 0; wr_err_code = `AXI_RESP_DECERR;
        pulse_start;
        wait_idle(20000, hung);
        chk("E2 DECERR ghi khong treo", hung == 0);
        chk("E2 err = DECERR", ch_err === `DMA_ERR_DECERR);
        if (hung) do_reset;

        cfg_clear;
        cfg_src_addr = 32'h1000; cfg_dst_addr = 32'h4D00;
        cfg_len = 256; cfg_ctrl = ctrl_mm(0);
        pulse_start;
        repeat (10) @(negedge clk);
        timeout_rd = 1'b1;
        @(negedge clk);
        timeout_rd = 1'b0;
        wait_idle(20000, hung);
        chk("E3 timeout khong treo", hung == 0);
        chk("E3 err = TIMEOUT", ch_err === `DMA_ERR_TIMEOUT);
        if (hung) do_reset;

        cfg_clear;
        cfg_src_addr = 32'h1000; cfg_dst_addr = 32'h4E00;
        cfg_len = 256; cfg_ctrl = ctrl_mm(0);
        pulse_start;
        repeat (6) @(negedge clk);
        rd_viol = 1'b1;
        @(negedge clk);
        rd_viol = 1'b0;
        wait_idle(20000, hung);
        chk("E4 IOPMP chan khong treo", hung == 0);
        chk("E4 err = ACCESS", ch_err === `DMA_ERR_ACCESS);
        if (hung) do_reset;

        cfg_clear;
        cfg_src_addr = 32'h1000; cfg_dst_addr = 32'h4F00;
        cfg_len = 2048; cfg_ctrl = ctrl_mm(0);
        pulse_start;
        repeat (12) @(negedge clk);
        cfg_ctrl = ctrl_mm(0) | (32'h1 << `CTRL_ABORT);
        wait_idle(20000, hung);
        chk("E5 abort khong treo", hung == 0);
        chk("E5 err = ABORT", ch_err === `DMA_ERR_ABORT);
        cfg_ctrl = ctrl_mm(0);
        if (hung) do_reset;

        cfg_clear;
        cfg_src_addr = 32'h1000; cfg_dst_addr = 32'h5400;
        cfg_len = 0; cfg_ctrl = ctrl_mm(0);
        pulse_start;
        wait_idle(200, hung);
        chk("E6 LEN=0 ket thuc ngay", hung == 0);
        chk("E6 LEN=0 khong phat lenh",
            (rd_burst_n == 0) && (wr_burst_n == 0));
        if (hung) do_reset;

        // Kenh da ve IDLE thi hang doi du lieu phai sach. Neu con
        // du thi lan chuyen ke tiep vua sai du lieu vua khong bao
        // gio thoat duoc ST_DRAIN (dieu kien thoat doi fifo_empty).
        wait_fifo_clean(64, fifo_hung);
        chk("E7 FIFO xa het khi ve IDLE", fifo_hung == 0);
        chk("E7 bo can byte sach khi ve IDLE", u_ch.al_level === 5'd0);

        // E8: bat start NGAY sau mot lan abort, luc FIFO con rac.
        // Kenh phai chot yeu cau lai, xa xong roi moi chay — va
        // chay dung. Day la bai kiem cho `start_pend`.
        cfg_clear;
        cfg_src_addr = 32'h1000; cfg_dst_addr = 32'h5B00;
        cfg_len = 2048; cfg_ctrl = ctrl_mm(0);
        pulse_start;
        repeat (12) @(negedge clk);
        cfg_ctrl = ctrl_mm(0) | (32'h1 << `CTRL_ABORT);
        wait_idle(20000, hung);
        cfg_ctrl = ctrl_mm(0);
        chk("E8 abort khong treo", hung == 0);

        cfg_clear;
        cfg_src_addr = 32'h1200; cfg_dst_addr = 32'h5C00; cfg_len = 64;
        cfg_ctrl = ctrl_mm(0);
        pulse_start_raw;                 // KHONG cho FIFO sach
        repeat (40) @(negedge clk);      // du de xa het roi chay
        wait_idle(20000, hung);
        chk("E8 khoi dong ngay sau abort khong treo", hung == 0);
        if (hung) do_reset;
        else begin
            cmp_copy("E8 du lieu dung sau abort", 32'h1200, 32'h5C00, 64);
            chk("E8 err = NONE", ch_err === `DMA_ERR_NONE);
        end

        // --------------------------------------------------------
        $display("=== F. 2D / stride ===");
        cfg_clear;
        cfg_src_addr   = 32'h1000;
        cfg_dst_addr   = 32'h5100;
        cfg_len        = 16;
        cfg_src_stride = 32;
        cfg_dst_stride = 24;
        cfg_num_lines  = 16'd4;
        cfg_ctrl       = ctrl_mm(0) | (32'h1 << `CTRL_TWO_D);
        pulse_start;
        wait_idle(20000, hung);
        chk("F1 2D khong treo", hung == 0);
        if (hung) do_reset;
        else begin
            bad = 0;
            for (ln = 0; ln < 4; ln = ln + 1)
                for (bi = 0; bi < 16; bi = bi + 1)
                    if (mem[32'h5100 + ln*24 + bi] !==
                        gold[32'h1000 + ln*32 + bi]) bad = bad + 1;
            chk("F1 4 dong x 16B, stride 32/24", bad == 0);
            chk("F1 xfer_cnt = 64", ch_xfer_cnt === 32'd64);
        end

        // --------------------------------------------------------
        $display("=== G. Scatter-gather ===");
        cfg_clear;
        wr_desc(32'h8000, 32'h1000, 32'h5200, 32'd32, ctrl_mm(0),
                32'h8020, 32'd0, 32'd0, 32'd1);
        wr_desc(32'h8020, 32'h1100, 32'h5300, 32'd48, ctrl_mm(0),
                32'h0000, 32'd0, 32'd0, 32'd1);
        cfg_desc_ptr = 32'h8000;
        cfg_ctrl     = ctrl_mm(0) | (32'h1 << `CTRL_SG_EN);
        cfg_len      = 32'd0;          // SG lay do dai tu descriptor
        pulse_start;
        wait_idle(40000, hung);
        chk("G1 SG khong treo", hung == 0);
        if (hung) do_reset;
        else begin
            cmp_copy("G1 descriptor 1", 32'h1000, 32'h5200, 32);
            cmp_copy("G2 descriptor 2", 32'h1100, 32'h5300, 48);
            chk("G3 chain_pulse phat 1 lan", chain_seen == 1);
            chk("G4 err = NONE", ch_err === `DMA_ERR_NONE);
        end

        cfg_clear;
        wr_desc(32'h8040, 32'h1000, 32'h5500, 32'd16, ctrl_mm(0),
                32'h8051, 32'd0, 32'd0, 32'd1);   // NEXT khong can 32B
        cfg_desc_ptr = 32'h8040;
        cfg_ctrl     = ctrl_mm(0) | (32'h1 << `CTRL_SG_EN);
        pulse_start;
        wait_idle(20000, hung);
        chk("G5 descriptor hong khong treo", hung == 0);
        chk("G5 err = DESC", ch_err === `DMA_ERR_DESC);
        if (hung) do_reset;

        // --------------------------------------------------------
        $display("=== H. Reload (shadow) ===");
        cfg_clear;
        cfg_src_addr = 32'h1000; cfg_dst_addr = 32'h5600; cfg_len = 32;
        cfg_sh_src   = 32'h1100; cfg_sh_dst   = 32'h5700; cfg_sh_len = 32;
        cfg_sh_ctrl  = ctrl_mm(0);
        cfg_ctrl     = ctrl_mm(0) | (32'h1 << `CTRL_RELOAD);
        pulse_start;
        wait_idle(40000, hung);
        chk("H1 reload khong treo", hung == 0);
        if (hung) do_reset;
        else begin
            cmp_copy("H1 lan dau",     32'h1000, 32'h5600, 32);
            cmp_copy("H2 lan nap lai", 32'h1100, 32'h5700, 32);
        end

        // --------------------------------------------------------
        $display("=== I. Ngat HALF ===");
        cfg_clear;
        cfg_src_addr = 32'h1000; cfg_dst_addr = 32'h5800;
        cfg_len = 256; cfg_ctrl = ctrl_mm(0);
        pulse_start;
        wait_idle(20000, hung);
        chk("I1 half_pulse phat dung 1 lan", half_seen == 1);
        if (hung) do_reset;

        // --------------------------------------------------------
        $display("=== J. Sideband PROT/CACHE ===");
        cfg_clear;
        cfg_src_addr = 32'h1000; cfg_dst_addr = 32'h5900; cfg_len = 16;
        cfg_ctrl = ctrl_mm(0) | (32'h1 << `CTRL_PRIV) |
                   (32'hA << `CTRL_CACHE_LSB);
        pulse_start;
        chk("J1 axi_prot[0] = PRIV",    axi_prot[0] === 1'b1);
        chk("J1 axi_prot[1] = ~SECURE", axi_prot[1] === 1'b1);
        chk("J1 axi_cache = 0xA",       axi_cache === 4'hA);
        wait_idle(20000, hung);
        if (hung) do_reset;

        // --------------------------------------------------------
        $display("=== K. Gioi han outstanding / token ===");
        cfg_clear;
        cfg_src_addr = 32'h1000; cfg_dst_addr = 32'h5A00; cfg_len = 512;
        cfg_ctrl   = ctrl_mm(0);
        cfg_tokens = 4'd2;
        cfg_rd_out = 4'd1;
        cfg_wr_out = 4'd1;
        pulse_start;
        wait_idle(60000, hung);
        chk("K1 outstanding = 1 khong treo", hung == 0);
        if (hung) do_reset;
        else cmp_copy("K1 du lieu van dung", 32'h1000, 32'h5A00, 512);

        // --------------------------------------------------------
        $display("");
        chk("Z1 khong burst nao cat bien 4KB", cross4k_err == 0);
        chk("Z2 cmd_bytes luon > 0",           bytes_err   == 0);

        $display("");
        $display("PASS COUNT = %0d", pass_cnt);
        $display("FAIL COUNT = %0d", fail_cnt);
        if (fail_cnt == 0) $display("RESULT: PASS");
        else               $display("RESULT: FAIL");
        $finish;
    end

    // Chot an toan chung
    initial begin
        #4_000_000;
        $display("[FAIL] testbench qua han tong the");
        $display("PASS COUNT = %0d", pass_cnt);
        $display("FAIL COUNT = %0d", fail_cnt + 1);
        $display("RESULT: FAIL");
        $finish;
    end

endmodule
