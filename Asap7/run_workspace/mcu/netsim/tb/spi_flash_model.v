`timescale 1ns / 1ps
// =============================================================================
// spi_flash_model - SPI NOR flash toi gian cho tb_netsim.sv.
//
// Chi lam dung thu axi_spi_flash.v phat ra: Fast Read 0x0B mot bit, mode 0
// (SCK nghi 0), 8 bit lenh + 24 bit dia chi chot o canh LEN, 8 chu ky dummy,
// du lieu day ra o canh XUONG tu canh xuong cuoi cua dummy, MSB truoc, dia chi
// tu tang.  Burst cua controller dung SCK giua cac beat ma van giu CS# thap -
// canh xuong luc dung clock da day bit ke tiep, nen doc lien tuc van dung.
// Lenh khac thi in canh bao va khong lai MISO (tb keo len 1).
//
// Anh nap bang +FLASH_IMAGE=<file> ($readmemh, 1 byte / phan tu); phan con lai
// la 0xFF nhu flash da xoa.  Khong co +FLASH_IMAGE -> flash trong, boot ROM
// vao `park`.
// =============================================================================
module spi_flash_model #(
    parameter integer SIZE_BYTES = 65536,
    parameter real    T_V_NS     = 2.0,   // SCK xuong -> MISO hop le
    parameter integer MAX_LOG    = 32     // so lenh doc dau tien in ra log
)(
    input  wire sck,
    input  wire cs_n,
    input  wire mosi,
    output wire miso
);
    reg [7:0]  mem [0:SIZE_BYTES-1];
    reg [31:0] cmd_addr;     // {lenh, dia chi 24 bit}
    integer    nrise;        // canh len SCK ke tu khi CS# xuong
    integer    nreads;       // so lenh 0x0B da nhan (tb in ra khi timeout)
    integer    bitpos;
    reg        miso_q;
    reg        drive;
    reg [8*256-1:0] image;
    integer    i;

    assign miso = drive ? miso_q : 1'bz;

    initial begin
        for (i = 0; i < SIZE_BYTES; i = i + 1) mem[i] = 8'hFF;
        nrise = 0; nreads = 0; drive = 1'b0; miso_q = 1'b1; cmd_addr = 32'h0;
        if ($value$plusargs("FLASH_IMAGE=%s", image)) begin
            $readmemh(image, mem);
            $display("[FLASH] nap %0s: header %02h%02h%02h%02h", image,
                     mem[3], mem[2], mem[1], mem[0]);
        end else begin
            $display("[FLASH] khong co +FLASH_IMAGE: flash trong (0xFF), boot ROM se vao park");
        end
    end

    always @(negedge cs_n) begin
        nrise = 0;
        drive = 1'b0;
    end

    always @(posedge cs_n) drive = 1'b0;

    always @(posedge sck) if (cs_n === 1'b0) begin
        if (nrise < 32) cmd_addr = {cmd_addr[30:0], mosi};
        nrise = nrise + 1;
        if (nrise == 32) begin
            if (cmd_addr[31:24] !== 8'h0B)
                $display("[FLASH][WARN] t=%0t lenh %h dia chi %h khong ho tro (chi 0x0B)",
                         $time, cmd_addr[31:24], cmd_addr[23:0]);
            else if (nreads < MAX_LOG)
                $display("[FLASH] t=%0t Fast Read @%06h", $time, cmd_addr[23:0]);
            nreads = nreads + 1;
        end
    end

    // Canh xuong thu 40 (cuoi dummy) day bit 0 cua du lieu; controller chot o
    // canh len thu 41.
    always @(negedge sck) if (cs_n === 1'b0 && nrise >= 40 && cmd_addr[31:24] === 8'h0B) begin
        bitpos = nrise - 40;
        miso_q <= #(T_V_NS) mem[(cmd_addr[23:0] + bitpos / 8) % SIZE_BYTES][7 - bitpos % 8];
        drive  = 1'b1;
    end
endmodule
