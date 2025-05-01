module mastermind_core(
    input  wire        Clk,
    input  wire        Reset,
    input  wire [11:0] correct_answer,  // 4 colors × 3 bits
    input  wire [2:0]  current_color,    // from switches
    input  wire        confirm_color,
    input  wire        check_guess,
    input  wire        BtnL,
    input  wire        BtnR,
    output reg  [1:0]  index,         
    output reg  [2:0]  guess_num,
    output reg  [11:0] current_guess,
    output wire        q_Start,
    output wire        q_Input,
    output wire        q_Check,
    output wire        q_DoneC,
    output wire        q_DoneNC
);
    reg  [4:0] state;
    assign { q_Start, q_Input, q_Check, q_DoneC, q_DoneNC } = state;

    reg [11:0] target;
    wire all_filled = 
        current_guess[ 2:0] != 3'd0 &&
        current_guess[ 5:3] != 3'd0 &&
        current_guess[ 8:6] != 3'd0 &&
        current_guess[11:9] != 3'd0;

    localparam 
      START   = 5'b10000,
      INPUT   = 5'b01000,
      CHECK   = 5'b00100,
      DONEC   = 5'b00010,
      DONENC  = 5'b00001;

    always @(posedge Clk or posedge Reset) begin
        if (Reset) begin
            state         <= START;
            index         <= 2'd0;
            guess_num     <= 3'd0;
            target        <= 12'd0;
            current_guess <= 12'd0;
        end else begin
            case (state)
              START: begin
                state         <= INPUT;
                index         <= 2'd0;
                guess_num     <= 3'd0;
                target        <= correct_answer;
                current_guess <= 12'd0;  // clear the buffer on new game
              end

              INPUT: begin
                if (check_guess && all_filled)
                  state <= CHECK;
                if (BtnR && index != 2'b11)
                  index <= index + 1;
                else if (BtnL && index != 2'b00)
                  index <= index - 1;
                if (confirm_color)
                  current_guess[index*3 +: 3] <= current_color;
              end

              CHECK: begin
                if (current_guess == target)
                  state <= DONEC;
                else if (guess_num == 3'd5)
                  state <= DONENC;
                else begin
                  state     <= INPUT;
                  guess_num <= guess_num + 1;
                end
              end

              DONEC: begin end 
              DONENC: begin end

              default: state <= START;
            endcase
        end
    end

endmodule
