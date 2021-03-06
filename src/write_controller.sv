`timescale 1ns / 1ps

module write_controller
#(
    parameter MEM = "a"
)
(
    input   logic clk,
    input   logic rst,
    input   logic [7:0] byte_received,
    input   logic rx_data_ready,
    output  logic en,
    output  logic we,
    output  logic [9:0] addr,
    output  logic [7:0] din,
    output  logic [2:0] status,
    output	logic [2:0] status_next,
    output  logic [23:0] array
);

    

    //Not sure why, but registering this signal helps in FSM
    logic rx_data_ready_r = 1'd0;
    always_ff @(posedge clk) begin
        if (rst)
            rx_data_ready_r <= 1'd0;
        else
            rx_data_ready_r <= rx_data_ready;
    end


    // Last 3 data bytes concatenation
    logic [23:0] data_array = 24'd0;
    assign array[23:0] = data_array[23:0];

    // always_comb begin
    //     if (rx_data_ready_r)
    //         data_array_next[23:0] = {data_array[15:0],byte_received[7:0]};
    // end

    always_ff @(posedge clk) begin
        if (rst)
            data_array[23:0] <= 24'd0;
        else
            if (rx_data_ready_r)
                data_array[23:0] <= {data_array[15:0],byte_received[7:0]};
    end
    


    //FSM
    enum logic [2:0]{IDLE, WAIT, WRITE} state, state_next;
    assign status[2:0] = state[2:0];
    assign status_next[2:0] = state_next[2:0];


    logic   addr_reset;
    logic   [9:0] addr_next = 10'd0;
    logic   [7:0] din_next = 8'd0;

    always_comb begin
        state_next[2:0] = IDLE;
        din_next[7:0] = 8'd0;
        en = 1'b0;
        we = 1'b0;
        addr_reset = 1'd1;
        case(state)
            IDLE:   begin
                        if (data_array[23:0]=={"w",MEM,8'h0A}) begin
                            state_next[2:0] = WAIT;
                            addr_reset = 1'd0;
                        end
                    end
            WAIT:   begin
                        state_next[2:0] = WAIT;
                        addr_reset = 1'd0;
                        if (rx_data_ready_r) begin
                            state_next[2:0] = WRITE;
                            addr_reset = 1'd0;
                            din_next[7:0] = byte_received[7:0];
                        end

                    end
            WRITE:  begin
                        en = 1'b1;
                        we = 1'b1;
                        addr_reset = 1'd0;
                        state_next[2:0] = WAIT;
                        if (addr[9:0]==10'd1023) begin
                            state_next = IDLE;
                            addr_reset = 1'b0;
                        end
                    end
        endcase
    end

    always_ff @(posedge clk) begin
        if (rst||addr_reset) 
            addr[9:0] <= 10'd0;
        else
            if (state[2:0]==WRITE)
                addr[9:0] <= addr[9:0]+1'd1;
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            state[2:0] <= IDLE;
            din[7:0] <= 8'd0;
        end
        else begin
            state[2:0] <= state_next[2:0];
            din[7:0] <= din_next[7:0];
        end
    end
endmodule