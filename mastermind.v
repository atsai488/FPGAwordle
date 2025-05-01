`timescale 1ns / 1ps

module mastermind_vga (
    input            clk,
    input            bright,
    input      [9:0] hCount,
    input      [9:0] vCount,
    input     [71:0] matrix_flat,
    input      [2:0] guess_num,
    input            q_Input,
    input      [1:0] cursor_index,
    input      [2:0] current_color,
    input            q_DoneC,        // <— new input
    output reg [3:0] vgaR,
    output reg [3:0] vgaG,
    output reg [3:0] vgaB
);

  // unpack 6×12
  wire [11:0] matrix [0:5];
  genvar i;
  generate
    for (i = 0; i < 6; i = i + 1)
      assign matrix[i] = matrix_flat[i*12 +:12];
  endgenerate

  // geometry
  localparam COLS=4, ROWS=6;
  localparam SLOT_W=48, SLOT_H=48, MARGIN=16;
  localparam X0=300, Y0=50;
  localparam GRID_W = COLS*(SLOT_W+MARGIN)-MARGIN;
  localparam GRID_H = ROWS*(SLOT_H+MARGIN)-MARGIN;

  integer row, col, x0_slot, y0_slot, dx, dy;
  reg [11:0] fill_color;

  always @(posedge clk) begin
    if (!bright) begin
      // blanking → black
      vgaR <= 0; vgaG <= 0; vgaB <= 0;

    end else if (q_DoneC) begin
      // DONEC → full‐screen green
      vgaR <= 4'h0; 
      vgaG <= 4'hF; 
      vgaB <= 4'h0;

    end else begin
      // normal Mastermind rendering
      fill_color = 12'h000;
      if (hCount>=X0 && hCount<X0+GRID_W &&
          vCount>=Y0 && vCount<Y0+GRID_H) begin

        col     = (hCount - X0)/(SLOT_W+MARGIN);
        row     = (vCount - Y0)/(SLOT_H+MARGIN);
        x0_slot = X0 + col*(SLOT_W+MARGIN);
        y0_slot = Y0 + row*(SLOT_H+MARGIN);
        dx      = hCount - x0_slot;
        dy      = vCount - y0_slot;

        // confirmed peg
        if ((dx-24)*(dx-24)+(dy-24)*(dy-24) <= 256 &&
            matrix[row][col*3 +:3] != 3'd0) begin
          case (matrix[row][col*3 +:3])
            3'b001: fill_color = 12'h00F;
            3'b010: fill_color = 12'h0F0;
            3'b011: fill_color = 12'h0FF;
            3'b100: fill_color = 12'hF00;
            3'b101: fill_color = 12'hFF0;
            3'b110: fill_color = 12'hF0F;
          endcase

        // live preview peg
        end else if ((dx-24)*(dx-24)+(dy-24)*(dy-24) <= 256 &&
                     row==guess_num && col==cursor_index && q_Input) begin
          case (current_color)
            3'b001: fill_color = 12'h00F;
            3'b010: fill_color = 12'h0F0;
            3'b011: fill_color = 12'h0FF;
            3'b100: fill_color = 12'hF00;
            3'b101: fill_color = 12'hFF0;
            3'b110: fill_color = 12'hF0F;
          endcase

        // active-row border
        end else if (row==guess_num && q_Input) begin
          if (dx<2||dx>=SLOT_W-2||dy<2||dy>=SLOT_H-2)
            fill_color = 12'hFFF;
        end
      end

      // drive DAC
      vgaR <= fill_color[11:8];
      vgaG <= fill_color[ 7:4];
      vgaB <= fill_color[ 3:0];
    end
  end

endmodule
