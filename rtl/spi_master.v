`timescale 1ns / 1ns
//****************************************VSCODE PLUG-IN**********************************// 
//---------------------------------------------------------------------------------------- 
// IDE :                   VSCODE      
// VSCODE plug-in version: Verilog-Hdl-Format-2.4.20240526
// VSCODE plug-in author : Jiang Percy 
//---------------------------------------------------------------------------------------- 
//****************************************Copyright (c)***********************************// 
// Copyright(C)            xlx_fpga
// All rights reserved      
// File name:               
// Last modified Date:     2024/07/10 15:19:34 
// Last Version:           V1.0 
// Descriptions:            
//---------------------------------------------------------------------------------------- 
// Created by:             xlx_fpga
// Created date:           2024/07/10 15:19:34 
// Version:                V1.0 
// TEXT NAME:              spi_master.v 
// PATH:                   E:\3.xlx_fpga\6.SPI\rtl\spi_master.v 
// Descriptions:            
//                          
//---------------------------------------------------------------------------------------- 
//****************************************************************************************// 

module spi_master#(
    parameter                                   SYS_CLK_FREQ       = 50_000_000,
    parameter                                   SPI_CLK_FREQ       = 12_500_000,
    parameter                                   ADDR_WIDTH         = 24    
)
(
    input                                       clk                 ,
    input                                       rst                 ,
    //***************************************************************************************
    // SPI物理接口                                                                                    
    //***************************************************************************************
    output reg                                  spi_sck             ,
    output reg                                  spi_cs              ,
    output                                      spi_sdo             ,
    input                                       spi_sdi             ,
    //***************************************************************************************
    // SPI用户接口                                                                                    
    //***************************************************************************************
    input                                       spi_start           ,
    input              [7: 0]                   spi_cmd             ,//给从机的命令
    input              [ADDR_WIDTH-1: 0]        spi_addr            ,//给从机的地址
    input              [11: 0]                  spi_length          ,//读写数据长度
    input              [7: 0]                   spi_wr_data         ,
    output reg         [7: 0]                   spi_rd_data         ,
    output reg                                  spi_busy            ,
    output reg                                  spi_wr_req          ,
    output reg                                  spi_rd_vld           
);
    localparam                                  DIV_CNT_MAX        = SYS_CLK_FREQ / SPI_CLK_FREQ - 1;
    localparam                                  DIV_CNT_MAX_HALF   = DIV_CNT_MAX  /2; 

    reg                [$clog2(DIV_CNT_MAX)-1: 0]div_cnt            ;
    reg                [2: 0]                   bit_cnt             ;
    reg                [12: 0]                  byte_cnt            ;

    reg                [11: 0]                  spi_length_d0       ;
    reg                [ADDR_WIDTH-1: 0]        spi_addr_d0         ;

    reg                [7: 0]                   send_data           ;

//***************************************************************************************
// 锁存数据长度                                                                                    
//***************************************************************************************
    always @(posedge clk )
        begin
            if(rst) begin
                spi_length_d0 <= 0;
        end
            else if(spi_start) begin
                spi_length_d0 <= spi_length;
        end
            else begin
                spi_length_d0 <= spi_length_d0;
        end
        end
//***************************************************************************************
// div_cnt                                                                                    
//***************************************************************************************
    always @(posedge clk )
        begin
            if(rst) begin
                div_cnt <= 0;
        end
            else if(spi_cs) begin
                div_cnt <= 0;
        end
            else if(div_cnt == DIV_CNT_MAX) begin
                div_cnt <= 0;
        end
            else begin
                div_cnt <= div_cnt +1;
        end
        end
//***************************************************************************************
// bit_cnt                                                                                  
//***************************************************************************************  
    always @(posedge clk )
        begin
            if(rst) begin
                bit_cnt <= 0;
        end
            else if(bit_cnt == 7 && div_cnt == DIV_CNT_MAX) begin
                bit_cnt <= 0;
        end
            else if(div_cnt == DIV_CNT_MAX) begin
                bit_cnt <= bit_cnt +1;
        end
            else begin
                bit_cnt <= bit_cnt;
        end
        end
//***************************************************************************************
// byte_cnt                                                                                    
//***************************************************************************************
    always @(posedge clk )
        begin
            if(rst) begin
                byte_cnt <= 0;
        end
            else if(bit_cnt == (spi_length_d0 + ADDR_WIDTH/8) && bit_cnt == 7 && div_cnt == DIV_CNT_MAX) begin
                byte_cnt <= 0;
        end
            else if(bit_cnt == 7 && div_cnt == DIV_CNT_MAX) begin
                byte_cnt <= byte_cnt +1;
        end
            else begin
                byte_cnt <= byte_cnt;
        end
        end
//***************************************************************************************
// cs                                                                                    
//***************************************************************************************
    always @(posedge clk) begin
            if(rst)
                spi_cs <= 1;
            else if(div_cnt == DIV_CNT_MAX && bit_cnt == 7 && byte_cnt == (spi_length_d0 + ADDR_WIDTH/8))
                spi_cs <= 1;
            else if(spi_start)
                spi_cs <= 0;
        end
//***************************************************************************************
// 锁存地址                                                                                    
//*************************************************************************************** 
    always @(posedge clk )
        begin
            if(rst) begin
                spi_addr_d0 <= 0;
        end
            else if(spi_start) begin
                spi_addr_d0 <= spi_addr;
        end
            else if(byte_cnt <= ADDR_WIDTH/8 && bit_cnt == 7 && div_cnt ==DIV_CNT_MAX) begin
                spi_addr_d0 <= spi_addr_d0 >> 8;
        end
            else begin
                spi_addr_d0 <= spi_addr_d0;
        end
        end
//***************************************************************************************
// spi_sck                                                                                    
//*************************************************************************************** 
    always @(posedge clk )
        begin
            if(rst) begin
                spi_sck <= 0;
        end
            else if(div_cnt == DIV_CNT_MAX_HALF) begin
                spi_sck <= 1;
        end
            else if(div_cnt == DIV_CNT_MAX) begin
                spi_sck <= 0;
        end
            else begin
                spi_sck <= spi_sck;
        end
        end
//***************************************************************************************
// sdo                                                                                    
//***************************************************************************************
    assign                                      spi_sdo            = send_data[0];

//***************************************************************************************
// send_data                                                                                    
//***************************************************************************************
    always @(posedge clk )
        begin
            if(rst) begin
                send_data <= 0;
        end
            else if(spi_start) begin
                send_data <= spi_cmd;
        end
            else if(byte_cnt <= ADDR_WIDTH/8 -1 && bit_cnt == 7 && div_cnt ==DIV_CNT_MAX) begin
                send_data <= spi_addr_d0[7:0];
        end
            else if(byte_cnt >= ADDR_WIDTH/8  && bit_cnt == 7 && div_cnt ==DIV_CNT_MAX) begin
                send_data <= spi_wr_data;
        end
            else if(div_cnt == DIV_CNT_MAX) begin
                send_data <= send_data >>1;
        end
            else begin
                                                         
        end
        end

//***************************************************************************************
// wr_req                                                                                    
//***************************************************************************************
    always @(posedge clk) begin
            if(rst)
                spi_wr_req <= 0;
            else if(~spi_cs && byte_cnt >= ADDR_WIDTH/8 && bit_cnt == 7 && div_cnt == DIV_CNT_MAX - 2 )
                spi_wr_req <= 1;
            else 
                spi_wr_req <= 0;
        end
//***************************************************************************************
// rd_data                                                                                    
//***************************************************************************************
    always @(posedge clk )
        begin
            if(rst) begin
                spi_rd_data <= 0;
        end
            else if(byte_cnt>= ADDR_WIDTH/8 +1 &&  div_cnt == DIV_CNT_MAX_HALF) begin
                spi_rd_data <= {spi_sdi,spi_rd_data[7:1]};
        end
            else begin
                spi_rd_data <= spi_rd_data;
        end
        end
//***************************************************************************************
// rd_vld                                                                                    
//*************************************************************************************** 
    always @(posedge clk )
        begin
            if(rst) begin
                spi_rd_vld <= 0;
        end
            else if(byte_cnt>= ADDR_WIDTH/8 +1 && bit_cnt == 7 && div_cnt == DIV_CNT_MAX) begin
                spi_rd_vld <= 1;
        end
            else begin
                spi_rd_vld <= 0;
        end
        end
//***************************************************************************************
// busy                                                                                    
//***************************************************************************************
    always @(posedge clk )
        begin
            if(rst) begin
                    spi_busy =0;
        end
            else if(~spi_cs) begin
                    spi_busy =1;
        end
            else begin
                    spi_busy =spi_busy;
        end
        end
        endmodule
