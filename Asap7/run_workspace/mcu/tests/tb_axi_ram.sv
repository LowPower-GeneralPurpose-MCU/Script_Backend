`timescale 1ns / 1ps

module tb_axi_ram;
    reg clk = 1'b0;
    reg rst_n = 1'b0;
    always #5 clk = ~clk;

    reg  [4:0]  awid;
    reg  [31:0] awaddr;
    reg  [7:0]  awlen;
    reg  [2:0]  awsize;
    reg  [1:0]  awburst;
    reg         awvalid;
    wire        awready;
    reg  [31:0] wdata;
    reg  [3:0]  wstrb;
    reg         wlast;
    reg         wvalid;
    wire        wready;
    wire [4:0]  bid;
    wire [1:0]  bresp;
    wire        bvalid;

    reg  [4:0]  arid;
    reg  [31:0] araddr;
    reg  [7:0]  arlen;
    reg  [2:0]  arsize;
    reg  [1:0]  arburst;
    reg         arvalid;
    wire        arready;
    wire [4:0]  rid;
    wire [31:0] rdata;
    wire [1:0]  rresp;
    wire        rlast;
    wire        rvalid;

    axi_ram dut (
        .clk(clk), .rst_n(rst_n),
        .s_axi_awid(awid), .s_axi_awaddr(awaddr), .s_axi_awlen(awlen),
        .s_axi_awsize(awsize), .s_axi_awburst(awburst),
        .s_axi_awlock(1'b0), .s_axi_awcache(4'b0), .s_axi_awprot(3'b0),
        .s_axi_awqos(4'b0), .s_axi_awregion(4'b0),
        .s_axi_awvalid(awvalid), .s_axi_awready(awready),
        .s_axi_wdata(wdata), .s_axi_wstrb(wstrb), .s_axi_wlast(wlast),
        .s_axi_wvalid(wvalid), .s_axi_wready(wready),
        .s_axi_bid(bid), .s_axi_bresp(bresp), .s_axi_bvalid(bvalid),
        .s_axi_bready(1'b1),
        .s_axi_arid(arid), .s_axi_araddr(araddr), .s_axi_arlen(arlen),
        .s_axi_arsize(arsize), .s_axi_arburst(arburst),
        .s_axi_arlock(1'b0), .s_axi_arcache(4'b0), .s_axi_arprot(3'b0),
        .s_axi_arqos(4'b0), .s_axi_arregion(4'b0),
        .s_axi_arvalid(arvalid), .s_axi_arready(arready),
        .s_axi_rid(rid), .s_axi_rdata(rdata), .s_axi_rresp(rresp),
        .s_axi_rlast(rlast), .s_axi_rvalid(rvalid), .s_axi_rready(1'b1)
    );

    task automatic write_word;
        input [31:0] address;
        input [31:0] data;
        input [3:0]  strobes;
        begin
            @(negedge clk);
            awid = 5'h03;
            awaddr = address;
            awlen = 0;
            awsize = 3'd2;
            awburst = 2'b01;
            awvalid = 1'b1;
            wait (awready);
            @(negedge clk);
            awvalid = 1'b0;

            wdata = data;
            wstrb = strobes;
            wlast = 1'b1;
            wvalid = 1'b1;
            wait (wready);
            @(negedge clk);
            wvalid = 1'b0;
            wlast = 1'b0;

            wait (bvalid);
            if (bid !== 5'h03 || bresp !== 2'b00)
                $fatal(1, "AXI write response mismatch: id=%h resp=%h", bid, bresp);
            @(negedge clk);
        end
    endtask

    task automatic read_word;
        input [31:0] address;
        input [31:0] expected_data;
        input [1:0]  expected_resp;
        begin
            @(negedge clk);
            arid = 5'h05;
            araddr = address;
            arlen = 0;
            arsize = 3'd2;
            arburst = 2'b01;
            arvalid = 1'b1;
            wait (arready);
            @(negedge clk);
            arvalid = 1'b0;

            wait (rvalid);
            if (rid !== 5'h05 || rresp !== expected_resp || !rlast)
                $fatal(1, "AXI read response mismatch: id=%h resp=%h last=%b",
                    rid, rresp, rlast);
            if (rdata !== expected_data)
                $fatal(1, "AXI read data mismatch at %h: got %h expected %h",
                    address, rdata, expected_data);
            @(negedge clk);
        end
    endtask

    initial begin
        awid = 0;
        awaddr = 0;
        awlen = 0;
        awsize = 0;
        awburst = 0;
        awvalid = 0;
        wdata = 0;
        wstrb = 0;
        wlast = 0;
        wvalid = 0;
        arid = 0;
        araddr = 0;
        arlen = 0;
        arsize = 0;
        arburst = 0;
        arvalid = 0;

        repeat (4) @(posedge clk);
        rst_n = 1'b1;

        write_word(32'h0000_0000, 32'h1122_3344, 4'b1111);
        read_word (32'h0000_0000, 32'h1122_3344, 2'b00);

        write_word(32'h0000_0000, 32'hAABB_CCDD, 4'b0101);
        read_word (32'h0000_0000, 32'h11BB_33DD, 2'b00);

        write_word(32'h0000_1000, 32'hDEAD_BEEF, 4'b1111);
        read_word (32'h0000_1000, 32'hDEAD_BEEF, 2'b00);
        read_word (32'h0000_0000, 32'h11BB_33DD, 2'b00);

        read_word (32'h0000_0002, 32'h0000_0000, 2'b10);

        $display("AXI_SRAM_TEST_PASS");
        $finish;
    end
endmodule

