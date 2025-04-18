//////////////////////////////////////////////////////////////////////////////////
// Author:			Shideh Shahidi, Bilal Zafar, Gandhi Puvvada
// Create Date:		02/25/08
// File Name:		ee354_GCD_top.v 
// Description: 
//
//
// Revision: 		2.2
// Additional Comments: 
// 10/13/2008 debouncing and single_clock_wide pulse_generation modules are added by Gandhi
// 10/13/2008 Clock Enable (CEN) has been added by Gandhi
//  3/ 1/2010 The Spring 2009 debounce design is replaced by the Spring 2010 debounce design
//            Now, in part 2 of the GCD lab, we do single-stepping 
//  2/19/2012 Nexys-2 to Nexys-3 conversion done by Gandhi
//  02/24/2020 Nexys-3 to Nexys-4 conversion done by Yue (Julien) Niu and reviewed by Gandhi
//////////////////////////////////////////////////////////////////////////////////



module ee354_GCD_top
		(//MemOE, MemWR, RamCS, 
		QuadSpiFlashCS, // Disable the three memory chips

        ClkPort,                           // the 100 MHz incoming clock signal
		
		BtnL, BtnU, BtnD, BtnR,            // the Left, Up, Down, and the Right buttons BtnL, BtnR,
		BtnC,                              // the center button (this is our reset in most of our designs)
		Sw5, Sw4, Sw3, Sw2, Sw1, Sw0, // 6 switches
		Ld5, Ld4, Ld3, Ld2, Ld1, Ld0, // 6 LEDs
		An3, An2, An1, An0,			       // 4 anodes
		An7, An6, An5, An4,                // another 4 anodes which are not used
		Ca, Cb, Cc, Cd, Ce, Cf, Cg,        // 7 cathodes
		Dp                                 // Dot Point Cathode on SSDs
	  );

	/*  INPUTS */
	// Clock & Reset I/O
	input		ClkPort;	
	// Project Specific Inputs
	input		BtnL, BtnU, BtnD, BtnR, BtnC;	
	input		Sw5, Sw4, Sw3, Sw2, Sw1, Sw0;
	
	
	/*  OUTPUTS */
	// Control signals on Memory chips 	(to disable them)
	//output 	MemOE, MemWR, RamCS, 
	output QuadSpiFlashCS;
	// Project Specific Outputs
	// LEDs
	output 	Ld0, Ld1, Ld2, Ld3, Ld4, Ld5;
	// SSD Outputs
	output 	Cg, Cf, Ce, Cd, Cc, Cb, Ca, Dp;
	output 	An0, An1, An2, An3;	
	output 	An4, An5, An6, An7;	

	
	/*  LOCAL SIGNALS */
	wire		Reset, ClkPort;
	wire		board_clk, sys_clk;
	wire [1:0] 	ssdscan_clk;
	reg [26:0]	DIV_CLK;
	
	wire enter;
	reg[2:0] guessNumber;
	wire q_Start, q_Input, q_Check, q_DoneC, q_DoneNC;
	reg [11:0] correct_answer;
	reg [5:0] colorIn;
	reg [2:0] current_color;
	reg [5:0] matrix [11:0];
	
//------------	
// Disable the three memories so that they do not interfere with the rest of the design.
	assign {MemOE, MemWR, RamCS, QuadSpiFlashCS} = 4'b1111;
	
	
//------------
// CLOCK DIVISION

	// The clock division circuitary works like this:
	//
	// ClkPort ---> [BUFGP2] ---> board_clk
	// board_clk ---> [clock dividing counter] ---> DIV_CLK
	// DIV_CLK ---> [constant assignment] ---> sys_clk;
	
	BUFGP BUFGP1 (board_clk, ClkPort); 	

// As the ClkPort signal travels throughout our design,
// it is necessary to provide global routing to this signal. 
// The BUFGPs buffer these input ports and connect them to the global 
// routing resources in the FPGA.

	assign Reset = BtnU;
	
//-------------------	
	// In this design, we run the core design at full 100MHz clock!
	assign	sys_clk = board_clk;
	// assign	sys_clk = DIV_CLK[25];

//------------
// INPUT: SWITCHES & BUTTONS
	// BtnL is used as both Start and Acknowledge. 
	// To make this possible, we need a single clock producing  circuit.

ee354_debouncer #(.N_dc(28)) ee354_debouncer_2 
        (.CLK(sys_clk), .RESET(Reset), .PB(BtnU), .DPB(), 
		.SCEN(enter), .MCEN( ), .CCEN( ));

//--------------
// LEDs
	assign {Ld7, Ld6} = {0, 0};
	assign {Ld5, Ld4, Ld3, Ld2, Ld1, Ld0} = {Sw5, Sw4, Sw3, Sw2, Sw1, Sw0}; // Reset is driven by BtnC
		 		
//------------
// DESIGN
	// On two pushes of BtnR, numbers A and B are recorded in Ain and Bin
    // (registers of the TOP) respectively
	always @ (posedge sys_clk, posedge Reset)
	begin
		if(Reset)
		begin			
			colorIn <= 6'b000000;
			correct_answer <= 12'b001001001001;
		end
		else
		begin
			if(q_Input)
			begin 
				colorIn <= {Sw5, Sw4, Sw3, Sw2, Sw1, Sw0};
				//VGA stuff
			end
			if(q_Check)
			begin
				matrix[guessNumber] <= current_guess;
				//tell em what they did wrong
			end
		end
	end
	
//
//------------
	always @(posedge colorIn)
	begin
		case(colorIn)
			6'b000001: current_color <= 3'b001; 
			6'b000010: current_color <= 3'b010; 
			6'b000100: current_color <= 3'b011; 
			6'b001000: current_color <= 3'b100; 
			6'b010000: current_color <= 3'b101; 
			6'b100000: current_color <= 3'b110; 
			default: current_color <= 3'b000;   
		endcase
	end	
	// the state machine module
	mastermind_core mastermind_core_1(.Clk(ClkPort), .Reset(Reset), .correct_answer(correct_answer), .current_color(current_color), 
									.confirm_color(BtnD), .check_guess(BtnC), .BtnL(BtnL), .BtnR(BtnR), guess_num(guessNumber), 
									current_guess(current_guess), q_Start(q_Start), q_Input(q_Input), q_Check(q_Check), q_DoneC(q_DoneC), q_DoneNC(q_DoneNC));




endmodule

