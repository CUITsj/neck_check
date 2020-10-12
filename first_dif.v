module first_dif(
    input                       clk,                //系统时钟
	input                       rst_n,              //复位信号
	input                       en_first_dif,       //一阶微分使能信号
	input [11:0]                current_data,       //一阶微分输入信号

	output reg signed [12:0]    first_dif_data,     //一阶微分输出信号
	output reg                  first_dif_finish    //一阶微分计算完成置1
);

reg signed [12:0] last_one_data;

localparam
    WAIT    = 3'b001,
    DIF     = 3'b010,
    FINISH  = 3'b100;

reg [2:0] state;



always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        state 			 <= WAIT;
        first_dif_data   <= 13'd0;
        last_one_data    <= 13'd0;
        first_dif_finish <= 1'b0;
    end
    else begin
        case(state)
            WAIT: begin
                if(en_first_dif)
                    state <= DIF;
                else
                    state <= WAIT;
            end
            DIF: begin
                last_one_data       <= current_data;
                first_dif_data      <= current_data - last_one_data;
                first_dif_finish    <= 1'b1;
                state               <= FINISH;
            end
            FINISH: begin
                first_dif_finish    <= 1'b0;
                state 			    <= WAIT;
            end
            default: state <= WAIT;
        endcase
    end
end
endmodule
