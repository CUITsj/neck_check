module second_dif(
	input                       clk,                //时钟信号
	input                       rst_n,              //复位信号
	input                       en_second_dif,      //使能二阶微分
	input [12:0]                current_data,       //当前数据
	                                                
	output reg signed [12:0]    second_dif_data,    //微分后数据
	output reg                  second_dif_finish   //微分完成标志
);
reg signed [12:0] last_one_data; //上次输入值
reg signed [12:0] last_two_data; //上上次输入值

localparam
    WAIT    = 3'b001,
    DIF     = 3'b010,
    FINISH  = 3'b100;
    
reg [2:0] state;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        state               <= WAIT;
        second_dif_data     <= 12'd0;
        last_one_data       <= 12'd0;
        last_two_data       <= 12'd0;
        second_dif_finish   <= 1'b0;
    end
    else begin
        case(state)
            WAIT: begin
                if(en_second_dif)
                    state <= DIF;
                else
                    state <= WAIT;
            end        
            DIF: begin
                last_two_data       <= last_one_data;
                last_one_data       <= current_data;
                second_dif_data     <= (current_data-last_one_data)-(last_one_data-last_two_data);
                second_dif_finish   <= 1'b1;
                state               <= FINISH;
            end
            FINISH: begin
                second_dif_finish   <= 1'b0;
                state               <= WAIT;
            end
            default: state <= WAIT;
        endcase  
    end
end	
endmodule
