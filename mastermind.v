`timescale 1ns / 1ps

module mastermind_vga(
    input            clk,
    input            bright,
    input      [9:0] hCount,
    input      [9:0] vCount,
    input     [71:0] matrix_flat,
    input      [2:0] guess_num,
    input            q_Input,
    input      [1:0] cursor_index,
    input      [2:0] current_color,
    output reg [3:0] vgaR,
    output reg [3:0] vgaG,
    output reg [3:0] vgaB
);

  // Unpack 6×12-bit words
  wire [11:0] matrix [0:5];
  genvar i;
  generate
    for (i = 0; i < 6; i = i + 1)
      assign matrix[i] = matrix_flat[i*12 +: 12];
  endgenerate

  // Grid geometry (fixed location)
  localparam COLS=4, ROWS=6;
  localparam SLOT_W=48, SLOT_H=48, MARGIN=16;
  localparam X0=300, Y0=50;

  integer row, col, x0_slot, y0_slot, dx, dy;
  reg [11:0] fill_color;

  always @(posedge clk) begin
    if (!bright) begin
      vgaR <= 0; vgaG <= 0; vgaB <= 0;
    end else begin
      fill_color = 12'h000;
      if (hCount>=X0 && hCount< X0+COLS*(SLOT_W+MARGIN)-MARGIN &&
          vCount>=Y0 && vCount< Y0+ROWS*(SLOT_H+MARGIN)-MARGIN) begin
        col     = (hCount - X0)/(SLOT_W+MARGIN);
        row     = (vCount - Y0)/(SLOT_H+MARGIN);
        x0_slot = X0 + col*(SLOT_W+MARGIN);
        y0_slot = Y0 + row*(SLOT_H+MARGIN);
        dx      = hCount - x0_slot;
        dy      = vCount - y0_slot;
        if ((dx-24)*(dx-24)+(dy-24)*(dy-24) <= 256) begin
          if (matrix[row][col*3 +:3] != 3'd0) begin
            case (matrix[row][col*3 +:3])
              3'b001: fill_color=12'h00F;
              3'b010: fill_color=12'h0F0;
              3'b011: fill_color=12'h0FF;
              3'b100: fill_color=12'hF00;
              3'b101: fill_color=12'hFF0;
              3'b110: fill_color=12'hF0F;
            endcase
          end else if (row==guess_num && col==cursor_index && q_Input) begin
            case (current_color)
              3'b001: fill_color=12'h00F;
              3'b010: fill_color=12'h0F0;
              3'b011: fill_color=12'h0FF;
              3'b100: fill_color=12'hF00;
              3'b101: fill_color=12'hFF0;
              3'b110: fill_color=12'hF0F;
            endcase
          end
        end else if (row==guess_num && q_Input) begin
          if (dx<2||dx>=SLOT_W-2||dy<2||dy>=SLOT_H-2)
            fill_color=12'hFFF;
        end
      end
      vgaR<=fill_color[11:8];
      vgaG<=fill_color[7:4];
      vgaB<=fill_color[3:0];
    end
  end
endmodule
