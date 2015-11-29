`include "define.sv"

module Main(
    input i_clk,
    input i_rst_n,
    input [3:0] i_key,
    input [7:0] i_sw,
    output [1:0] o_ptr_action,
    output [1:0]  o_mem_action
);

logic [1:0] ptr;
assign o_ptr_action = ptr;
assign o_mem_action = i_sw[0];

always_ff @(negedge i_key[2] or negedge i_key[1] or negedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n || !i_key[1]) ptr <= PTR_RESET;
    else if (!i_key[2]) begin
        case (ptr)
            PTR_RESET: begin
            end
            PTR_READ: begin
                ptr <= PTR_WRITE;
            end
            PTR_WRITE: begin
                ptr <= PTR_READ;
            end
        endcase
    end
    else begin
        ptr <= ptr_action_w;
    end
end
endmodule
