module neck_judge(
	input               clk,                //时钟信号
	input               rst_n,              //复位信号
	input               en_judge,           //使能信号
	input signed [12:0] first_order_data,   //一阶微分数据输入信号
	input signed [12:0] second_order_data,  //二阶微分数据输入信号
	input signed [12:0] third_order_data,   //三阶微分数据输入信号
	
	output reg          judge_finish,       //一次缩颈过程判断完成则置1
	output reg          necking_signal      //输出缩颈信号
);	

localparam
    WAIT    = 2'b01,	//等待缩颈信号
    DELAY   = 2'b10;

reg [1:0] state1 = WAIT;

reg neck_start_flag;	//缩颈信号开始标志
reg en_cnt;     	    //计数使能
    
wire judge_result; 	    //逻辑相与结果
    
reg [16:0] cnt;		    //判断运行周期计数

localparam
    LOW     = 2'b01,
    HIGH    = 2'b10;

reg [1:0] state2 = LOW;

//对判断结果相与
assign judge_result = (en_judge&&(first_order_data>12)&&(second_order_data<(-19)||(second_order_data>22))&&((third_order_data>(-25))&&(third_order_data<29)))?1'b1:1'b0;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        cnt <= 17'd0;
    else if(en_cnt)
        cnt <= cnt+1'b1;
    else
        cnt <= 17'd0;
end

//周期延时,并根据逻辑判断输出使能信号
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        judge_finish    <= 1'b0;
        neck_start_flag <= 1'b0;
        en_cnt          <= 1'b0;
        state1          <= WAIT;
    end
    else begin
        case(state1)
            WAIT: begin
                neck_start_flag     <= 1'b0;
                en_cnt              <= 1'b0;
                judge_finish        <= 1'b0;
                if(judge_result) begin              //如果逻辑相与为高电平，缩颈信号开始
                    neck_start_flag     <= 1'b1;    //缩颈信号开始标志置一
                    en_cnt              <= 1'b1;    //使能计数
                    state1              <= DELAY;
                end
                else
                    state1 <= WAIT;
            end
            DELAY: begin
                en_cnt              <= 1'b1;
                neck_start_flag     <= 1'b0;
                if(cnt>0 && cnt<130000) begin   //延时阶段
                    state1      <= DELAY;
                end
                else if(cnt == 130000) begin    //延时完成
                    neck_start_flag     <= 1'b0;
                    en_cnt              <= 1'b0;    //停止计数
                    judge_finish        <= 1'b1;    //缩颈检测一个周期1.3ms完成
                    state1              <= WAIT;
                end
            end
            default: begin
                judge_finish        <= 1'b0;
                neck_start_flag     <= 1'b0;
                en_cnt              <= 1'b0;
                state1              <= WAIT;
            end
        endcase
    end
end

//缩颈信号开始输出高电平，延时20微秒输出低电平
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        necking_signal  <= 1'b0;
        state2          =  LOW;
    end
    else begin
        case(state2)
                LOW: begin
                    necking_signal <= 1'b0;
                    if(en_judge && neck_start_flag) begin   //缩颈信号开始，驱动引脚拉高
                        state2  <= HIGH;
                    end
                    else
                        state2  <= LOW;
                end
                HIGH: begin
                    if(cnt>0 && cnt<=2000) begin    //延时20微秒
                        necking_signal <= 1'b1;
                    end
                    else begin
                        necking_signal <= 1'b0;     //保持20微秒高电平再拉低
                        state2  <= LOW;
                    end
                end
                default: begin
                    necking_signal <= 1'b0;
                    state2 <= LOW;
                end
        endcase    
    end
end
endmodule
