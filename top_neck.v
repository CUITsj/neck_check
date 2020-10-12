module top_neck(
	input   sys_clk,            //系统时钟
	input   sys_rst_n,          //系统复位
	input   ads7883_sdo,        //adc模块数据端口
	output  ads7883_sclk,       //adc模块时钟信号
	output  ads7883_ncs,        //adc模块片选信号
	output  necking_signal      //缩颈信号端口
);

//ip核       
wire clk_100m;                              //100MHz时钟信号
wire rst_n;                                 //复位信号
wire locked;                                //locked信号拉高,锁相环开始稳定输出时钟 
        
//ADC      
wire adc_finish_flag;                       //adc模块转换完成标志
wire signed [11:0] adc_data;                //adc最终数据

//kalman滤波      
wire signed [11:0] filtered_data;           //卡尔曼滤波后数据
wire filter_finish;                         //卡尔曼滤波完成标志
        
//一阶微分      
wire signed [11:0] first_dif_data;          //一阶微分输出数据
wire first_dif_finish;                      //一阶微分完成标志
        
//二阶微分      
wire signed [11:0] second_dif_data;         //二阶微分输出数据
wire second_dif_finish;                     //二阶微分完成标志
        
//三阶微分      
wire signed [11:0] third_dif_data;          //三阶微分输出数据
wire third_dif_finish;                      //三阶微分完成标志

//缩颈判断
wire judge_finish;                          //缩颈信号判断完毕标志
        
//系统复位与锁相环locked相与,作为其它模块的复位信号 
assign  rst_n = sys_rst_n & locked; 
    
//例化PLL IP核
pll_clk u_pll_clk(
    .areset             (~sys_rst_n),       //复位取反
    .inclk0             (sys_clk),          //50MHz时钟
    .c0                 (clk_100m),         //100MHz时钟
    .locked             (locked)            //locked信号拉高,锁相环开始稳定输出时钟 
);

//例化ADC模块
ads7883_ctrl #(
    .CLK_STEP           (2)                //ADC时钟步长
) u_ads7883_ctrl(
    .clk                (clk_100m),         //adc时钟
    .rst_n              (rst_n),            //复位
    .en_adc             (1),	            //开始转换使能信号
    .data_upflag        (adc_finish_flag),	//转换完成信号
    .adc_data           (adc_data),	        //采样结果
    .ads7883_sdo        (ads7883_sdo),      //adc模块数据端口
    .ads7883_sclk       (ads7883_sclk),     //adc模块时钟端口
    .ads7883_ncs        (ads7883_ncs)       //adc模块片选端口
);

//例化卡尔曼滤波模块
kalman_filter #(
    .Q                  (1),                //过程噪声协方差
    .R                  (400)               //观测噪声协方差
) u_kalman_filter(                          
    .clk                (clk_100m),         //时钟信号
    .rst_n              (rst_n),            //复位信号
    .en_kalman          (adc_finish_flag),  //滤波使能信号
    .origin_data        (adc_data),         //滤波原始数据
    .filtered_data      (filtered_data),    //滤波后数据
    .filter_finish      (filter_finish)     //滤波完成标志
);                                          

//例化一阶微分模块
first_dif u_first_dif(
    .clk                (clk_100m),         //时钟信号
    .rst_n              (rst_n),            //复位信号
    .en_first_dif       (adc_finish_flag),  //一阶微分使能信号
    .current_data       (filtered_data),    //一阶微分前数据  之前用的没滤波的数据是错误的
    .first_dif_data     (first_dif_data),   //一阶微分后数据
    .first_dif_finish   (first_dif_finish)  //一阶微分完成标志
);

//例化二阶微分模块
second_dif u_second_dif(
    .clk                (clk_100m),         //时钟信号
    .rst_n              (rst_n),            //复位信号
    .en_second_dif      (adc_finish_flag),  //二阶微分使能信号
    .current_data       (filtered_data),    //二阶微分前数据
    .second_dif_data    (second_dif_data),  //二阶微分后数据
    .second_dif_finish  (second_dif_finish) //二阶微分完成标志
);

//例化三阶微分模块
third_dif u_third_dif(
    .clk                (clk_100m),         //时钟信号
    .rst_n              (rst_n),            //复位信号
    .en_third_dif       (adc_finish_flag),  //三阶微分使能信号
    .current_data       (filtered_data),    //三阶微分前数据
    .third_dif_data     (third_dif_data),   //三阶微分后数据
    .third_dif_finish   (third_dif_finish)  //三阶微分完成标志
);

//例化缩颈信号判断模块
neck_judge u_neck_judge(
    .clk                (clk_100m),         //时钟信号
    .rst_n              (rst_n),            //复位信号
    .en_judge           (1),                //缩颈判断使能
    .first_order_data   (first_dif_data),   //一阶微分数据
    .second_order_data  (second_dif_data),  //二阶微分数据
    .third_order_data   (third_dif_data),   //三阶微分数据
    .judge_finish       (judge_finish),     //判断完成标志
    .necking_signal     (necking_signal)    //输出缩颈信号
);
endmodule
