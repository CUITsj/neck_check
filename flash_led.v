 module flash_led(
    input clk,
    input rst_n,
    input ctrl_switch,
    output led
    );

reg led_buff;
reg [25:0] cnt;

always @(posedge clk) begin
    if (!rst_n || !ctrl_switch) begin
        led_buff <= 0;
        cnt <= 0;
    end
    else if (cnt == 26'd4999_9999) begin //500毫秒切换一次引脚电平
        led_buff <= ~led_buff;
        cnt <= 0;
    end
    else begin
        cnt <= cnt + 1;
    end
end

assign led = led_buff;
    
endmodule
