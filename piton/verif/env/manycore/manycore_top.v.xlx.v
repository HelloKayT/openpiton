// Modified by Princeton University on June 9th, 2015
// ========== Copyright Header Begin ==========================================
//
// OpenSPARC T1 Processor File: cmp_top.v
// Copyright (c) 2006 Sun Microsystems, Inc.  All Rights Reserved.
// DO NOT ALTER OR REMOVE COPYRIGHT NOTICES.
//
// The above named program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public
// License version 2 as published by the Free Software Foundation.
//
// The above named program is distributed in the hope that it will be
// useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public
// License along with this work; if not, write to the Free Software
// Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA.
//
// ========== Copyright Header End ============================================
////////////////////////////////////////////////////////

`include "sys.h"
`include "iop.h"
`include "cross_module.tmp.h"
`include "ifu.h"
`include "define.vh"

//`define PITON_PROTO_SYNTH
//`define PITON_PROTO

`ifdef PITON_PROTO_SYNTH
    `define PITON_PROTO
    `define PITON_PROTO_CLK
`elsif PITON_PROTO
    `define PITON_PROTO_CLK
`endif // PITON_PROTO_SYNTH   

`ifndef PITON_PROTO_SYNTH
    `timescale 1ps/1ps
`endif // PITON_PROTO_SYNTH


module cmp_top (
`ifdef PITON_PROTO_SYNTH
    input       fast_clk,
    input       pin_rst,

    output      led_0,
    output      led_1,
    output      led_2,
    output      led_3,
    output      led_4,
    output      led_5,
    output      led_6

`endif // PITON_PROTO_SYNTH
);

`ifdef PITON_PROTO_SYNTH
wire    chip_rst_n;

assign chip_rst_n = ~pin_rst;
`endif // PITON_PROTO_SYNTH


//-------------------------------------------------
// Respective clock frequencies for a prototype:
//-------------------------------------------------
// fast_clk     - 33 MHZ from FPGA pin
// core_ref_clk - 6.666 MHZ - to meet chip timing
// fpga_clk     - core_ref_clk / 5      ? Alexey 
// jtag_clk     - ~core_ref_clk / 13    ? Alexey


`ifdef PITON_PROTO_CLK

    wire    io_clk;
    wire    fpga_clk;
    wire    jtag_clk;
    wire    core_ref_clk;

    `ifndef PITON_PROTO_SYNTH
    
        reg         fast_clk;
        reg         chip_rst_n;
        initial begin
            chip_rst_n = 0;
            fast_clk = 0;
            repeat(100)@(posedge core_ref_clk);
            repeat(10)@(posedge chip.clk_muxed);
            repeat(300)@(posedge chip.clk_muxed);
            chip_rst_n = 1;
        end

        always #500  fast_clk  = ~fast_clk;     // - ?? 1000MHz

    `endif // PITON_PROTO_SYNTH

    assign io_clk   = core_ref_clk;
    assign fpga_clk = core_ref_clk;
    assign jtag_clk = core_ref_clk;


    clk_18MHz clk_module (
        .CLK_IN1    (fast_clk),
        .CLK_OUT1   (core_ref_clk)
    );

`else // PITON_PROTO_CLK isn't defined

    // reg rst_n;
    reg clk_en;
    reg core_ref_clk;

    reg io_clk;
    reg fpga_clk;
    reg jtag_clk;
    reg jtag_rst_l;
    reg          chip_rst_n;
    reg          pll_rst_n;

    `ifndef NO_SIM_PLL
    always #5000 core_ref_clk = ~core_ref_clk;     // 100MHz
    `else
    always #500 core_ref_clk = ~core_ref_clk;    // 1000MHz
    `endif

    `ifndef SYNC_MUX
    always #1429 io_clk = ~io_clk;                 // 350MHz
    `else
    always @ * io_clk = core_ref_clk;
    `endif
    always #2500 fpga_clk = ~fpga_clk;           // 200MHz
    //assign fpga_clk = pin_clk;                // 
    always #6529 jtag_clk = ~jtag_clk;         // <~100MHz

`endif // PITON_PROTO_CLK


