`timescale 1ns / 1ps

// =========================================================================
// APB SLAVE WRAPPER CHO LOI ASCON-128 (AEAD) / ASCON-HASH + TRNG 128-BIT
//
// Slave S10 cua apb_interconnect. Base 0x4000_C000, cua so 4 KB.
//
// REGISTER MAP (offset trong cua so 4 KB, giai ma DU 12 bit)
//   0x000 CTRL    RW
//                 [0]   START      - xung 1 chu ky, tu dong xoa
//                 [1]   MODE       - 0 = AEAD (ASCON-128), 1 = HASH
//                 [2]   TRNG_RST   - reset TRNG, muc CAO, KHONG tu xoa
//                 [3]   TRNG_EN    - bat TRNG, giu clock mo cho no
//                 [4]   DATA_VALID - xung 1 chu ky, tu dong xoa
//                 [7:5] DATA_CMD   - 0=AD 1=AD_LAST 2=PT 3=PT_LAST
//                                    4=HASH 5=HASH_LAST 6=EMPTY_AD
//   0x004 STATUS  [0] READY (RO)  [1] DONE (sticky, ghi 1 de xoa)
//                 [2] TRNG_VALID (RO)  [3] BUSY (RO)
//   0x010-0x01C   KEY[127:0]     WO (0x010 = bit 127:96)
//   0x020-0x02C   NONCE[127:0]   WO
//   0x030-0x034   DATA_IN[63:0]  WO (0x030 = bit 63:32)
//   0x040-0x044   DATA_OUT[63:0] RO - BAN MA cua khoi vua nap
//   0x050-0x05C   MODE=0: TAG[127:0]        MODE=1: HASH[255:128]
//   0x060-0x06C   HASH[127:0]      RO
//   0x070-0x07C   TRNG_RAND[127:0] RO
//
// LUU Y VE GIAO THUC (phan mem phai tuan thu):
//   - Chi duoc xung DATA_VALID khi STATUS.READY = 1.  Loi KHONG chan xung
//     den sai luc: no se bi BO QUA am tham va ket qua sai.
//   - Padding 10* cua ASCON do phan mem lam, khoi nay chi nhan khoi 64-bit.
//   - Loi chi ho tro MA HOA. Giai ma can x0 <= C (khong phai x0 ^= C) nen
//     phai them lenh moi vao ascon_core.
// =========================================================================
module apb_ascon (
    input  wire        PCLK,
    input  wire        PRESETn,
    input  wire        PSEL,
    input  wire        PENABLE,
    input  wire        PWRITE,
    input  wire [11:0] PADDR,
    input  wire [31:0] PWDATA,
    output wire [31:0] PRDATA,
    output wire        PREADY,
    output wire        PSLVERR,
    output wire        ascon_irq,
    // Bao cho mang clock gating o top_soc biet loi dang can clock. PSEL chi mo
    // cong trong luc co truy cap bus, ma mot lenh START can 12 chu ky va TRNG
    // can 128 chu ky - cat clock giua chung se DONG BANG FSM (dung loi cua
    // apb_cordic da mac truoc day).
    output wire        o_active
);

    assign PREADY = 1'b1;   // zero wait state

    // ---------------------------------------------------------------------
    // Thanh ghi cau hinh
    // ---------------------------------------------------------------------
    reg [31:0] ctrl_reg;
    reg [31:0] key_reg_0, key_reg_1, key_reg_2, key_reg_3;
    reg [31:0] nonce_reg_0, nonce_reg_1, nonce_reg_2, nonce_reg_3;
    reg [31:0] data_in_reg_0, data_in_reg_1;

    wire [63:0]  ascon_data_out;
    wire [127:0] ascon_tag_out;
    wire [255:0] ascon_hash_out;
    wire [127:0] trng_rand_out;
    wire         ascon_ready, ascon_done, ascon_busy, trng_valid;

    wire write_en = PSEL & PENABLE &  PWRITE;
    wire read_en  = PSEL & PENABLE & ~PWRITE;

    // Giai ma DU 12 bit. Ban dau chi so sanh PADDR[7:0] nen moi thanh ghi bi
    // lap lai 16 lan trong cua so 4 KB (ghi 0x100 / 0x200 ... deu trung CTRL).
    wire addr_wr_ok = (PADDR == 12'h000) || (PADDR == 12'h004) ||
                      (PADDR == 12'h010) || (PADDR == 12'h014) ||
                      (PADDR == 12'h018) || (PADDR == 12'h01C) ||
                      (PADDR == 12'h020) || (PADDR == 12'h024) ||
                      (PADDR == 12'h028) || (PADDR == 12'h02C) ||
                      (PADDR == 12'h030) || (PADDR == 12'h034);

    wire addr_rd_ok = (PADDR == 12'h000) || (PADDR == 12'h004) ||
                      (PADDR == 12'h040) || (PADDR == 12'h044) ||
                      (PADDR == 12'h050) || (PADDR == 12'h054) ||
                      (PADDR == 12'h058) || (PADDR == 12'h05C) ||
                      (PADDR == 12'h060) || (PADDR == 12'h064) ||
                      (PADDR == 12'h068) || (PADDR == 12'h06C) ||
                      (PADDR == 12'h070) || (PADDR == 12'h074) ||
                      (PADDR == 12'h078) || (PADDR == 12'h07C);

    assign PSLVERR = (write_en & ~addr_wr_ok) | (read_en & ~addr_rd_ok);

    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            ctrl_reg      <= 32'h0;
            key_reg_0     <= 32'h0; key_reg_1     <= 32'h0;
            key_reg_2     <= 32'h0; key_reg_3     <= 32'h0;
            nonce_reg_0   <= 32'h0; nonce_reg_1   <= 32'h0;
            nonce_reg_2   <= 32'h0; nonce_reg_3   <= 32'h0;
            data_in_reg_0 <= 32'h0; data_in_reg_1 <= 32'h0;
        end else if (write_en) begin
            case (PADDR)
                12'h000: ctrl_reg      <= PWDATA;
                12'h010: key_reg_0     <= PWDATA;
                12'h014: key_reg_1     <= PWDATA;
                12'h018: key_reg_2     <= PWDATA;
                12'h01C: key_reg_3     <= PWDATA;
                12'h020: nonce_reg_0   <= PWDATA;
                12'h024: nonce_reg_1   <= PWDATA;
                12'h028: nonce_reg_2   <= PWDATA;
                12'h02C: nonce_reg_3   <= PWDATA;
                12'h030: data_in_reg_0 <= PWDATA;
                12'h034: data_in_reg_1 <= PWDATA;
                default: ;
            endcase
        end else begin
            ctrl_reg[0] <= 1'b0;   // START tu xoa
            ctrl_reg[4] <= 1'b0;   // DATA_VALID tu xoa
        end
    end

    // ---------------------------------------------------------------------
    // DONE sticky.
    // `done` cua loi la xung 1 chu ky: phan mem polling STATUS khong bao gio
    // bat kip. Chot lai va cho ghi 1 de xoa (W1C tren STATUS[1]).
    // ---------------------------------------------------------------------
    reg done_sticky;
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn)
            done_sticky <= 1'b0;
        else if (ascon_done)
            done_sticky <= 1'b1;
        else if (write_en && (PADDR == 12'h004) && PWDATA[1])
            done_sticky <= 1'b0;
    end

    // ---------------------------------------------------------------------
    // Chot BAN MA.
    // `data_out` cua loi la to hop: x0 ^ data_in. No CHI dung o chu ky loi
    // hap thu khoi (ST_WAIT_DATA, data_valid = 1). Ngay sau do x0 da bi XOR
    // voi chinh data_in nen data_out quay ve x0 CU, roi 6/12 vong hoan vi
    // xoa sach. Khong chot thi doc 0x040 sau `done` chi ra rac.
    // ---------------------------------------------------------------------
    reg [63:0] ct_reg;
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn)
            ct_reg <= 64'h0;
        else if (ctrl_reg[4] && ascon_ready)
            ct_reg <= ascon_data_out;
    end

    // ---------------------------------------------------------------------
    // Read MUX
    // ---------------------------------------------------------------------
    reg [31:0] prdata_reg;
    always @(*) begin
        case (PADDR)
            12'h000: prdata_reg = ctrl_reg;
            12'h004: prdata_reg = {28'h0, ascon_busy, trng_valid, done_sticky, ascon_ready};
            12'h040: prdata_reg = ct_reg[63:32];
            12'h044: prdata_reg = ct_reg[31:0];

            12'h050: prdata_reg = ctrl_reg[1] ? ascon_hash_out[255:224] : ascon_tag_out[127:96];
            12'h054: prdata_reg = ctrl_reg[1] ? ascon_hash_out[223:192] : ascon_tag_out[95:64];
            12'h058: prdata_reg = ctrl_reg[1] ? ascon_hash_out[191:160] : ascon_tag_out[63:32];
            12'h05C: prdata_reg = ctrl_reg[1] ? ascon_hash_out[159:128] : ascon_tag_out[31:0];
            12'h060: prdata_reg = ascon_hash_out[127:96];
            12'h064: prdata_reg = ascon_hash_out[95:64];
            12'h068: prdata_reg = ascon_hash_out[63:32];
            12'h06C: prdata_reg = ascon_hash_out[31:0];

            12'h070: prdata_reg = trng_rand_out[127:96];
            12'h074: prdata_reg = trng_rand_out[95:64];
            12'h078: prdata_reg = trng_rand_out[63:32];
            12'h07C: prdata_reg = trng_rand_out[31:0];
            default: prdata_reg = 32'h0;
        endcase
    end

    assign PRDATA    = read_en ? prdata_reg : 32'h0;
    assign ascon_irq = done_sticky;
    assign o_active  = ascon_busy | ctrl_reg[0] | ctrl_reg[4] | ctrl_reg[3];

    wire [127:0] full_key   = {key_reg_0, key_reg_1, key_reg_2, key_reg_3};
    wire [127:0] full_nonce = {nonce_reg_0, nonce_reg_1, nonce_reg_2, nonce_reg_3};
    wire [63:0]  full_data  = {data_in_reg_0, data_in_reg_1};

    // TRNG reset la muc CAO. Phai OR them reset he thong, neu khong cac flop
    // cua no khong co duong nao ve trang thai dau tu PRESETn.
    trng_128b u_trng (
        .clock    (PCLK),
        .reset    (~PRESETn | ctrl_reg[2]),
        .enable   (ctrl_reg[3]),
        .valid    (trng_valid),
        .rand_out (trng_rand_out)
    );

    ascon_core u_ascon (
        .clk        (PCLK),
        .rst_n      (PRESETn),
        .start      (ctrl_reg[0]),
        .mode       (ctrl_reg[1]),
        .key_in     (full_key),
        .nonce_in   (full_nonce),
        .data_in    (full_data),
        .data_valid (ctrl_reg[4]),
        .data_cmd   (ctrl_reg[7:5]),
        .data_out   (ascon_data_out),
        .tag_out    (ascon_tag_out),
        .hash_out   (ascon_hash_out),
        .ready      (ascon_ready),
        .busy       (ascon_busy),
        .done       (ascon_done)
    );

endmodule
