module neck_judge(
    input               clk,
	input               rst_n,              //复位信号
    input               en_judge,
	input signed [12:0] first_order_data,   //一阶微分数据输入信号
	input signed [12:0] second_order_data,  //二阶微分数据输入信号
	input signed [12:0] third_order_data,   //三阶微分数据输入信号
	
	output reg          power_switch        //电焊机电源控制管脚
);

//reg [12:0]  count;
//
//always @(posedge clk or negedge rst_n) begin
//    if (!rst_n)
//        power_switch <= 1'b1;
//    else if (en_judge&&first_order_data>30&&second_order_data>30&&third_order_data>-40&&third_order_data<40)      //缩颈开始判断
//        power_switch <= 1'b0;        //缩颈开始关掉电源
//    else if (count == 13'd5000||en_judge&&first_order_data>30&&second_order_data<-20&&third_order_data>-40&&third_order_data<40)//延时50微秒时间到了，或者缩颈结束判断
//        power_switch <= 1'b1;        //缩颈结束打开电源
//    else;
//end
//
//always @(posedge clk or negedge rst_n) begin
//    if (!rst_n)
//        count <= 13'b0;
//    else if (power_switch == 1'b0)      //缩颈开始
//        count <= count + 1'b1;        //开始计时
//    else
//        count <= 13'b0;        //缩颈在50微秒内结束
//end

//测试IGBT驱动电路的PWM程序
reg [12:0] cnt;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        cnt <= 13'b0;
    else if (cnt < 13'd2000)
        cnt <= cnt + 1'b1;
    else
        cnt <= 13'b0;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        power_switch <= 1'b0;
    else if (cnt == 13'd1800)
        power_switch <= 1'b0;
    else if (cnt == 13'd2000)
        power_switch <= 1'b1;
    else;
end

endmodule
