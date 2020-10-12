module neck_judge(
	input               rst_n,              //复位信号
    input               en_judge,
	input signed [12:0] first_order_data,   //一阶微分数据输入信号
	input signed [12:0] second_order_data,  //二阶微分数据输入信号
	input signed [12:0] third_order_data,   //三阶微分数据输入信号
	
	output reg          power_switch        //电焊机电源控制管脚
);

always @(en_judge or rst_n) begin
    if (!rst_n)
        power_switch = 1'b1;
    else if (en_judge&&first_order_data>12&&second_order_data>22&&third_order_data>-25&&third_order_data<29)      //缩颈开始判断
        power_switch = 1'b0;        //缩颈开始关掉电源
    else if (en_judge&&first_order_data>12&&second_order_data<-19&&third_order_data>-25&&third_order_data<29)     //缩颈结束判断
        power_switch = 1'b1;        //缩颈结束打开电源
    else
        power_switch = 1'b1;        //正常运行打开电源
end
endmodule
