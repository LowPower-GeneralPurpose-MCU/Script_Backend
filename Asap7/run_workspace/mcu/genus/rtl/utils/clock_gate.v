`timescale 1ns / 1ps

// =============================================================================
// MODULE: clock_gate
// Chức năng: cổng clock (clock gating) cho các domain của SoC.
//
// Module suy ra cấu trúc "latch trong suốt khi clock thấp + cổng AND". Genus
// map cấu trúc này thành DLLx1 + AND rời rạc, KHÔNG phải một ICG cell.
//
// TODO (back-end): CTS không nhận diện được đây là clock gate, latch và cổng
// AND có thể bị đặt xa nhau (hold trên đường enable rủi ro), và cổng AND không
// phải clock cell cân bằng delay. Khi nào cần thì kiểm tra
// asap7sc7p5t_28/LIB/CCS/*SEQ* xem thư viện có ICG cell không rồi instantiate
// trực tiếp. Chưa làm ở thời điểm này.
// =============================================================================

module clock_gate (
    input  wire clk_in,
    input  wire en,
    // DFT: nối 1 trong scan-shift để clock chạy xuyên qua, nối 0 khi chạy chức
    // năng. Hiện top_soc nối cứng 1'b0 vì thiết kế chưa có scan chain.
    input  wire test_en,
    output wire clk_out
);

    reg en_latch;

    // Latch trong suốt khi clock ở mức THẤP. Giữ nguyên en_latch trong nửa chu
    // kỳ clock cao để 'en' thay đổi không tạo glitch cưa đôi clock.
    always @* begin
        if (!clk_in) begin
            en_latch = en | test_en;
        end
    end

    assign clk_out = clk_in & en_latch;

endmodule
