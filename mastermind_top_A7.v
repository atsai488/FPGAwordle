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

    // Seven-segment (off)
    output wire       Cg, Cf, Ce, Cd, Cc, Cb, Ca, Dp,
    output wire       An0, An1, An2, An3, An4, An5, An6, An7,

    // VGA
    output wire       hSync, vSync,
    output wire [3:0] vgaR, vgaG, vgaB
);

  // Disable external memories
  wire MemOE, MemWR, RamCS;
  assign {MemOE,MemWR,RamCS,QuadSpiFlashCS} = 4'b1111;

  // System clock & debounced reset
  wire sys_clk = ClkPort;
  wire reset_db;
  ee354_debouncer #(.N_dc(28)) db_reset(
    .CLK(sys_clk), .RESET(BtnU), .PB(BtnU), .SCEN(reset_db)
  );

  // Debounced control buttons
  wire confirm_color, confirm_guess, left_db, right_db;
  ee354_debouncer #(.N_dc(28)) db_color (
    .CLK(sys_clk), .RESET(BtnU), .PB(BtnD), .SCEN(confirm_color)
  );
  ee354_debouncer #(.N_dc(28)) db_guess (
    .CLK(sys_clk), .RESET(BtnU), .PB(BtnC), .SCEN(confirm_guess)
  );
  ee354_debouncer #(.N_dc(28)) db_right(
    .CLK(sys_clk), .RESET(BtnU), .PB(BtnR), .SCEN(right_db)
  );
  ee354_debouncer #(.N_dc(28)) db_left (
    .CLK(sys_clk), .RESET(BtnU), .PB(BtnL), .SCEN(left_db)
  );

  // FSM interface
  wire [1:0]  cursor_index;
  wire [2:0]  guessNumber;
  wire [11:0] current_guess;
  wire        q_Start, q_Input, q_Check, q_DoneC, q_DoneNC;
  reg  [11:0] correct_answer = 12'b001_001_001_001;
  reg  [2:0]  current_color;

  // Live color selection (reset to gray)
  always @(posedge sys_clk or posedge reset_db) begin
    if (reset_db)
      current_color <= 3'd0;
    else if (q_Input)
      case ({Sw5,Sw4,Sw3,Sw2,Sw1,Sw0})
        6'b000001: current_color <= 3'b001;
        6'b000010: current_color <= 3'b010;
        6'b000100: current_color <= 3'b011;
        6'b001000: current_color <= 3'b100;
        6'b010000: current_color <= 3'b101;
        6'b100000: current_color <= 3'b110;
        default:   current_color <= 3'b000;
      endcase
  end

  // Instantiate FSM core
  mastermind_core core_u(
    .Clk            (sys_clk),
    .Reset          (reset_db),
    .correct_answer (correct_answer),
    .current_color  (current_color),
    .confirm_color  (confirm_color),
    .check_guess    (confirm_guess),
    .BtnL           (left_db),
    .BtnR           (right_db),
    .index          (cursor_index),
    .guess_num      (guessNumber),
    .current_guess  (current_guess),
    .q_Start        (q_Start),
    .q_Input        (q_Input),
    .q_Check        (q_Check),
    .q_DoneC        (q_DoneC),
    .q_DoneNC       (q_DoneNC)
  );

  // Matrix storage and update on check
  reg [11:0] matrix [0:5];
  integer r;
always @(posedge sys_clk or posedge reset_db) begin
  if (reset_db) begin
    for (r = 0; r < 6; r = r + 1)
      matrix[r] <= 12'd0;
  end else if (confirm_color && q_Input) begin
    matrix[guessNumber][cursor_index*3 +: 3] <= current_color;
  end
end


// Flatten matrix into 72-bit register
reg [71:0] matrix_flat;
integer m;

always @(posedge sys_clk or posedge reset_db) begin
  if (reset_db) begin
    matrix_flat <= 72'd0;
  end else begin
    for (m = 0; m < 6; m = m + 1) begin
      matrix_flat[m*12 +: 12] <= matrix[m];
    end
  end
end

  // VGA timing
  wire        bright;
  wire [9:0]  hc, vc;
  display_controller dc(
    .clk    (sys_clk),
    .hSync  (hSync),
    .vSync  (vSync),
    .bright (bright),
    .hCount (hc),
    .vCount (vc)
  );

  // VGA renderer
  mastermind_vga mg_vga(
    .clk           (sys_clk),
    .bright        (bright),
    .hCount        (hc),
    .vCount        (vc),
    .matrix_flat   (matrix_flat),
    .guess_num     (guessNumber),
    .q_Input       (q_Input),
    .cursor_index  (cursor_index),
    .current_color (current_color),
    .vgaR          (vgaR),
    .vgaG          (vgaG),
    .vgaB          (vgaB)
  );

  // LEDs mirror switches
  assign {Ld5,Ld4,Ld3,Ld2,Ld1,Ld0} = {Sw5,Sw4,Sw3,Sw2,Sw1,Sw0};
  // SSDs off
  assign {Cg,Cf,Ce,Cd,Cc,Cb,Ca,Dp}      = 8'hFF;
  assign {An7,An6,An5,An4,An3,An2,An1,An0} = 8'hFF;
endmodule
