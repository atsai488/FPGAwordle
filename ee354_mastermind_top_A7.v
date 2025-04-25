`timescale 1ns / 1ps

module ee354_mastermind_top_A7(
    // Memory disable
    output wire       QuadSpiFlashCS,

    // Clock & reset
    input  wire       ClkPort,
    input  wire       BtnL, BtnU, BtnD, BtnR, BtnC,
    input  wire       Sw5, Sw4, Sw3, Sw2, Sw1, Sw0,

    // LEDs
    output wire       Ld0, Ld1, Ld2, Ld3, Ld4, Ld5,

    // Seven-segment
    output wire       Cg, Cf, Ce, Cd, Cc, Cb, Ca, Dp,
    output wire       An0, An1, An2, An3, An4, An5, An6, An7,

    // VGA
    output wire       hSync, vSync,
    output wire [3:0] vgaR, vgaG, vgaB
);

  // Disable external memories
  wire MemOE, MemWR, RamCS;
  assign {MemOE, MemWR, RamCS, QuadSpiFlashCS} = 4'b1111;

    // Clock buffering and reset: use direct port clock as system clock
  wire sys_clk = ClkPort;
  // debounced reset
  wire reset_db;

  // Debounced buttons
  wire confirm_color, confirm_guess, left_db, right_db;
  ee354_debouncer #(.N_dc(28)) db_reset   (.CLK(sys_clk), .RESET(BtnU), .PB(BtnU), .SCEN(reset_db));
  ee354_debouncer #(.N_dc(28)) db_color   (.CLK(sys_clk), .RESET(BtnU), .PB(BtnD), .SCEN(confirm_color));
  ee354_debouncer #(.N_dc(28)) db_guess   (.CLK(sys_clk), .RESET(BtnU), .PB(BtnC), .SCEN(confirm_guess));
  ee354_debouncer #(.N_dc(28)) db_right   (.CLK(sys_clk), .RESET(BtnU), .PB(BtnR), .SCEN(right_db));
  ee354_debouncer #(.N_dc(28)) db_left    (.CLK(sys_clk), .RESET(BtnU), .PB(BtnL), .SCEN(left_db));
 
  // FSM signals
  wire [2:0] guessNumber;
  wire [11:0] current_guess;
  wire q_Start, q_Input, q_Check, q_DoneC, q_DoneNC;
  reg  [11:0] correct_answer = 12'b001_001_001_001;
  reg  [2:0]  current_color;
  wire [71:0] matrix_flat;

  reg [1:0] index;
  // Update current_color from switches when in INPUT
  always @(posedge sys_clk, posedge db_reset) 
  begin
	if (db_reset)
	begin
		current_color <= 3'b000; // reset color
		current_guess <= 12'b000000000000; // reset guess
		guessNumber <= 3'b000; // reset guess number

	end
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
		matrix_flat[guessNumber*12 + (index+1)*3 - 1: guessNumber*12 + index*3] <= current_color;
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