`ifdef PITON_PROTO_SYNTH

blinker blinker(
    .clk                (core_ref_clk   ),
    .rst_n              (chip_rst_n     ),

    .GPIO_LED_0         (led_0          ),
    .GPIO_LED_1         (led_1          ),
    .GPIO_LED_2         (led_2          ),
    .GPIO_LED_3         (led_3          ),
    .GPIO_LED_4         (led_4          ),
    .GPIO_LED_5         (led_5          ),
    .GPIO_LED_6         (led_6          )
 );

`endif // PITON_PROTO_SYNTH

////////////////////////////////////////////////////////
// SYNTHESIZABLE CHIP
////////////////////////////////////////////////////////
    wire         pll_lock;
    reg          pll_bypass;
    reg [4:0]    pll_rangea;
    reg [1:0]    clk_mux_sel;
    // wire         pll_clk;
    wire          async_mux;

    wire [31:0]  intf_chip_data;
    wire [1:0]   intf_chip_channel;
    wire [2:0]   intf_chip_credit_back;

    wire [31:0]  chip_intf_data;
    wire [1:0]   chip_intf_channel;
    wire [2:0]   chip_intf_credit_back;

    // Alexey
    assign pll_lock = 1'b1;


    chip chip(
        // Fastest setting for I/O's
        // .slew (1'b1),
        // .impsel1 (1'b1),
        // .impsel2 (1'b1),
        .core_ref_clk(core_ref_clk),
        .io_clk(io_clk),
        .rst_n(chip_rst_n),
        // .pll_rst_n(pll_rst_n),
        // .clk_en(clk_en),
        // .pll_bypass (pll_bypass),
        // .async_mux (async_mux),

        // .pll_lock (pll_lock),
        // .pll_bypass (pll_bypass),
        // .pll_rangea (pll_rangea),
        // .clk_mux_sel (clk_mux_sel),
        // .pll_clk (pll_clk),
        
        // JTAG pins
        // .jtag_clk(jtag_clk),
        // .jtag_rst_l(jtag_rst_l),
        // .jtag_modesel(1'b0),
        // .jtag_datain(1'b0),
        // .jtag_dataout(),

        .intf_chip_data(intf_chip_data),
        .intf_chip_channel(intf_chip_channel),
        .intf_chip_credit_back(intf_chip_credit_back),

        .chip_intf_data(chip_intf_data),
        .chip_intf_channel(chip_intf_channel),
        .chip_intf_credit_back(chip_intf_credit_back)
    );

