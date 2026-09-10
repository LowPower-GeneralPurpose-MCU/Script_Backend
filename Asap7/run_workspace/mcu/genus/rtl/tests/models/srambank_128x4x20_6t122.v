// synchronous SRAM verilog

module srambank_128x4x20_6t122 (
			    input clk
			  , input [8:0] ADDRESS          // address
			  , input [19:0] wd                // data to write
		       	  , input banksel                    // access enable
			  , input read                       // read enable
			  , input write                      // write enable
			  , output reg [19:0] dataout      // latched data output (only updated on read)
			    );

   reg [19:0] 				      mem [511:0];

   always @ (posedge(clk))
     begin                            // should have an error assert on read & write at once...
	if (write & banksel)
	  mem[ADDRESS] <= wd;
	else if (read & banksel)
	  dataout <= mem[ADDRESS];    // output is latched until next read, independent of writes
     end
endmodule // 

 

// ---------------------------------------------------------------------------
// SIMULATION ONLY.  Trong luong synthesis/PnR, srambank_128x4x20_6t122 la hard
// macro doc tu .lib/.lef (xem tcl/rtl_filelist.tcl - file nay CO Y KHONG nam
// trong RTL_FILES).  Nguon: The-OpenROAD-Project/asap7_sram_0p0 @522eecc,
// generated/verilog/srambank_128x4x20_6t122.v, chep nguyen van.
// ---------------------------------------------------------------------------
