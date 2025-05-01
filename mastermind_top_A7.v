//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    12:18:00 12/14/2017 
// Design Name: 
// Module Name:    vga_top 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
// Date: 04/04/2020
// Author: Yue (Julien) Niu
// Description: Port from NEXYS3 to NEXYS4
//////////////////////////////////////////////////////////////////////////////////
module ee354_mastermind_top_A7(
	input ClkPort,
	input BtnC,
	input BtnU,
	input BtnR,
	input BtnL,
	input BtnD,
  input Sw5, Sw4, Sw3, Sw2, Sw1, Sw0,
	//VGA signal
	output hSync, vSync,
	output [3:0] vgaR, vgaG, vgaB,
	output Ld0, Ld1, Ld2, Ld3, Ld4, Ld5,
  
	//SSD signal 
	output An0, An1, An2, An3, An4, An5, An6, An7,
	output Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp,
	
	//output MemOE, MemWR, RamCS,
	output  QuadSpiFlashCS
	);

	// Clock buffering and reset: use direct port clock as system clock
  wire sys_clk = ClkPort;
  // debounced reset
  wire reset_db;

  // Debounced buttons
  wire confirm_color, confirm_guess, left_db, right_db;
  ee354_debouncer #(.N_dc(28)) db_reset   (.CLK(sys_clk), .RESET(BtnU), .PB(BtnU), .SCEN(reset_db));
  ee354_debouncer #(.N_dc(28)) db_color   (.CLK(sys_clk), .RESET(reset_db), .PB(BtnD), .SCEN(confirm_color));
  ee354_debouncer #(.N_dc(28)) db_guess   (.CLK(sys_clk), .RESET(reset_db), .PB(BtnC), .SCEN(confirm_guess));
  ee354_debouncer #(.N_dc(28)) db_right   (.CLK(sys_clk), .RESET(reset_db), .PB(BtnR), .SCEN(right_db));
  ee354_debouncer #(.N_dc(28)) db_left    (.CLK(sys_clk), .RESET(reset_db), .PB(BtnL), .SCEN(left_db));
 
  // FSM signals
  wire [2:0] guessNumber;
  wire [11:0] current_guess;
  wire q_Start, q_Input, q_Check, q_DoneC, q_DoneNC;
  reg  [11:0] correct_answer = 12'b001_001_001_001;
  reg  [2:0]  current_color;
  reg [71:0] matrix_flat;

  wire [1:0] index;
  // Update current_color from switches when in INPUT
  always @(posedge sys_clk) 
  begin
  if (q_Input) begin
    case ({Sw5,Sw4,Sw3,Sw2,Sw1,Sw0})
		6'b000001: current_color <= 3'b001;
		6'b000010: current_color <= 3'b010;
		6'b000100: current_color <= 3'b011;
		6'b001000: current_color <= 3'b100;
		6'b010000: current_color <= 3'b101;
		6'b100000: current_color <= 3'b110;
		default:   current_color <= 3'b000;
    endcase
		if (q_Input && confirm_color) begin
        matrix_flat[guessNumber * 12 + index * 3 +: 3] <= current_color;
        end
	end
  end

  // Instantiate game core
  mastermind_core core_u (
    .Clk           (sys_clk),
    .Reset         (reset_db),
    .correct_answer(correct_answer),
    .current_color (current_color),
    .confirm_color (confirm_color),
    .check_guess   (confirm_guess),
    .BtnL          (left_db),
    .BtnR          (right_db),
    .index         (index),           // unused here
    .guess_num     (guessNumber),
    .current_guess (current_guess),
    .q_Start       (q_Start),
    .q_Input       (q_Input),
    .q_Check       (q_Check),
    .q_DoneC       (q_DoneC),
    .q_DoneNC      (q_DoneNC)
  );


  // VGA timing
  wire        bright;
  wire [9:0]  hc, vc;
  display_controller dc (
    .clk    (ClkPort),
    .hSync  (hSync),
    .vSync  (vSync),
    .bright (bright),
    .hCount (hc),
    .vCount (vc)
  );

  // Mastermind VGA renderer
  mastermind_vga mg_vga (
    .clk         (ClkPort),
    .bright      (bright),
    .hCount      (hc),
    .vCount      (vc),
    .matrix_flat (matrix_flat),
    .guess_num   (guessNumber),
    .q_Input     (q_Input),
    .vgaR        (vgaR),
    .vgaG        (vgaG),
    .vgaB        (vgaB)
  );

  // Drive LEDs and SSDs (example)
  assign {Ld5,Ld4,Ld3,Ld2,Ld1,Ld0} = {Sw5,Sw4,Sw3,Sw2,Sw1,Sw0};
  assign {An7,An6,An5,An4,An3,An2,An1,An0} = 8'b1111_1111;

	

endmodule
