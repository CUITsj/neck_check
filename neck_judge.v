module neck_judge(
    input               clk,
	input               rst_n,              //复位信号
    input               en_judge,
    input               ctrl_switch,        //控制缩颈算法的引脚
    input signed [12:0] adc_data,             
	input signed [12:0] first_order_data,   //一阶微分数据输入信号
	input signed [12:0] second_order_data,  //二阶微分数据输入信号
	input signed [12:0] third_order_data,   //三阶微分数据输入信号
	
	output reg          power_switch        //电焊机电源控制管脚
);

reg [23:0]  cnt;    //用于IGBT关断时间计数
reg delay_flag;     //延时缩颈判断标志
reg [23:0] cnt1;    //用于延时缩颈判断


//缓存用于比较的一阶微分数值
reg signed [12:0] adc_data_buff1;
reg signed [12:0] adc_data_buff2;
reg signed [12:0] adc_data_buff3;
reg start_check;

//缓存用于比较的一阶微分数值
reg signed [12:0] compare_data_buff1;
reg signed [12:0] compare_data_buff2;
reg signed [12:0] compare_data_buff3;

//调试思路：
//第一步，考虑延长关断时间
//第二部，考虑延迟关断这个动作
//将延时50毫秒改成 AD值4095

//方法一，基于一阶微分判断缩颈过程，找电阻增大最快的点，缩颈检测基于波形出现个数不是基于延时
always @(posedge clk) begin
    if (!rst_n || !ctrl_switch) begin
        power_switch <= 1'b0;//IGBT开
        start_check <= 0;
        compare_data_buff1 <= 0;
        compare_data_buff2 <= 0;
        compare_data_buff3 <= 0;
        
        adc_data_buff1 <= 0;
        adc_data_buff2 <= 0;
        adc_data_buff3 <= 0;
        end
    else if (en_judge) begin      //缩颈开始判断
        compare_data_buff1 <= first_order_data;
        compare_data_buff2 <= compare_data_buff1;
        compare_data_buff3 <= compare_data_buff2;
        
        adc_data_buff1 <= adc_data;
        adc_data_buff2 <= adc_data_buff1;
        adc_data_buff3 <= adc_data_buff2;
        
        if (adc_data_buff3 == 13'd4095 && adc_data_buff2 == 13'd4095 && adc_data_buff1 != 13'd4095 && start_check == 0) //可以开始检测缩颈信号
            start_check <= 1;
        
        if (compare_data_buff1>compare_data_buff2 && compare_data_buff2>compare_data_buff3 && compare_data_buff3>5 && start_check == 1)
            power_switch <= 1'b1;   //IGBT关 //可以考虑将这个关断信号往后延时数微秒

        end
    else if (cnt == 24'd1_00000) begin  //1000_00关断约1毫秒
        power_switch <= 1'b0;           //IGBT开
        start_check <= 0;               //等待下一个缩颈过程再检测
        end
    else;
end

//IGBT关断时间延时
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        cnt <= 0;
    else if (power_switch == 1'b1)      //缩颈开始
        cnt <= cnt + 1;        //开始计时
    else
        cnt <= 0;        //缩颈在50微秒内结束
end



////方法一，基于一阶微分判断缩颈过程，找电阻增大最快的点，但是是基于延时来限制缩颈检测次数。
//always @(posedge clk) begin
//    if (!rst_n || !ctrl_switch) begin
//        power_switch <= 1'b0;//IGBT开
//        delay_flag <= 1'b0;
//        end
//    else if (en_judge) begin      //缩颈开始判断
//        compare_data_buff1 <= first_order_data;
//        compare_data_buff2 <= compare_data_buff1;
//        compare_data_buff3 <= compare_data_buff2;
//        if (compare_data_buff1>compare_data_buff2 && compare_data_buff2>compare_data_buff3 && compare_data_buff3>2 && delay_flag == 0)
//            power_switch <= 1'b1;        //IGBT关 //可以考虑将这个关断信号往后延时数微秒
//        end
//    else if (cnt == 19'd1_00000) begin    //100000关断约1毫秒
//        power_switch <= 1'b0;           //IGBT开
//        delay_flag <= 1'b1;             //延时到下一个缩颈过程再判断
//        end
//    else if (cnt1 == 23'd50_00000)      //5000000延时约50毫秒再判断
//        delay_flag <= 1'b0;
//    else;
//end
////缩颈判断延时
//always @(posedge clk or negedge rst_n) begin
//    if (!rst_n)
//        cnt1 <= 0;
//    else if (delay_flag == 1'b1)    //IGBT开通，开始延时到下一个缩颈过程    
//        cnt1 <= cnt1 + 1;       
//    else
//        cnt1 <= 0;       
//end



////方法一，基于一阶微分判断缩颈过程，找电阻减小最快的点
//always @(posedge clk) begin
//    if (!rst_n || !ctrl_switch) begin
//        power_switch <= 1'b0;//IGBT开
//        delay_flag <= 1'b0;
//        end
//    else if (en_judge) begin      //缩颈开始判断
//        compare_data_buff1 <= first_order_data;
//        compare_data_buff2 <= compare_data_buff1;
//        compare_data_buff3 <= compare_data_buff2;
//        if (compare_data_buff3<-2 && compare_data_buff3>compare_data_buff2 && compare_data_buff2>compare_data_buff1 && delay_flag == 0)
//            power_switch <= 1'b1;        //IGBT关 //可以考虑将这个关断信号往后延时数微秒
//        end
//    else if (cnt == 19'd1_00000) begin    //100000关断约1毫秒
//        power_switch <= 1'b0;           //IGBT开
//        delay_flag <= 1'b1;             //延时到下一个缩颈过程再判断
//        end
//    else if (cnt1 == 23'd50_00000)      //5000000延时约50毫秒再判断
//        delay_flag <= 1'b0;
//    else;
//end



////方法二，基于三阶微分判断缩颈过程
//always @(posedge clk) begin
//    if (!rst_n || !ctrl_switch) begin
//        power_switch <= 1'b0;//IGBT开
//        delay_flag <= 1'b0;
//        end
//    else if (en_judge&&delay_flag==1'b0&&first_order_data>2&&second_order_data>30&&third_order_data>-60&&third_order_data<40)      //缩颈开始判断
//        power_switch <= 1'b1;         //IGBT关 //可以考虑将这个关断信号往后延时数微秒
//    else if (cnt == 24'd5_00000) begin //关断1毫秒
//        power_switch <= 1'b0;         //IGBT开
//        delay_flag <= 1'b1;           //延时到下一个缩颈过程再判断
//        end
//    else if (cnt1 == 24'd500_0000)    //延时50毫秒再判断
//        delay_flag <= 1'b0;
//    else;
//end
////cnt == 13'd5000，50微秒




////测试IGBT驱动电路的PWM程序
//reg [12:0] cnt;
//
//always @(posedge clk or negedge rst_n) begin
//    if (!rst_n)
//        cnt <= 13'b0;
//    else if (cnt < 13'd2000)
//        cnt <= cnt + 1'b1;
//    else
//        cnt <= 13'b0;
//end
//
//always @(posedge clk or negedge rst_n) begin
////    if (!rst_n)
////        power_switch <= 1'b0;
////    else if (cnt == 13'd1800)
////        power_switch <= 1'b0;
////    else if (cnt == 13'd2000)
////        power_switch <= 1'b1;
////    else;
////    power_switch <= 1'b1;//输出-8
//    power_switch <= 1'b0;//输出15
//end

endmodule
