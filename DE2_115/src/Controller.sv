`include "define.sv"

module Main(
    input i_clk,
    input i_rst_n,

    input [3:0] i_key,
    input i_sw,
    input mode,

    output [3:0] o_ptr_action,
    output  o_mem_action
);

logic [3:0] ptr_r, ptr_w;
assign o_mem_action = i_sw[0];

always_comb begin
    o_ptr_action = ptr_r;
    if (!i_key[0]) o_ptr_action = PTR_RIGHT;
    else if (!i_key[3]) o_ptr_action = PTR_LEFT;
end

always_comb begin
    ptr_w = ptr_r;
    case (ptr_r)
        PTR_RESET: begin
        end
        PTR_READ: begin
            ptr_w = PTR_WRITE;
        end
        PTR_WRITE: begin
            ptr_w = PTR_READ;
        end
    endcase
end

always_ff @(negedge i_key[2] or negedge i_key[1] or negedge i_rst_n) begin
    if (!i_rst_n || !i_key[1]) ptr <= PTR_RESET;
    else ptr_r <= ptr_w;
end
endmodule

