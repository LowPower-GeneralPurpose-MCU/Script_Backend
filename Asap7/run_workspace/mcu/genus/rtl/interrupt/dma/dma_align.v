`timescale 1ns / 1ps
`include "dma_defines.vh"

// ============================================================
// dma_align.v — Hang doi BYTE co dich lan (byte queue)
// Layer : Reusable IP (noi bo dma_channel)
//
// Vi sao can module nay
// ---------------------
// DMA v1 tu choi moi cau hinh lech 4 byte (`cfg_bad` trong
// dma_core.v:171) va ghi WSTRB cung toan 1 (dma_axi_master.v:407).
// Nghia la khong copy duoc chuoi byte le, khong ghi halfword, va
// khong noi duoc ngoai vi 8-bit voi bo nho 32-bit.
//
// Module nay dung giua FIFO doc (32-bit) va duong ghi W. No nhan
// tung word kem "lan bat dau" + "so byte hop le", dong goi thanh
// dong byte lien tuc, roi nha ra theo lan/so byte ma phia ghi yeu
// cau. Nho vay hai dau co the lech nhau tuy y.
//
// Module KHONG biet gi ve AXI. No chi la hang doi byte.
//
// Giao dien
//   push_*  : nap tu FIFO doc. push_lane = vi tri byte dau hop le
//             trong word, push_cnt = so byte hop le (1..4).
//   pop_*   : nha ra cho duong ghi. pop_lane = vi tri byte dau
//             trong word dich, pop_cnt = so byte can (1..4).
//             pop_data da duoc dich san, pop_strb la WSTRB dung.
//   level   : so byte dang giu (0..DEPTH_BYTES)
//
// Luu y timing: module nay nam tren duong DU LIEU, khong nam tren
// duong DIA CHI. Duong gang cua chip la ch_bmax -> rd_addr; bo
// dich o day khong cham vao no.
// ============================================================

module dma_align #(
    parameter DEPTH_BYTES = 8           // phai >= 8 de day duoc 4B/chu ky
) (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        flush,           // xoa hang doi (IDLE / abort)

    //  Nap tu FIFO doc
    input  wire        push_valid,
    output wire        push_ready,
    input  wire [31:0] push_data,
    input  wire [1:0]  push_lane,       // byte dau hop le trong word
    input  wire [2:0]  push_cnt,        // 1..4

    //  Nha ra duong ghi
    output wire        pop_valid,
    input  wire        pop_ready,
    input  wire [1:0]  pop_lane,        // byte dau trong word dich
    input  wire [2:0]  pop_cnt,         // 1..4
    output wire [31:0] pop_data,
    output wire [3:0]  pop_strb,

    //  Trang thai
    output wire [4:0]  level            // 0..DEPTH_BYTES
);

    localparam QW = DEPTH_BYTES * 8;    // bit cua hang doi

    reg [QW-1:0] q;                     // byte 0 = q[7:0] = dau hang doi
    reg [4:0]    lvl;

    assign level = lvl;

    //  Nap: dich bo byte dan dau, chi giu push_cnt byte
    // push_data >> (push_lane*8) dua byte hop le dau tien ve vi tri 0.
    wire [31:0] push_shifted = push_data >> {push_lane, 3'b000};

    // Mat na theo so byte: cnt=1 -> 0x000000FF, cnt=4 -> 0xFFFFFFFF
    reg [31:0] push_mask;
    always @(*) begin
        case (push_cnt)
            3'd1:    push_mask = 32'h0000_00FF;
            3'd2:    push_mask = 32'h0000_FFFF;
            3'd3:    push_mask = 32'h00FF_FFFF;
            default: push_mask = 32'hFFFF_FFFF;
        endcase
    end

    wire [31:0] push_bytes = push_shifted & push_mask;

    //  Bat tay
    // pop_valid: du byte cho mot beat.
    // push_ready: con cho ngay ca sau khi tru phan sap pop di.
    //   Vong lap to hop? Khong: pop_ready den tu ben ngoai (WREADY),
    //   pop_valid chi phu thuoc lvl. push_ready khong quay lai
    //   pop_ready qua duong nao khac.
    wire pop_fire  = pop_valid  & pop_ready;
    wire push_fire = push_valid & push_ready;

    assign pop_valid = (lvl >= {2'b00, pop_cnt});

    wire [4:0] lvl_after_pop = pop_fire ? (lvl - {2'b00, pop_cnt}) : lvl;

    assign push_ready = ((lvl_after_pop + {2'b00, push_cnt}) <= DEPTH_BYTES[4:0]);

    //  Nha ra: byte dau hang doi dat vao vi tri pop_lane
    assign pop_data = q[31:0] << {pop_lane, 3'b000};

    reg [3:0] strb_by_cnt;
    always @(*) begin
        case (pop_cnt)
            3'd1:    strb_by_cnt = 4'b0001;
            3'd2:    strb_by_cnt = 4'b0011;
            3'd3:    strb_by_cnt = 4'b0111;
            default: strb_by_cnt = 4'b1111;
        endcase
    end
    assign pop_strb = strb_by_cnt << pop_lane;

    //  Cap nhat hang doi: POP TRUOC, PUSH SAU
    wire [QW-1:0] q_after_pop = pop_fire ? (q >> {pop_cnt, 3'b000}) : q;

    // Zero-extend roi dich toi vi tri lvl_after_pop.
    // push_ready bao dam lvl_after_pop + push_cnt <= DEPTH_BYTES,
    // nen khong byte nao bi day ra ngoai hang doi.
    wire [QW-1:0] push_aligned =
        {{(QW-32){1'b0}}, push_bytes} << {lvl_after_pop, 3'b000};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q   <= {QW{1'b0}};
            lvl <= 5'd0;
        end else if (flush) begin
            q   <= {QW{1'b0}};
            lvl <= 5'd0;
        end else begin
            if (push_fire) begin
                q   <= q_after_pop | push_aligned;
                lvl <= lvl_after_pop + {2'b00, push_cnt};
            end else if (pop_fire) begin
                q   <= q_after_pop;
                lvl <= lvl_after_pop;
            end
        end
    end

`ifndef SYNTHESIS
    // Kiem tra gia dinh: cnt phai trong 1..4 khi co giao dich.
    always @(posedge clk) begin
        if (rst_n && push_fire && (push_cnt == 3'd0 || push_cnt > 3'd4))
            $display("[dma_align] ERROR push_cnt=%0d ngoai 1..4", push_cnt);
        if (rst_n && pop_fire && (pop_cnt == 3'd0 || pop_cnt > 3'd4))
            $display("[dma_align] ERROR pop_cnt=%0d ngoai 1..4", pop_cnt);
        if (rst_n && pop_fire && (({1'b0, pop_lane} + {1'b0, pop_cnt[2:0]}) > 4'd4))
            $display("[dma_align] ERROR pop_lane=%0d + pop_cnt=%0d > 4",
                     pop_lane, pop_cnt);
    end
`endif

endmodule
