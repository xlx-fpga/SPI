// Author : XiaiBai FPGA
// File   : tb_spi_master.v
// Create : 2023-11-15 16:52:37
// -----------------------------------------------------------------------------

`timescale 1ns / 1ps



module tb_spi_master(

    );



	parameter      SYS_CLK_FREQ = 50000000;
	parameter      SPI_CLK_FREQ = 12500000;
	parameter        ADDR_WIDTH = 24;




	reg clk;
	reg reset;

	wire                  spi_sck;
	wire                  spi_cs;
	wire                  spi_sdo;
	wire                  spi_sdi = 1;

	reg                     spi_start;
	wire              [7:0] spi_cmd    = 8'h01;
	wire [ADDR_WIDTH-1:0]   spi_addr   = 24'haabbcc;
	wire           [11:0]   spi_length = 5;
	wire                    spi_busy;
	wire                    spi_wr_req;
	wire            [7:0]   spi_wr_data = 8'haa;
	wire                   spi_rd_vld;
	wire            [7:0]  spi_rd_data;	





	initial begin
		clk = 0;
		forever #(10) 
		clk = ~clk;
	end

	initial begin
		reset = 1;
	    #(200) 
		reset = 0;
	end

	initial begin
		spi_start <= 0;
	    #290 
		spi_start <= 1;
		#20
		spi_start <= 0;
	end





	spi_master #(
			.SYS_CLK_FREQ(SYS_CLK_FREQ),
			.SPI_CLK_FREQ(SPI_CLK_FREQ),
			.ADDR_WIDTH(ADDR_WIDTH)
		) spi_master (
			.clk         (clk),
			.rst       (reset),

			.spi_sck     (spi_sck),
			.spi_cs      (spi_cs),
			.spi_sdo     (spi_sdo),
			.spi_sdi     (spi_sdi),

			.spi_start   (spi_start),
			.spi_cmd     (spi_cmd),
			.spi_addr    (spi_addr),
			.spi_length  (spi_length),
			.spi_busy    (spi_busy),
			.spi_wr_req  (spi_wr_req),
			.spi_wr_data (spi_wr_data),
			.spi_rd_vld  (spi_rd_vld),
			.spi_rd_data (spi_rd_data)
		);




endmodule