////////////////////////////////////////////////////////
// fpga to chip bridge
////////////////////////////////////////////////////////

    wire                         fpga_offfpga_noc1_valid = 1'b0;
    wire [`NOC_DATA_WIDTH-1:0]   fpga_offfpga_noc1_data = 64'b0;
    wire                         fpga_offfpga_noc1_yummy;
    wire                         fpga_offfpga_noc2_valid;
    wire [`NOC_DATA_WIDTH-1:0]   fpga_offfpga_noc2_data;
    wire                         fpga_offfpga_noc2_yummy;
    wire                         fpga_offfpga_noc3_valid;
    wire [`NOC_DATA_WIDTH-1:0]   fpga_offfpga_noc3_data;
    wire                         fpga_offfpga_noc3_yummy = 1'b0;

    wire                         offfpga_fpga_noc1_valid;
    wire [`NOC_DATA_WIDTH-1:0]   offfpga_fpga_noc1_data;
    wire                         offfpga_fpga_noc1_yummy;
    wire                         offfpga_fpga_noc2_valid;
    wire [`NOC_DATA_WIDTH-1:0]   offfpga_fpga_noc2_data;
    wire                         offfpga_fpga_noc2_yummy;
    wire                         offfpga_fpga_noc3_valid;
    wire [`NOC_DATA_WIDTH-1:0]   offfpga_fpga_noc3_data;
    wire                         offfpga_fpga_noc3_yummy;

    wire                         fpga_intf_noc1_valid;
    wire [`NOC_DATA_WIDTH-1:0]   fpga_intf_noc1_data;
    wire                         fpga_intf_noc1_rdy;
    wire                         fpga_intf_noc2_valid;
    wire [`NOC_DATA_WIDTH-1:0]   fpga_intf_noc2_data;
    wire                         fpga_intf_noc2_rdy;
    wire                         fpga_intf_noc3_valid;
    wire [`NOC_DATA_WIDTH-1:0]   fpga_intf_noc3_data;
    wire                         fpga_intf_noc3_rdy;

    wire                         intf_fpga_noc1_valid;
    wire [`NOC_DATA_WIDTH-1:0]   intf_fpga_noc1_data;
    wire                         intf_fpga_noc1_rdy;
    wire                         intf_fpga_noc2_valid;
    wire [`NOC_DATA_WIDTH-1:0]   intf_fpga_noc2_data;
    wire                         intf_fpga_noc2_rdy;
    wire                         intf_fpga_noc3_valid;
    wire [`NOC_DATA_WIDTH-1:0]   intf_fpga_noc3_data;
    wire                         intf_fpga_noc3_rdy;

    wire [31:0]                  intf_fpga_data;
    wire [1:0]                   intf_fpga_channel;
    wire [2:0]                   intf_fpga_credit_back;

    wire [31:0]                  fpga_intf_data;
    wire [1:0]                   fpga_intf_channel;
    wire [2:0]                   fpga_intf_credit_back;

    assign intf_chip_data = fpga_intf_data;
    assign intf_chip_channel = fpga_intf_channel;
    assign chip_intf_credit_back = intf_fpga_credit_back;

    assign intf_fpga_data = chip_intf_data;
    assign intf_fpga_channel = chip_intf_channel;
    assign fpga_intf_credit_back = intf_chip_credit_back;

    `ifndef SYNC_MUX
        assign async_mux = 1'b1;
    `else
        assign async_mux = 1'b0;
    `endif

    //assign intf_chip_noc1_valid = fpga_intf_noc1_valid;
    //assign intf_chip_noc1_data = fpga_intf_noc1_data;
    //assign intf_chip_noc1_rdy = fpga_intf_noc1_rdy;
    //assign intf_chip_noc2_valid = fpga_intf_noc2_valid;
    //assign intf_chip_noc2_data = fpga_intf_noc2_data;
    //assign intf_chip_noc2_rdy = fpga_intf_noc2_rdy;
    //assign intf_chip_noc3_valid = fpga_intf_noc3_valid;
    //assign intf_chip_noc3_data = fpga_intf_noc3_data;
    //assign intf_chip_noc3_rdy = fpga_intf_noc3_rdy;

    //assign intf_fpga_noc1_valid = chip_intf_noc1_valid;
    //assign intf_fpga_noc1_data = chip_intf_noc1_data;
    //assign intf_fpga_noc1_rdy = chip_intf_noc1_rdy;
    //assign intf_fpga_noc2_valid = chip_intf_noc2_valid;
    //assign intf_fpga_noc2_data = chip_intf_noc2_data;
    //assign intf_fpga_noc2_rdy = chip_intf_noc2_rdy;
    //assign intf_fpga_noc3_valid = chip_intf_noc3_valid;
    //assign intf_fpga_noc3_data = chip_intf_noc3_data;
    //assign intf_fpga_noc3_rdy = chip_intf_noc3_rdy;




    valrdy_to_credit #(4, 3) fpga_to_intf_noc1_v2c(
        .clk(fpga_clk),
        .reset(~chip_rst_n),
        .data_in(intf_fpga_noc1_data),
        .valid_in(intf_fpga_noc1_valid),
        .ready_in(fpga_intf_noc1_rdy),

        .data_out(offfpga_fpga_noc1_data),           // Data
        .valid_out(offfpga_fpga_noc1_valid),       // Val signal
        .yummy_out(fpga_offfpga_noc1_yummy)    // Yummy signal
    );

    credit_to_valrdy fpga_from_intf_noc1_c2v(
        .clk(fpga_clk),
        .reset(~chip_rst_n),
        .data_in(fpga_offfpga_noc1_data),
        .valid_in(fpga_offfpga_noc1_valid),
        .yummy_in(offfpga_fpga_noc1_yummy),

        .data_out(fpga_intf_noc1_data),           // Data
        .valid_out(fpga_intf_noc1_valid),       // Val signal from dynamic network to processor
        .ready_out(intf_fpga_noc1_rdy)    // Rdy signal from processor to dynamic network
    );

    valrdy_to_credit #(4, 3) fpga_to_intf_noc2_v2c(
        .clk(fpga_clk),
        .reset(~chip_rst_n),
        .data_in(intf_fpga_noc2_data),
        .valid_in(intf_fpga_noc2_valid),
        .ready_in(fpga_intf_noc2_rdy),

        .data_out(offfpga_fpga_noc2_data),           // Data
        .valid_out(offfpga_fpga_noc2_valid),       // Val signal
        .yummy_out(fpga_offfpga_noc2_yummy)    // Yummy signal
    );

    credit_to_valrdy fpga_from_intf_noc2_c2v(
        .clk(fpga_clk),
        .reset(~chip_rst_n),
        .data_in(fpga_offfpga_noc2_data),
        .valid_in(fpga_offfpga_noc2_valid),
        .yummy_in(offfpga_fpga_noc2_yummy),

        .data_out(fpga_intf_noc2_data),           // Data
        .valid_out(fpga_intf_noc2_valid),       // Val signal from dynamic network to processor
        .ready_out(intf_fpga_noc2_rdy)    // Rdy signal from processor to dynamic network
    );

    valrdy_to_credit #(4, 3) fpga_to_intf_noc3_v2c(
        .clk(fpga_clk),
        .reset(~chip_rst_n),
        .data_in(intf_fpga_noc3_data),
        .valid_in(intf_fpga_noc3_valid),
        .ready_in(fpga_intf_noc3_rdy),

        .data_out(offfpga_fpga_noc3_data),           // Data
        .valid_out(offfpga_fpga_noc3_valid),       // Val signal
        .yummy_out(fpga_offfpga_noc3_yummy)    // Yummy signal
    );

    credit_to_valrdy fpga_from_intf_noc3_c2v(
        .clk(fpga_clk),
        .reset(~chip_rst_n),
        .data_in(fpga_offfpga_noc3_data),
        .valid_in(fpga_offfpga_noc3_valid),
        .yummy_in(offfpga_fpga_noc3_yummy),

        .data_out(fpga_intf_noc3_data),           // Data
        .valid_out(fpga_intf_noc3_valid),       // Val signal from dynamic network to processor
        .ready_out(intf_fpga_noc3_rdy)    // Rdy signal from processor to dynamic network
    );

    fpga_bridge fpga_intf(
        .rst_n                  (chip_rst_n),
        .fpga_clk               (fpga_clk),
        .intcnct_clk            (io_clk),
        .network_out_1          (fpga_intf_noc1_data),
        .network_out_2          (fpga_intf_noc2_data),
        .network_out_3          (fpga_intf_noc3_data),
        .data_out_val_1         (fpga_intf_noc1_valid),
        .data_out_val_2         (fpga_intf_noc2_valid),
        .data_out_val_3         (fpga_intf_noc3_valid),
        .data_out_rdy_1         (intf_fpga_noc1_rdy),
        .data_out_rdy_2         (intf_fpga_noc2_rdy),
        .data_out_rdy_3         (intf_fpga_noc3_rdy),
        .intcnct_data_in        (intf_fpga_data),
        .intcnct_channel_in     (intf_fpga_channel),
        .intcnct_credit_back_in (intf_fpga_credit_back),
        .network_in_1           (intf_fpga_noc1_data),
        .network_in_2           (intf_fpga_noc2_data),
        .network_in_3           (intf_fpga_noc3_data),
        .data_in_val_1          (intf_fpga_noc1_valid),
        .data_in_val_2          (intf_fpga_noc2_valid),
        .data_in_val_3          (intf_fpga_noc3_valid),
        .data_in_rdy_1          (fpga_intf_noc1_rdy),
        .data_in_rdy_2          (fpga_intf_noc2_rdy),
        .data_in_rdy_3          (fpga_intf_noc3_rdy),
        .intcnct_data_out       (fpga_intf_data),
        .intcnct_channel_out    (fpga_intf_channel),
        .intcnct_credit_back_out(fpga_intf_credit_back)
    );

////////////////////////////////////////////////////////
// fake memory controller
////////////////////////////////////////////////////////
    // input: noc2
    // output: noc3
    // Memory controller val/rdy interface
    wire mem_noc2_valid_in;
    wire mem_noc2_ready_in;
    wire [`NOC_DATA_WIDTH-1:0] mem_noc2_data_in;
    wire mem_noc3_valid_out;
    wire mem_noc3_ready_out;
    wire [`NOC_DATA_WIDTH-1:0] mem_noc3_data_out;

    valrdy_to_credit #(4, 3) cgno_blk_mem(
        .clk(fpga_clk),
        .reset(~chip_rst_n),
        .data_in(mem_noc3_data_out),
        .valid_in(mem_noc3_valid_out),
        .ready_in(mem_noc3_ready_out),

        .data_out(fpga_offfpga_noc3_data),           // Data
        .valid_out(fpga_offfpga_noc3_valid),       // Val signal
        .yummy_out(offfpga_fpga_noc3_yummy)    // Yummy signal
    );
    credit_to_valrdy cgni_blk_mem(
        .clk(fpga_clk),
        .reset(~chip_rst_n),
        .data_in(offfpga_fpga_noc2_data),
        .valid_in(offfpga_fpga_noc2_valid),
        .yummy_in(fpga_offfpga_noc2_yummy),

        .data_out(mem_noc2_data_in),           // Data
        .valid_out(mem_noc2_valid_in),       // Val signal from dynamic network to processor
        .ready_out(mem_noc2_ready_in)    // Rdy signal from processor to dynamic network
    );
    fake_mem_ctrl fake_mem_ctrl(
        .clk                (fpga_clk),
        .rst_n              (chip_rst_n),
        .noc_valid_in       (mem_noc2_valid_in),
        .noc_data_in        (mem_noc2_data_in),
        .noc_ready_in       (mem_noc2_ready_in),
        .noc_valid_out      (mem_noc3_valid_out),
        .noc_data_out       (mem_noc3_data_out),
        .noc_ready_out      (mem_noc3_ready_out)
    );

////////////////////////////////////////////////////////
// iobridge rtl/stub
////////////////////////////////////////////////////////

    // input: noc1
    // output: noc2
    // Iob val/rdy interface
    wire iob_noc1_valid_in;
    wire iob_noc1_ready_in;
    wire [`NOC_DATA_WIDTH-1:0] iob_noc1_data_in;
    wire iob_noc2_valid_out;
    wire iob_noc2_ready_out;
    wire [`NOC_DATA_WIDTH-1:0] iob_noc2_data_out;

    valrdy_to_credit #(4, 3) cgno_blk_iob(
        .clk(fpga_clk),
        .reset(~chip_rst_n),
        .data_in(iob_noc2_data_out),
        .valid_in(iob_noc2_valid_out),
        .ready_in(iob_noc2_ready_out),
        .data_out(fpga_offfpga_noc2_data),           // Data
        .valid_out(fpga_offfpga_noc2_valid),       // Val signal
        .yummy_out(offfpga_fpga_noc2_yummy)    // Yummy signal
    );
    credit_to_valrdy cgni_blk_iob(
        .clk(fpga_clk),
        .reset(~chip_rst_n),
        .data_in(offfpga_fpga_noc1_data),
        .valid_in(offfpga_fpga_noc1_valid),
        .yummy_in(fpga_offfpga_noc1_yummy),
        .data_out(iob_noc1_data_in),           // Data
        .valid_out(iob_noc1_valid_in),       // Val signal from dynamic network to processor
        .ready_out(iob_noc1_ready_in)    // Rdy signal from processor to dynamic network
    );

    ciop_iob ciop_iob     (
        .chip_clk       (core_ref_clk           ),
        .fpga_clk       (fpga_clk               ),
        .rst_n          (chip_rst_n             ),
        
        .noc_in_val     (iob_noc1_valid_in      ),
        .noc_in_rdy     (iob_noc1_ready_in      ),
        .noc_in_data    (iob_noc1_data_in       ),

        .noc_out_val    (iob_noc2_valid_out     ),
        .noc_out_rdy    (iob_noc2_ready_out     ),
        .noc_out_data   (iob_noc2_data_out      )
    );

////////////////////////////////////////////////////////
// MONITOR STUFF
////////////////////////////////////////////////////////
`ifndef PITON_PROTO_SYNTH

    reg diag_done;
    reg fail_flag;
    reg [3:0] stub_done;
    reg [3:0] stub_pass;
    reg init_done;
    integer j;

    // Tri: slam init is taken out because it's too complicated to extend to 64 cores
    // slam_init slam_init () ;

    // The only thing that we will "slam init" is the integer register file
    //  and it is randomized. For some reason if we left it as X's some tests will fail
    
initial begin
    $slam_random(`SPARC_REG0.bw_r_irf_core.register01.bw_r_irf_register.window, 8, 0);
    $slam_random(`SPARC_REG0.bw_r_irf_core.register02.bw_r_irf_register.window, 8, 0);
    $slam_random(`SPARC_REG0.bw_r_irf_core.register03.bw_r_irf_register.window, 8, 0);
    $slam_random(`SPARC_REG0.bw_r_irf_core.register04.bw_r_irf_register.window, 8, 0);
    $slam_random(`SPARC_REG0.bw_r_irf_core.register05.bw_r_irf_register.window, 8, 0);
    $slam_random(`SPARC_REG0.bw_r_irf_core.register06.bw_r_irf_register.window, 8, 0);
    $slam_random(`SPARC_REG0.bw_r_irf_core.register07.bw_r_irf_register.window, 8, 0);
    $slam_random(`SPARC_REG0.bw_r_irf_core.register08.bw_r_irf_register.window, 8, 0);
    $slam_random(`SPARC_REG0.bw_r_irf_core.register09.bw_r_irf_register.window, 8, 0);
    $slam_random(`SPARC_REG0.bw_r_irf_core.register10.bw_r_irf_register.window, 8, 0);
    $slam_random(`SPARC_REG0.bw_r_irf_core.register11.bw_r_irf_register.window, 8, 0);
    $slam_random(`SPARC_REG0.bw_r_irf_core.register12.bw_r_irf_register.window, 8, 0);
    $slam_random(`SPARC_REG0.bw_r_irf_core.register13.bw_r_irf_register.window, 8, 0);
    $slam_random(`SPARC_REG0.bw_r_irf_core.register14.bw_r_irf_register.window, 8, 0);
    $slam_random(`SPARC_REG0.bw_r_irf_core.register15.bw_r_irf_register.window, 8, 0);
    $slam_random(`SPARC_REG0.bw_r_irf_core.register16.bw_r_irf_register.window, 16, 0);
    $slam_random(`SPARC_REG0.bw_r_irf_core.register17.bw_r_irf_register.window, 16, 0);
    $slam_random(`SPARC_REG0.bw_r_irf_core.register18.bw_r_irf_register.window, 16, 0);
    $slam_random(`SPARC_REG0.bw_r_irf_core.register19.bw_r_irf_register.window, 16, 0);
    $slam_random(`SPARC_REG0.bw_r_irf_core.register20.bw_r_irf_register.window, 16, 0);
    $slam_random(`SPARC_REG0.bw_r_irf_core.register21.bw_r_irf_register.window, 16, 0);
    $slam_random(`SPARC_REG0.bw_r_irf_core.register22.bw_r_irf_register.window, 16, 0);
    $slam_random(`SPARC_REG0.bw_r_irf_core.register23.bw_r_irf_register.window, 16, 0);
    $slam_random(`SPARC_REG0.bw_r_irf_core.register24.bw_r_irf_register.window, 8, 0);
    $slam_random(`SPARC_REG0.bw_r_irf_core.register25.bw_r_irf_register.window, 8, 0);
    $slam_random(`SPARC_REG0.bw_r_irf_core.register26.bw_r_irf_register.window, 8, 0);
    $slam_random(`SPARC_REG0.bw_r_irf_core.register27.bw_r_irf_register.window, 8, 0);
    $slam_random(`SPARC_REG0.bw_r_irf_core.register28.bw_r_irf_register.window, 8, 0);
    $slam_random(`SPARC_REG0.bw_r_irf_core.register29.bw_r_irf_register.window, 8, 0);
    $slam_random(`SPARC_REG0.bw_r_irf_core.register30.bw_r_irf_register.window, 8, 0);
    $slam_random(`SPARC_REG0.bw_r_irf_core.register31.bw_r_irf_register.window, 8, 0);
end

`endif // PITON_PROTO_SYNTH


////////////////////////////////////////////////////////
// BOOT SEQUENCE
////////////////////////////////////////////////////////
`ifndef PITON_PROTO_CLK
    initial
    begin
        fail_flag = 0;
        stub_done = 0;
        stub_pass = 0;
        init_done = 0;
        //`ifdef ORAM_ON
        if ($test$plusargs("oram"))
        begin
            $init_jbus_model("mem.image", 1);
            force chip.ctap_oram_clk_en = 1'b1;
        //`else
        end
        else
        begin
            $init_jbus_model("mem.image", 0);
        //`endif
        end

        pll_rst_n = 0;           // reset is held low upon boot up
        chip_rst_n = 0;
        jtag_rst_l = 0;
        io_clk = 0;
        core_ref_clk = 0;
        fpga_clk = 0;
        jtag_clk = 0;
        pll_bypass = 1'b0;
        // assign rangeA = x10 ? 5'b1 : x5 ? 5'b11110 : x2 ? 5'b10100 : x1 ? 5'b10010 : x20 ? 5'b0 : 5'b1;
        pll_rangea = 5'b00001; // 10x ref clock
        // pll_rangea = 5'b11110; // 5x ref clock
        // pll_rangea = 5'b00000; // 20x ref clock

        if ($test$plusargs("pll_en"))
        begin
            // PLL is disabled by default
            pll_bypass = 1'b0; // trin: pll_bypass is a switch in the pll; not reliable
            clk_mux_sel[1:0] = 2'b10; // selecting pll
            // clk_mux_sel[1:0] = 2'b01; // selecting pll
        end
        else
        begin
            pll_bypass = 1'b1; // trin: pll_bypass is a switch in the pll; not reliable
            clk_mux_sel[1:0] = 2'b00; // selecting ref clock
        end
        
        repeat(100)@(posedge core_ref_clk);
        pll_rst_n = 1;           // deassert reset

        wait( pll_lock == 1'b1 );   // wait for PLL, regardless if we use it or not

        repeat(10)@(posedge chip.clk_muxed);
        clk_en = 1;          // turn on clock for all tiles
        repeat(100)@(posedge chip.clk_muxed);
        chip_rst_n = 1;
        jtag_rst_l = 1'b1;

        repeat(5000)@(posedge chip.clk_muxed);     // wait for sram wrappers; trin: 5000 cycles is about the lowest

        diag_done = 1;       // ???
        ciop_iob.ok_iob = 1'b1;    // send wake up packet to first tile
        init_done = 1;       // ???
    end
`endif // PITON_PROTO_CLK
    


`ifndef PITON_PROTO_SYNTH
    // T1's TSO monitor, stripped of all L2 references
    tso_mon tso_mon(clk, `SPARC_CORE0.reset_l);

    // this is the T1 sparc core monitor
    monitor   monitor(
        .clk    (chip.clk_muxed),
        .cmp_gclk  (chip.clk_muxed),
        .rst_l     (`SPARC_CORE0.reset_l)
        );

    // L15 MONITORS
    cmp_l15_messages_mon l15_messages_mon(
        .clk (chip.clk_muxed)
        );

    // DMBR MONITOR
    dmbr_mon dmbr_mon (
        .clk(chip.clk_muxed)
     );

    //L2 MONITORS
    `ifdef FAKE_L2
    `else
    l2_mon l2_mon(
        .clk (chip.clk_muxed)
    );
    `endif

    //only works if clk == fpga_clk
    //async_fifo_mon async_fifo_mon(
    //   .clk (core_ref_clk)
    //);

    jtag_mon jtag_mon(
        .clk (clk)
        );

    `ifndef PITON_PROTO
        iob_mon iob_mon(
            .clk (fpga_clk)
        );
    `endif // PITON_PROTO

    // sas, more debug info

    // turn on sas interface after a delay
//    reg   need_sas_sparc_intf_update;
//    initial begin
//        need_sas_sparc_intf_update  = 0;
//        #12500;
//        need_sas_sparc_intf_update  = 1;
//    end // initial begin

    // sas_intf  sas_intf(/*AUTOINST*/
    //     // Inputs
    //     .clk       (chip.clk_muxed),      // Templated
    //     .rst_l     (`SPARC_CORE0.reset_l));       // Templated

    // create sas tasks
    // sas_tasks sas_tasks(/*AUTOINST*/
    //     // Inputs
    //     .clk      (chip.clk_muxed),      // Templated
    //     .rst_l        (`SPARC_CORE0.reset_l));       // Templated

    // sparc pipe flow monitor
    sparc_pipe_flow sparc_pipe_flow(/*AUTOINST*/
        // Inputs
        .clk  (chip.clk_muxed));         // Templated


    // initialize client to communicate with ref model through socket
    integer   vsocket, i, list_handle;
    initial begin
        //list_handle = $bw_list(list_handle, 0);chin's change
         //if not use sas, list should not be called
        if($test$plusargs("use_sas_tasks"))begin
            list_handle = $bw_list(list_handle, 0);
                $bw_socket_init();
        end
    end

   manycore_network_mon network_mon (pll_clk);

`endif // PITON_PROTO_SYNTH

endmodule // cmp_top
