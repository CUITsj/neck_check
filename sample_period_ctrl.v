module sample_period_ctrl(
    input clk,
    input rst_n,
    input en_sample,
    input signed [12:0] before_sample_data,
    output reg signed [12:0] after_sample_data,
    output reg sample_finish

);
reg [18:0] cnt;     //用于延时采样计数

always @(posedge clk) begin
    if (!rst_n) begin
        cnt <= 0;
        after_sample_data <= 0;
        sample_finish <= 0;
    end
    else if (cnt == 19'd4999) begin //4999对应50微秒采样一次数据
            after_sample_data <= before_sample_data;
            sample_finish <= 1;
            cnt <= 0;
    end
    else begin
        cnt <= cnt + 1;
        sample_finish <= 0;
    end
end

endmodule
