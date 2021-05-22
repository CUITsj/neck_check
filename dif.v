module dif(
    input                       clk,
	input                       rst_n,              //复位信号
	input                       en_dif,             //使能三阶微分
	input signed [12:0]         current_data,       //当前数据
    
    output reg signed [12:0]    first_dif_data,     //一阶微分输出信号
    output reg signed [12:0]    second_dif_data,    //微分后数据
	output reg signed [12:0]    third_dif_data,     //微分后数据
    
	output reg                  dif_finish    //微分完成标志
);

reg signed [12:0] last_one_data;    //上次的输入值
reg signed [12:0] last_two_data;    //上上次的输入值
reg signed [12:0] last_three_data;  //上上上次的输入值

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        first_dif_data      <= 13'd0;
        second_dif_data     <= 13'd0;
        third_dif_data      <= 13'd0;
        last_one_data       <= 13'd0;
        last_two_data       <= 13'd0;
        last_three_data     <= 13'd0;
        dif_finish          <= 1'b0;
    end
    else if (en_dif) begin
        first_dif_data      <= current_data-last_one_data;
        second_dif_data     <= current_data-last_one_data-last_one_data+last_two_data;
        third_dif_data      <= current_data-last_one_data-last_one_data+last_two_data-last_one_data+last_two_data+last_two_data-last_three_data;
        last_three_data     <= last_two_data;
        last_two_data       <= last_one_data;
        last_one_data       <= current_data;
        dif_finish          <= 1'b1;
    end
    else
        dif_finish          <= 1'b0;
end
endmodule
