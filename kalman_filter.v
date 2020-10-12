module kalman_filter(
	input                       rst_n,          //复位信号，低电平有效
	input                       en_kalman,      //滤波器使能信号，高电平有效
	input signed [11:0]         origin_data,    //滤波前数据信号

	output reg signed [11:0]    filtered_data,  //滤波后数据信号
	output reg                  filter_finish   //一次滤波完成后置1
);

parameter [8:0] Q;                 //过程协方差矩阵
parameter [8:0] R;                 //观测协方差矩阵

localparam AD_WIDE = 11;            //跟AD位宽一样的参数

reg signed [AD_WIDE:0] x_last;           //上一次的估计值
reg signed [AD_WIDE:0] x_fore;           //预测值

reg signed [4:0] p_last;           //上一次的估计值和真实值的协方差矩阵
reg signed [4:0] p_fore;           //估计值和真实值的协方差矩阵

reg signed [16:0] kg_num;			//卡尔曼增益分子
reg signed [8:0] kg_den;			//卡尔曼增益分母
reg signed [7:0] kg;               //卡尔曼增益
  
reg signed [11:0] xnew_den;			//x_new的分母//该值大小与噪声大小有关
reg signed [17:0] xnew_left_add;	//x_new左移后(放大)的加数//该值大小与噪声大小有关
  
reg signed [5:0] xnew_right_add;	//x_new右移后(还原)的加数//该值大小与噪声大小有关
reg signed [AD_WIDE:0] x_new;            //新的估计值
  
reg signed [AD_WIDE:0] pnew_left_min;	//估计值和真实值的协方差左移后（放大）的被减数
  
reg signed [1:0] pnew_right_min;	//估计值和真实值的协方差右移后（还原）的被减数
reg signed [4:0] p_new;            //新的估计值和真实值的协方差矩阵

always @(en_kalman or rst_n) begin
    if(!rst_n) begin
        x_last = 12'd2048;         //给上一次的估计值赋初值
        p_last = 5'd0;            //给上一次的估计值和真实值的协方差矩阵赋初值
        x_fore = 12'd0;
        p_fore = 5'd0;
        kg_num = 17'd0;
        kg_den = 9'd0;
        kg = 8'd0;
        xnew_den = 12'd0;
        xnew_left_add = 18'd0;
        xnew_right_add = 6'd0;
        pnew_left_min = 12'd0;
        pnew_right_min = 2'd0;
        filtered_data = 12'd0;
        filter_finish = 1'b0;
        
    end
    else if (en_kalman) begin
        x_fore = x_last;       //卡尔曼滤波公式一: 根据上一次的估计值计算预测值
        p_fore = p_last+Q;     //卡尔曼滤波公式二: 计算预测值和真实值之间的协方差矩阵
        kg_num = p_fore<<12;   //卡尔曼增益分子增大2的12次方倍
        kg_den = p_fore+R;     //计算卡尔曼增益的分母
        kg = kg_num/kg_den;    //计算卡尔曼增益
        xnew_den = origin_data-x_fore;         //计算估计值（滤波值）其中一个加数的分母
        xnew_left_add = kg*xnew_den;           //计算估计值（滤波值）其中一个加数
        xnew_right_add = xnew_left_add>>12;    //将估计值（滤波值）其中一个加数缩小2的12次方倍
        
        x_last = x_fore+xnew_right_add;         //卡尔曼公式4:计算新的估计值
        
        pnew_left_min = kg*p_fore;             //计算新的估计值和真实值协方差矩阵其中的被减数
        pnew_right_min = pnew_left_min>>12;    //新的估计值和真实值协方差矩阵的被减数缩小2的12次方倍
        
        p_last = p_fore-pnew_right_min;         //计算新的估计值和真实值协方差矩阵
        

        filtered_data   =  x_last;    //输出卡尔曼滤波值
        filter_finish   =  1'b1;
    end
    else
    filter_finish   = 1'b0;
end
endmodule
