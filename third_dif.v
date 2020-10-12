module third_dif(
	input                       clk,                //时钟信号
	input                       rst_n,              //复位信号
	input                       en_third_dif,       //使能三阶微分
	input [11:0]                current_data,       //当前数据
                                                   
	output reg signed [12:0]    third_dif_data,     //微分后数据
	output reg                  third_dif_finish    //微分完成标志
);

reg signed [12:0] last_one_data;    //上次的输入值
reg signed [12:0] last_two_data;    //上上次的输入值
reg signed [12:0] last_three_data;  //上上上次的输入值

localparam
    WAIT    = 3'b001,
    DIF     = 3'b010,
    FINISH  = 3'b100;

reg [2:0]state;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        state               <= WAIT;
        third_dif_data      <= 13'd0;
        last_one_data       <= 13'd0;
        last_two_data       <= 13'd0;
        last_three_data     <= 13'd0;
        third_dif_finish    <= 1'b0;
    end
    else begin
        case(state)
            WAIT: begin
                if(en_third_dif)
                    state <= DIF;
                else
                    state <= WAIT;
            end
            DIF: begin
                last_three_data     <= last_two_data;
                last_two_data       <= last_one_data;
                last_one_data       <= current_data;
                third_dif_data      <= (current_data-last_one_data)-(last_one_data-last_two_data)-(last_one_data-last_two_data)+(last_two_data-last_three_data);
                third_dif_finish    <= 1'b1;
                state               <= FINISH;
            end
            FINISH: begin
                third_dif_finish    <=  1'b0;
                state               <=  WAIT;
            end
            default: state <= WAIT;
        endcase
            
    end
end
endmodule
