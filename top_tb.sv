`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.05.2024 11:07:07
// Design Name: 
// Module Name: top_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


import uvm_pkg::*;
`include "uvm_macros.svh"

//interface 
interface mul_if(input logic clk,reset);
    logic [3:0] a,b;
    logic [7:0] out;
endinterface

//seq-item
class seq_item extends uvm_sequence_item;
    rand bit[3:0] a,b;
    bit[7:0] out;    
    
    function new (input string name="seq_item");
        super.new(name);
    endfunction
    
    `uvm_object_utils_begin(seq_item);
        `uvm_field_int(a,UVM_ALL_ON);
        `uvm_field_int(b,UVM_ALL_ON);
    `uvm_object_utils_end
    
    //can add some constraints
    constraint const_a{
        a>0;
    }
    constraint const_b{
        b dist{1:=2,3:=4,15:=6,2:=3};
    }
    
endclass

//base-seq
class base_seq extends uvm_sequence#(seq_item);
    seq_item req;
    `uvm_object_utils(base_seq);
    function new(input string name="base_seq");
        super.new(name);    
    endfunction
    
    task body();
        `uvm_info(get_type_name(),"Base seq: Inside body",UVM_LOW);
        `uvm_do(req);
    endtask
    
endclass

//sequencer
class seqcr extends uvm_sequencer#(seq_item);
    `uvm_component_utils(seqcr);
    function new(string name,uvm_component parent=null);
        super.new(name,parent);
    endfunction
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction
endclass

//driver
class driver extends uvm_driver#(seq_item);
    virtual mul_if vif;
    `uvm_component_utils(driver);
    function new(string name="driver",uvm_component parent);
        super.new(name,parent);
    endfunction
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual mul_if)::get(this,"","vif",vif))
            `uvm_fatal(get_type_name(),"Not set at top level");
    endfunction
    task run_phase(uvm_phase phase);
        forever begin
            seq_item_port.get_next_item(req);
            `uvm_info(get_type_name(),$sformatf("a=%0d,b=%0d",req.a,req.b),UVM_LOW);
            vif.a=req.a;
            vif.b=req.b;
            seq_item_port.item_done();
        end
    endtask
endclass

//monitor
class monitor extends uvm_monitor;
    virtual mul_if vif;
    uvm_analysis_port #(seq_item) item_collect_port;
    seq_item mon_item;
    `uvm_component_utils(monitor);
    function new(string name="monitor",uvm_component parent=null);
        super.new(name,parent);
        item_collect_port=new("item_collect_port",this);
        mon_item =new();
    endfunction
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual mul_if)::get(this,"","vif",vif))
            `uvm_fatal(get_type_name(),"Not set at top level");
    endfunction
    task run_phase(uvm_phase phase);
        forever begin
            wait(!vif.reset);
            @(posedge vif.clk);
            mon_item.a=vif.a;
            mon_item.b=vif.b;
            `uvm_info(get_type_name(),$sformatf("a=%0d,b=%0d",mon_item.a,mon_item.b),UVM_HIGH);
            @(posedge vif.clk);
            mon_item.out=vif.out;
            item_collect_port.write(mon_item);
        end
    endtask
    
endclass

//agent
class agent extends uvm_agent;
    `uvm_component_utils(agent);
    driver drv;
    monitor mon;
    seqcr seqr;
    
    function new(string name="agent",uvm_component parent=null);
        super.new(name,parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(get_is_active == UVM_ACTIVE)begin
            drv=driver::type_id::create("drv",this);
            seqr=seqcr::type_id::create("seqr",this);
        end
        
        mon=monitor::type_id::create("mon",this);
    endfunction;
    
    function void connect_phase(uvm_phase phase);
        if(get_is_active == UVM_ACTIVE)begin
            drv.seq_item_port.connect(seqr.seq_item_export);
         end
    endfunction
    
endclass

//scoreboard
class scoreboard extends uvm_scoreboard;
    uvm_analysis_imp #(seq_item,scoreboard) item_collect_export;
    seq_item item_q[$];
    `uvm_component_utils(scoreboard);
    
    function new(string name="sb",uvm_component parent=null);
        super.new(name,parent);
        item_collect_export =new ("item_collect_export",this);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction
    
    function void write(seq_item req);
        item_q.push_back(req);
    endfunction
    
    task run_phase(uvm_phase phase);
        seq_item sb_item;
        forever begin 
            wait(item_q.size>0);
            if(item_q.size>0) begin
                sb_item=item_q.pop_front();
                $display("-----[scoreboard]------------");
                if(sb_item.a*sb_item.b==sb_item.out) begin
                    `uvm_info(get_type_name(),$sformatf("Matched: a=%0d,b=%0d,out=%0d",sb_item.a,sb_item.b,sb_item.out),UVM_LOW);
                end
                else begin
                    `uvm_error(get_name,$sformatf("Not Matched: a=%0d,b=%0d,out=%0d",sb_item.a,sb_item.b,sb_item.out));
                end
            end   
        end
    endtask
    
endclass

//environment
class env extends uvm_env;
    `uvm_component_utils(env);
    agent agt;
    scoreboard sb;
    function new(string name="env",uvm_component parent=null);
        super.new(name,parent);
    endfunction
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agt=agent::type_id::create("agt",this);
        sb=scoreboard::type_id::create("sb",this);
    endfunction
    function void connect_phase(uvm_phase phase);
        agt.mon.item_collect_port.connect(sb.item_collect_export);
    endfunction
endclass

//test
class base_test extends uvm_test;
    env env_o;
    base_seq bseq;
    `uvm_component_utils(base_test);
    
    //covergroup-1
    covergroup cg1;
        A: coverpoint bseq.req.a{
            bins b1={1,2,3,4};
            bins b2={[5:12]};
        }
    endgroup
    
    //covergroup-2
    covergroup cg2;
        B: coverpoint bseq.req.b;
    endgroup
        
    function new(string name="base_test",uvm_component parent=null);
        super.new(name,parent);
        cg1=new();cg2=new();
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env_o=env::type_id::create("env_o",this);
    endfunction
    
    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        bseq=base_seq::type_id::create("bseq");
        repeat(10) begin
            #5; bseq.start(env_o.agt.seqr);
            if(bseq.req!=null)begin
                cg1.sample();
                cg2.sample(); 
            end
            else `uvm_warning("NULL REQ","bseq.req is NULL; skipping the sampling");
        end  
        
        phase.drop_objection(this);
        `uvm_info(get_type_name,"END OF TESTCASE",UVM_LOW);
    endtask
endclass

//testbench_top
module top_tb;
    bit clk,reset;
    always #2 clk=~clk;
    initial begin
        reset=1;
        #5;
        reset=0;
    end
    mul_if vif(clk,reset);
    Mul4Bit DUT(.clk(vif.clk),.reset(vif.reset),.a(vif.a),.b(vif.b),.out(vif.out));
    
    initial begin
        uvm_config_db#(virtual mul_if)::set(uvm_root::get(),"*","vif",vif);
    end
    
    initial begin
        run_test("base_test");
    end
    
endmodule
