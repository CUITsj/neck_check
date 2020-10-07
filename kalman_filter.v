module kalman_filter(
	input                       clk,            //系统时钟
	input                       rst_n,          //复位信号，低电平有效
	input                       en_kalman,      //滤波器使能信号，高电平有效
	input signed [11:0]         origin_data,    //滤波前数据信号

	output reg signed [12:0]    filtered_data,  //滤波后数据信号
	output reg                  filter_finish   //一次滤波完成后置1
);

parameter [11:0] Q;                 //过程协方差矩阵
parameter [11:0] R;                 //观测协方差矩阵

reg signed [11:0] x_last;         //上一次的估计值
reg signed [11:0] x_fore;           //预测值

reg signed [11:0] p_last;          //上一次的估计值和真实值的协方差矩阵
reg signed [11:0] p_fore;           //估计值和真实值的协方差矩阵

reg signed [23:0] kg_num;			//卡尔曼增益分子
reg signed [12:0] kg_den;			//卡尔曼增益分母
reg signed [23:0] kg;               //卡尔曼增益
  
reg signed [11:0] xnew_den;			//x_new的分母
reg signed [35:0] xnew_left_add;	//x_new左移后(放大)的加数
  
reg signed [23:0] xnew_right_add;	//x_new右移后(还原)的加数
reg signed [24:0] x_new;            //新的估计值
  
reg signed [35:0] pnew_left_min;	//估计值和真实值的协方差左移后（放大）的被减数
  
reg signed [23:0] pnew_right_min;	//估计值和真实值的协方差右移后（还原）的被减数
reg signed [11:0] p_new;            //新的估计值和真实值的协方差矩阵

//卡尔曼滤波公式一: 根据上一次的估计值计算预测值
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		x_fore <= 12'd0;
	end
	else
		x_fore <= x_last;
end

//卡尔曼滤波公式二: 计算预测值和真实值之间的协方差矩阵
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        p_fore <= 12'd0;
    end
    else
        p_fore <= p_last+Q;
end

//卡尔曼增益分子增大2的12次方倍
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        kg_num <= 24'd0;
    end
    else
        kg_num <= p_fore<<12;
end

//计算卡尔曼增益的分母
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        kg_den <= 13'd0;
    end
    else
        kg_den <= p_fore+R;
end

//计算卡尔曼增益
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        kg <= 24'd0;
    end
    else
        kg <= kg_num/kg_den;
end

//计算估计值（滤波值）其中一个加数的分母
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        xnew_den <= 12'd0;
    end
    else
        xnew_den <= origin_data-x_fore;
end

//计算估计值（滤波值）其中一个加数
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        xnew_left_add <= 36'd0;
    end
    else
        xnew_left_add <= kg*xnew_den;
end

//将估计值（滤波值）其中一个加数缩小2的12次方倍
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        xnew_right_add <= 24'd0;
    end
    else
        xnew_right_add <= xnew_left_add>>12;
end

//卡尔曼公式4:计算新的估计值
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        x_new <= 25'd0;
    end
    else
        x_new <= x_fore+xnew_right_add;
end

//计算新的估计值和真实值协方差矩阵其中的被减数
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        pnew_left_min <= 36'd0;
    end
    else
        pnew_left_min <= kg*p_fore;
end

//新的估计值和真实值协方差矩阵的被减数缩小2的12次方倍
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        pnew_right_min <= 24'd0;
    end
    else
        pnew_right_min <= pnew_left_min>>12;
end

//计算新的估计值和真实值协方差矩阵
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        p_new <= 12'd0;
    end
    else
        p_new <= p_fore-pnew_right_min;
end

//卡尔曼滤波控制
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        filtered_data <= 13'd0;
        filter_finish <= 1'b0;
        x_last <= 12'd2048;      //给上一次的估计值赋初值
        p_last <= 12'd0;       //给上一次的估计值和真实值的协方差矩阵赋初值
    end
    else if(en_kalman) begin
        filtered_data   <=  x_new[12:0];    //输出卡尔曼滤波值
        x_last          <=  x_new[12:0];    //更新上一次的估计值
        p_last          <=  p_new[11:0];    //更新上一次的估计值与真实值的协方差值
        filter_finish   <=  1'b1;
    end
    else
        filter_finish   <= 1'b0;
end
endmodule
