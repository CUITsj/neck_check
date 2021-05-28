module top_neck(
	input   sys_clk,            //系统时钟
	input   sys_rst_n,          //系统复位
	input   ads7883_sdo,        //adc模块数据端口
    input   ctrl_switch,         //0:IGBT常开，1:IGBT受程序控制。
    
	output  ads7883_sclk,       //adc模块时钟信号
	output  ads7883_ncs,        //adc模块片选信号
	output  power_switch,        //电焊机电源控制
    output  led
);

//ip核       
wire clk_100m;                              //100MHz时钟信号
wire rst_n;                                 //复位信号
wire locked;                                //locked信号拉高,锁相环开始稳定输出时钟 

//ADC      
wire adc_finish;                            //adc模块转换完成标志
wire signed [12:0] adc_data;                //adc最终数据

//kalman滤波      
wire signed [12:0] filtered_data;           //卡尔曼滤波后数据
wire filter_finish;                         //卡尔曼滤波完成标志

//采样
wire signed [12:0] sampled_data;
wire sample_finish;
        
//微分      
wire signed [12:0] first_dif_data;          //一阶微分输出数据    
wire signed [12:0] second_dif_data;         //二阶微分输出数据      
wire signed [12:0] third_dif_data;          //三阶微分输出数据
wire dif_finish;                            //微分完成标志

wire signed [12:0] same_data;
        
//系统复位与锁相环locked相与,作为其它模块的复位信号 
assign  rst_n = sys_rst_n & locked; 

//固定不改
//例化PLL IP核
pll_clk u_pll_clk(
    .areset             (~sys_rst_n),       //复位取反
    .inclk0             (sys_clk),          //50MHz时钟
    .c0                 (clk_100m),         //100MHz时钟
    .locked             (locked)            //locked信号拉高,锁相环开始稳定输出时钟 
);

//固定不改
//例化ADC模块,700纳秒以内获取一个AD值
ads7883_ctrl #(
    .CLK_STEP           (2)                 //ADC时钟步长
) u_ads7883_ctrl(
    .clk                (clk_100m),         //adc时钟
    .rst_n              (rst_n),            //复位
    .en_adc             (1),	            //开始转换使能信号
    .adc_finish         (adc_finish),	    //转换完成信号
    .adc_data           (adc_data),	        //采样结果
    .ads7883_sdo        (ads7883_sdo),      //adc模块数据端口
    .ads7883_sclk       (ads7883_sclk),     //adc模块时钟端口
    .ads7883_ncs        (ads7883_ncs)       //adc模块片选端口
);

//固定不改
//例化卡尔曼滤波模块
kalman_filter #(
    // Q越大，越信任测量值，波形噪音越大
    // R越大，越信任预测值，波形越平滑
    /*效果比较好的Q-R值
    //1-60
    //1-400
    */
    .Q                  (1),                //过程噪声协方差40
    .R                  (400)                //观测噪声协方差1
) u_kalman_filter(     
    .clk                (clk_100m),
    .rst_n              (rst_n),            //复位信号
    .en_kalman          (adc_finish),       //滤波使能信号
    .origin_data        (adc_data),         //滤波原始数据
    .filtered_data      (filtered_data),    //滤波后数据
    .filter_finish      (filter_finish)     //滤波完成标志
);


//例化数据取样周期模块
sample_period_ctrl u_sample_period_ctrl(
    .clk                (clk_100m),
    .rst_n              (rst_n),
    .en_sample          (filter_finish),
    .before_sample_data (filtered_data),
    .after_sample_data  (sampled_data),     //采样过后的数据
    .sample_finish      (sample_finish)
);
                                          
//例化微分模块
dif u_dif(
    .clk                (clk_100m),
    .rst_n              (rst_n),            //复位信号
    .en_dif             (sample_finish),    //三阶微分使能信号
    .current_data       (sampled_data),     //三阶微分前数据
    .first_dif_data     (first_dif_data),   //一阶微分后数据
    .second_dif_data    (second_dif_data),  //二阶微分后数据
    .third_dif_data     (third_dif_data),   //三阶微分后数据
    .dif_finish         (dif_finish)        //三阶微分完成标志
);

//例化缩颈信号判断模块
neck_judge u_neck_judge(
    .clk                (clk_100m),
    .rst_n              (rst_n),            //复位信号
    .en_judge           (dif_finish),
    .adc_data           (adc_data),
    .ctrl_switch        (ctrl_switch),      //控制缩颈检测开关
    .first_order_data   (first_dif_data),   //一阶微分数据
    .second_order_data  (second_dif_data),  //二阶微分数据
    .third_order_data   (third_dif_data),   //三阶微分数据
    .power_switch       (power_switch)      //判断完成标志
);

//例化呼吸灯模块
flash_led u_flash_led(
    .clk                (clk_100m),
    .rst_n              (rst_n),
    .ctrl_switch        (ctrl_switch),      //控制呼吸灯开关
    .led                (led)
);

endmodule
