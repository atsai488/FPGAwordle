// mastermind_vga.v
`timescale 1ns/1ps
// mastermind_vga.v
`timescale 1ns/1ps
module mastermind_vga (
    input            clk,          // pixel clock (≈25 MHz)
    input            bright,       // from display_controller
    input      [9:0] hCount,       // X coordinate
    input      [9:0] vCount,       // Y coordinate
    input     [71:0] matrix_flat,  // 6 rows × 12 bits each → 72 bits total
    input      [2:0] guess_num,    // current attempt (0-5)
    input            q_Input,      // high while in INPUT state
    output reg [3:0] vgaR,         // 4 bits/channel
    output reg [3:0] vgaG,
    output reg [3:0] vgaB
);

  // unpack the flat 72-bit bus into an internal 6×12 array
  wire [11:0] matrix [5:0];
  genvar i;
  generate
    for (i = 0; i < 24; i = i + 1) begin
      assign matrix[i] = matrix_flat[3*(i+1) - 1 : 3*i];
    end
  endgenerate

  // geometry parameters
  localparam COLS    = 4;
  localparam ROWS    = 6;
  localparam SLOT_W  = 48;    // each peg‐slot square width
  localparam SLOT_H  = 48;    // each peg‐slot square height
  localparam MARGIN  = 16;    // space between slots
  localparam X0      = 300;    // left offset for whole grid
  localparam Y0      = 50;    // top  offset for whole grid

  integer row, col;
  integer x0_slot, y0_slot;
  integer dx, dy;
  reg [11:0] fill_color;

  always @(posedge clk) begin
    if (!bright) begin
      // outside active video
      vgaR <= 4'h0;
      vgaG <= 4'h0;
      vgaB <= 4'h0;

    end else begin
      // default background
      fill_color = 12'h000;

      // are we inside the grid region?
      if (hCount >= X0 &&
          hCount <  X0 + COLS*(SLOT_W+MARGIN)-MARGIN &&
          vCount >= Y0 &&
          vCount <  Y0 + ROWS*(SLOT_H+MARGIN)-MARGIN) begin

        // compute which cell
        col = (hCount - X0) / (SLOT_W + MARGIN);
        row = (vCount - Y0) / (SLOT_H + MARGIN);

        // origin (top-left) of this slot
        x0_slot = X0 + col*(SLOT_W+MARGIN);
        y0_slot = Y0 + row*(SLOT_H+MARGIN);

        // relative coords inside the 48×48 cell
        dx = hCount - x0_slot;
        dy = vCount - y0_slot;

        // draw a circular peg of radius 16px at center (24,24)
        // (dx−24)^2 + (dy−24)^2 < 16^2
        if ((dx-24)*(dx-24) + (dy-24)*(dy-24) <= 16*16) begin
          // get the 3-bit color code from matrix[row]
          case ( matrix[row][col*3 +: 3] )
            3'b001: fill_color = 12'h00F; // blue
            3'b010: fill_color = 12'h0F0; // green
            3'b011: fill_color = 12'h0FF; // cyan
            3'b100: fill_color = 12'hF00; // red
            3'b101: fill_color = 12'hFF0; // yellow
            3'b110: fill_color = 12'hF0F; // magenta
            default: fill_color = 12'h888; // gray for empty
          endcase

        end else begin
          // cell border: highlight the current input row
          if (row == guess_num && q_Input) begin
            // draw a 2px bright border
            if (dx < 2 || dx >= SLOT_W-2 || dy < 2 || dy >= SLOT_H-2)
              fill_color = 12'hFFF;  // white border
          end
        end
      end

      // drive DAC outputs
      vgaR <= fill_color[11:8];
      vgaG <= fill_color[7:4];
      vgaB <= fill_color[3:0];
    end
  end

endmodule
