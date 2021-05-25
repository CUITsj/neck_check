//该卡尔曼滤波器只能用于对13位的一维数据进行滤波
module kalman_filter(
	input                       clk,            //系统时钟
	input                       rst_n,          //复位信号，低电平有效
	input                       en_kalman,      //滤波器使能信号，高电平有效
	input signed [12:0]         origin_data,    //滤波前数据信号

	output reg signed [12:0]    filtered_data,  //滤波后数据信号
	output reg                  filter_finish   //一次滤波完成后置1
);

parameter [12:0] Q;                 //过程协方差矩阵
parameter [12:0] R;                 //观测协方差矩阵

reg signed [12:0] x_last;           //上一次的估计值
reg signed [12:0] x_fore;           //预测值

reg signed [12:0] p_last;           //上一次的估计值和真实值的协方差矩阵
reg signed [12:0] p_fore;           //估计值和真实值的协方差矩阵

reg signed [23:0] kg_small_num;		//卡尔曼增益分子
reg signed [12:0] kg_den;			//卡尔曼增益分母
reg signed [23:0] kg_small;         //卡尔曼增益

reg signed [12:0] origin_data_buff; //原始数据缓存
  
reg signed [12:0] xnew_mul;			//x_new的乘数
reg signed [35:0] xnew_small_add;	//x_new右移后变小的加数
  
reg signed [23:0] xnew_big_add;	    //x_new左移后放大的加数
reg signed [24:0] x_new;            //新的估计值
  
reg signed [35:0] pnew_small_sub;	//估计值和真实值的协方差右移变小后的被减数
  
reg signed [23:0] pnew_big_sub;	    //估计值和真实值的协方差左移后放大后的被减数
reg signed [12:0] p_new;            //新的估计值和真实值的协方差矩阵

reg [2:0] state;                    //卡尔曼滤波状态

localparam    STEP1 = 3'b000,   
              STEP2 = 3'b001,   
              STEP3 = 3'b010,   
              STEP4 = 3'b011,   
              STEP5 = 3'b100,   
              STEP6 = 3'b101,   
              STEP7 = 3'b110,   
              STEP8 = 3'b111;       //卡尔曼滤波8个状态
              
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		x_fore <= 13'd0;
        p_fore <= 13'd0;
        kg_small_num <= 24'd0;
        kg_den <= 13'd0;
        kg_small <= 24'd0;
        xnew_mul <= 13'd0;
        xnew_small_add <= 36'd0;
        xnew_big_add <= 24'd0;
        x_new <= 25'd0;
        pnew_small_sub <= 36'd0;
        pnew_big_sub <= 24'd0;
        p_new <= 13'd0;
        
        filtered_data <= 13'd0;
        x_last <= 13'd2048;         //给上一次的估计值赋初值
        p_last <= 13'd0;            //给上一次的估计值和真实值的协方差矩阵赋初值
        origin_data_buff <= 0;
        filter_finish <= 1'b0;
        state <= STEP1;
	end
    //弄清楚卡尔曼滤波迭代次数
	else begin
        case(state)
            STEP1:begin
                if (en_kalman) begin
                    origin_data_buff <= origin_data;    //1相同位宽赋值
                    //先验估计
                    x_fore <= x_last;       //1根据上一次的估计值计算预测值
                    p_fore <= p_last+Q;     //1计算预测值和真实值之间的协方差矩阵
                    state <= STEP2;
                end
                else state <= STEP1;
            end
            STEP2:begin
                //计算缩小后的卡尔曼增益kg_small
                kg_small_num <= p_fore<<12; //2卡尔曼增益分子增大2的12次方倍
                kg_den <= p_fore+R;         //2计算卡尔曼增益的分母
                xnew_mul <= origin_data_buff-x_fore;    //2计算估计值（滤波值）其中一个加数的分母
                origin_data_buff <= 0;
                state <= STEP3;
            end
            STEP3:begin
                kg_small <= kg_small_num/kg_den;        //3计算卡尔曼增益
                state <= STEP4;
            end
            STEP4:begin
                xnew_small_add <= kg_small*xnew_mul;    //4计算估计值（滤波值）其中一个加数
                pnew_small_sub <= kg_small*p_fore;      //4计算新的估计值和真实值协方差矩阵其中的被减数
                state <= STEP5;
            end
            STEP5:begin
                xnew_big_add <= xnew_small_add>>12;     //5将估计值（滤波值）其中一个加数缩小2的12次方倍
                pnew_big_sub <= pnew_small_sub>>12;     //5新的估计值和真实值协方差矩阵的被减数缩小2的12次方倍
                state <= STEP6;
            end
            STEP6:begin
                x_new <= x_fore+xnew_big_add;           //6计算新的预测值
                p_new <= p_fore-pnew_big_sub;           //6计算新的估计值和真实值协方差矩阵
                state <= STEP7;
            end
            STEP7:begin
                x_last              <= {x_new[12:0]};     //7更新上一次的估计值
                p_last              <= {p_new[12:0]};     //7更新上一次的估计值与真实值的协方差值
                
                filtered_data       <= {x_new[12:0]};     //7输出卡尔曼滤波值//位宽大的赋值给位宽小的
                filter_finish       <= 1'b1;            //7
                state <= STEP8;
            end
            STEP8:begin
                //c,输出滤波后的值
                filter_finish       <= 1'b0;            //8
                state <= STEP1;
            end
            default:state <= STEP1;
        endcase
    end
end
endmodule
