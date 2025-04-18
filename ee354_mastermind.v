module mastermind_core(Clk, Reset, correct_answer, current_color, confirm_color, check_guess, BtnL, BtnR, index, guess_num, current_guess, q_Start, q_Input, q_Check, q_DoneC, q_DoneNC);


    /*  INPUTS */
    input Clk, Reset;
    input [11:0] correct_answer; // 4 colors of 3 bits each
    input [2:0] current_color; // color input from switches

    // Buttons
    input confirm_color;
    input check_guess;
    input BtnL, BtnR;

    // OUTPUTS
    output reg[2:0] guess_num; // Guess number
    output reg[11:0] current_guess;
    
    // States
    output q_Start, q_Input, q_Check, q_DoneC, q_DoneNC;
    reg [4:0] state;    
    assign {q_Start, q_Input, q_Check, q_DoneC, q_DoneNC} = state;
    reg[1:0] index; // Position of current color cursor
    reg [11:0] target;

    wire all_filled =
        (current_guess[ 2:0] != 3'd0) &&
        (current_guess[ 5:3] != 3'd0) &&
        (current_guess[ 8:6] != 3'd0) &&
        (current_guess[11:9] != 3'd0);
        
    localparam 
    START   = 5'b10000,
    INPUT   = 5'b01000,
    CHECK   = 5'b00100,
    DONEC   = 5'b00010,
    DONENC  = 5'b00001;

    
    // NSL AND SM
    always @ (posedge Clk, posedge Reset)
    begin 
        if(Reset) 
        begin
            state <= START;
            index <= 2'b0;  
            guess_num <= 3'b0;
            target <= 12'b0;
            current_guess <= 12'b0;
        end
        else            
                case(state) 
                    START:
                    begin
                        // state transfers
                        state <= INPUT;
                        // data transfers
                        index <= 2'b0;  
                        guess_num <= 3'b0;
                        target <= correct_answer;
                    end     
                    INPUT: 
                        begin       
                            // state transfers
                            if (check_guess && all_filled)
                                state <= CHECK;
                            // data transfers
                            if (BtnR && (index != 2'b11))
                                index <= index + 1;
                            if (BtnL && (index != 2'b00))
                                index <= index - 1;
                            if (confirm_color)
                                current_guess[index*3 +: 3] <= current_color; // move to the index of index * 3 and input the next 3 bits

                        end
                    CHECK:
                        begin
                            // state transfers
                            if (current_guess == target)
                                state <= DONEC;
                            else if (guess_num == 3'b101)
                                state <= DONENC;
                            else 
                                begin
                                    state <= INPUT;
                                    guess_num <= guess_num + 1;
                                end
                            // data transfers
                        end
                    DONEC:
                    DONENC: 
                endcase
    end
        
endmodule

