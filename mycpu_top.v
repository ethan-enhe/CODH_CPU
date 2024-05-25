module mycpu_top (
    input  wire        clk,
    input  wire        resetn,
    // inst sram interface
    output wire        inst_sram_we,
    output wire        inst_sram_re,
    output wire [31:0] inst_sram_addr,
    output wire [31:0] inst_sram_wdata,
    input  wire [31:0] inst_sram_rdata,
    input  wire        inst_sram_miss,
    output wire        inst_sram_rstn,
    // data sram interface
    output wire        data_sram_we,
    output wire [31:0] data_sram_addr,
    output reg  [31:0] data_sram_wdata,
    input  wire [31:0] data_sram_rdata,
    // trace debug interface
    output wire [31:0] debug_wb_pc,
    output wire [ 3:0] debug_wb_rf_we,
    output wire [ 4:0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata
);
  //加入cache需要把if段分成if1和if2两部分，

  wire rf_rd0_fe;
  wire rf_rd1_fe;
  wire [31:0] rf_rd0_fd;
  wire [31:0] rf_rd1_fd;
  //reg [31:0] maw_reg;
  //reg [3:0] mwew_reg;
  reg [31:0] mdw_reg;
  reg [31:0] mdr_reg;
  reg reset;
  always @(posedge clk) reset <= ~resetn;

  reg  valid;
  wire flush_if1if2;
  wire flush_ifid;
  wire flush_idex;
  wire stall_pc;
  wire stall_ifid;
  reg  stall_ifid_buf; 
  wire stall_if1if2;
  wire stall_all;
  always @(posedge clk) begin
    if (reset) begin
      valid <= 1'b0;
    end else begin
      valid <= 1'b1;
    end
  end

  wire [31:0] seq_pc;
  wire [31:0] nextpc;
  wire        br_taken;
  wire [31:0] br_target;
  wire [31:0] inst;
  reg  [31:0] ir_reg1;
  reg  [31:0] ir_reg;
  // reg  [31:0] ire_reg;
  // reg  [31:0] irm_reg;
  // reg  [31:0] irw_reg;


  wire [31:0] final_result_mem;
  reg  [31:0] final_result_wb;
  reg  [31:0] pc;
  reg  [31:0] pcf2_reg;
  reg  [31:0] pcd_reg;
  reg  [31:0] pce_reg;
  reg  [31:0] pcm_reg;
  reg  [31:0] pcw_reg;

  wire [11:0] alu_op;
  reg  [11:0] alu_op_reg;
  //wire        load_op;
  wire        src1_is_pc;
  wire        src2_is_imm;
  reg         src1_is_pc_reg;
  reg         src2_is_imm_reg;
  wire        res_from_mem;
  reg         res_from_mem_e_reg;
  reg         res_from_mem_m_reg;
  reg         res_from_mem_w_reg;
  wire        dst_is_r1;
  wire        rf_we;
  reg         rf_we_e_reg;
  reg         rf_we_m_reg;
  reg         rf_we_w_reg;
  wire        mem_we;
  reg         mem_wee_reg;
  reg         mem_wem_reg;
  wire        src_reg_is_rd;
  wire [ 4:0] rf_wa_;
  reg  [ 4:0] rf_wa_e_reg;
  reg  [ 4:0] rf_wa_m_reg;
  reg  [ 4:0] rf_wa_w_reg;
  wire [31:0] rj_value;
  wire [31:0] rkd_value;
  wire [31:0] imm;
  reg  [31:0] imm_reg;
  wire [31:0] br_offs;
  reg  [31:0] br_offs_reg;
  // wire [31:0] jirl_offs;

  wire [ 5:0] op_31_26;
  wire [ 3:0] op_25_22;
  wire [ 1:0] op_21_20;
  wire [ 4:0] op_19_15;
  wire [ 4:0] rd;
  // reg  [ 4:0] rd_reg;
  // reg  [ 4:0] rdm_reg;
  // reg  [ 4:0] rdw_reg;
  wire [ 4:0] rj;
  wire [ 4:0] rk;
  wire [ 4:0] i5;
  wire [11:0] i12;
  wire [19:0] i20;
  wire [15:0] i16;
  wire [25:0] i26;

  wire [63:0] op_31_26_d;
  wire [15:0] op_25_22_d;
  wire [ 3:0] op_21_20_d;
  wire [31:0] op_19_15_d;

  wire        inst_add_w;
  wire        inst_sub_w;
  wire        inst_slt;
  wire        inst_sltu;
  wire        inst_nor;
  wire        inst_and;
  wire        inst_or;
  wire        inst_xor;
  wire        inst_slli_w;
  wire        inst_srli_w;
  wire        inst_srai_w;
  wire        inst_addi_w;
  wire        inst_ld_w;
  wire        inst_st_w;
  wire        inst_jirl;
  wire        inst_b;
  wire        inst_bl;
  wire        inst_beq;
  wire        inst_bne;
  wire        inst_lu12i_w;

  reg         inst_beq_reg;
  reg         inst_bne_reg;
  reg         inst_blt_reg;
  reg         inst_bltu_reg;
  reg         inst_bge_reg;
  reg         inst_bgeu_reg;
  reg         inst_jirl_reg;
  reg         inst_bl_reg;
  reg         inst_b_reg;

  reg         inste_st_w_reg;
  reg         inste_st_b_reg;
  reg         inste_st_h_reg;
  reg         inste_ld_w_reg;
  reg         inste_ld_b_reg;
  reg         inste_ld_h_reg;
  reg         inste_ld_bu_reg;
  reg         inste_ld_hu_reg;

  reg         instm_st_w_reg;
  reg         instm_st_b_reg;
  reg         instm_st_h_reg;
  reg         instm_ld_w_reg;
  reg         instm_ld_b_reg;
  reg         instm_ld_h_reg;
  reg         instm_ld_bu_reg;
  reg         instm_ld_hu_reg;

  wire        inst_pcaddu12i;
  wire        inst_slti;
  wire        inst_sltui;
  wire        inst_andi;
  wire        inst_ori;
  wire        inst_xori;
  wire        inst_sll_w;
  wire        inst_srl_w;
  wire        inst_sra_w;
  wire        inst_ld_b;
  wire        inst_st_b;
  wire        inst_st_h;
  wire        inst_ld_h;
  wire        inst_ld_hu;
  wire        inst_ld_bu;
  wire        inst_blt;
  wire        inst_bge;
  wire        inst_bltu;
  wire        inst_bgeu;
  //end 

  wire        need_ui5;
  wire        need_ui12;
  wire        need_si12;
  wire        need_si16;
  wire        need_si20;
  wire        need_si26;
  wire        src2_is_4;

  wire [ 4:0] rf_raddr1;
  wire [31:0] rf_rdata1;
  reg  [31:0] a_reg;
  wire [ 4:0] rf_raddr2;
  wire [31:0] rf_rdata2;
  reg  [31:0] b_reg;
  wire [ 4:0] rf_waddr;
  wire [31:0] rf_wdata;

  wire [31:0] alu_src1;
  wire [31:0] alu_src2;
  wire [31:0] alu_result;
  reg  [31:0] y_reg;
  reg  [31:0] yw_reg;

  reg  [31:0] mem_result;

  reg  [ 4:0] rf_ra0_ex;
  reg  [ 4:0] rf_ra1_ex;  //registers between different states
  always @(posedge clk) begin
    if (reset || !valid) begin
      //IF1-IF2
      pcf2_reg <= 0;
      //IF-ID
      pcd_reg <= 0;
      stall_ifid_buf <= 0;
      ir_reg <= 0;  //nop here
      ir_reg1 <= 0;
      //ID-EX
      rf_ra0_ex <= 0;
      rf_ra1_ex <= 0;
      pce_reg <= 0;
      a_reg <= 0;
      b_reg <= 0;
      imm_reg <= 0;
      // rd_reg <= 0;
      // ire_reg <= 0;
      alu_op_reg <= 0;
      src1_is_pc_reg <= 0;
      src2_is_imm_reg <= 0;
      br_offs_reg <= 0;


      rf_we_e_reg <= 0;
      mem_wee_reg <= 0;
      res_from_mem_e_reg <= 0;
      rf_wa_e_reg <= 0;

      //鐢ㄤ簬鍐呭瓨
      inste_st_w_reg <= 0;
      inste_st_b_reg <= 0;
      inste_st_h_reg <= 0;
      inste_ld_w_reg <= 0;
      inste_ld_b_reg <= 0;
      inste_ld_h_reg <= 0;
      inste_ld_bu_reg <= 0;
      inste_ld_hu_reg <= 0;
      //鐢ㄤ簬PCsrc璁＄畻
      inst_beq_reg <= 0;
      inst_bne_reg <= 0;
      inst_blt_reg <= 0;
      inst_bltu_reg <= 0;
      inst_bge_reg <= 0;
      inst_bgeu_reg <= 0;
      inst_jirl_reg <= 0;
      inst_bl_reg <= 0;
      inst_b_reg <= 0;
      //EX-MEM
      rf_we_m_reg <= 0;
      pcm_reg <= 0;
      rf_wa_m_reg <= 0;
      mem_wem_reg <= 0;
      res_from_mem_m_reg <= 0;
      y_reg <= 0;
      mdw_reg <= 0;
      // rdm_reg <= 0;
      // irm_reg <= 0;

      //鐢ㄤ簬鍐呭瓨
      instm_st_w_reg <= 0;
      instm_st_b_reg <= 0;
      instm_st_h_reg <= 0;
      instm_ld_w_reg <= 0;
      instm_ld_b_reg <= 0;
      instm_ld_h_reg <= 0;
      instm_ld_bu_reg <= 0;
      instm_ld_hu_reg <= 0;
      //MEM-WB
      final_result_wb <= 0;
      rf_we_w_reg <= 0;
      pcw_reg <= 0;
      rf_wa_w_reg <= 0;
      res_from_mem_w_reg <= 0;
      mdr_reg <= 0;
      yw_reg <= 0;
      // rdw_reg <= 0;
      // irw_reg <= 0;
    end else if(!stall_all) begin
      //IF1-IF2
      pcf2_reg <= flush_if1if2 ? 0 : stall_if1if2 ? pcf2_reg : pc;
      //IF-ID
      pcd_reg <= flush_ifid ? 0 : stall_ifid ? pcd_reg : pcf2_reg;
      //这里ir比较特别
      //因为cache是在时钟上升沿工作的，所以有可能在stall的时候输出了结果，但是
      //ir没有将其保存
      //在stall的第一周期允许写入
      stall_ifid_buf <= stall_ifid;
      ir_reg1 <= flush_ifid ? 0 : (stall_ifid && stall_ifid_buf) ? ir_reg : inst;
      ir_reg <= flush_ifid ? 0 : stall_ifid ? ir_reg : (stall_ifid_buf? ir_reg1 : inst);
      //ID-EX
      rf_ra0_ex <= flush_idex ? 0 : rf_raddr1;
      rf_ra1_ex <= flush_idex ? 0 : rf_raddr2;
      pce_reg <= flush_idex ? 0 : pcd_reg;
      a_reg <= flush_idex ? 0 : rf_rdata1;
      b_reg <= flush_idex ? 0 : rf_rdata2;
      imm_reg <= flush_idex ? 0 : imm;
      // rd_reg <= flush_idex ? 0 : rd;
      // ire_reg <= flush_idex ? 0 : ir_reg;
      alu_op_reg <= flush_idex ? 0 : alu_op;
      src1_is_pc_reg <= flush_idex ? 0 : src1_is_pc;
      src2_is_imm_reg <= flush_idex ? 0 : src2_is_imm;
      br_offs_reg <= flush_idex ? 0 : br_offs;


      rf_we_e_reg <= flush_idex ? 0 : rf_we;
      mem_wee_reg <= flush_idex ? 0 : mem_we;
      res_from_mem_e_reg <= flush_idex ? 0 : res_from_mem;
      rf_wa_e_reg <= flush_idex ? 0 : rf_wa_;

      //鐢ㄤ簬鍐呭瓨
      inste_st_w_reg <= flush_idex ? 0 : inst_st_w;
      inste_st_b_reg <= flush_idex ? 0 : inst_st_b;
      inste_st_h_reg <= flush_idex ? 0 : inst_st_h;
      inste_ld_w_reg <= flush_idex ? 0 : inst_ld_w;
      inste_ld_b_reg <= flush_idex ? 0 : inst_ld_b;
      inste_ld_h_reg <= flush_idex ? 0 : inst_ld_h;
      inste_ld_bu_reg <= flush_idex ? 0 : inst_ld_bu;
      inste_ld_hu_reg <= flush_idex ? 0 : inst_ld_hu;
      //鐢ㄤ簬PCsrc璁＄畻
      inst_beq_reg <= flush_idex ? 0 : inst_beq;
      inst_bne_reg <= flush_idex ? 0 : inst_bne;
      inst_blt_reg <= flush_idex ? 0 : inst_blt;
      inst_bltu_reg <= flush_idex ? 0 : inst_bltu;
      inst_bge_reg <= flush_idex ? 0 : inst_bge;
      inst_bgeu_reg <= flush_idex ? 0 : inst_bgeu;
      inst_jirl_reg <= flush_idex ? 0 : inst_jirl;
      inst_bl_reg <= flush_idex ? 0 : inst_bl;
      inst_b_reg <= flush_idex ? 0 : inst_b;
      //EX-MEM
      rf_we_m_reg <= rf_we_e_reg;
      pcm_reg <= pce_reg;
      rf_wa_m_reg <= rf_wa_e_reg;
      mem_wem_reg <= mem_wee_reg;
      res_from_mem_m_reg <= res_from_mem_e_reg;
      y_reg <= alu_result;
      mdw_reg <= rkd_value;
      // rdm_reg <= rd_reg;
      // irm_reg <= ire_reg;

      //鐢ㄤ簬鍐呭瓨
      instm_st_w_reg <= inste_st_w_reg;
      instm_st_b_reg <= inste_st_b_reg;
      instm_st_h_reg <= inste_st_h_reg;
      instm_ld_w_reg <= inste_ld_w_reg;
      instm_ld_b_reg <= inste_ld_b_reg;
      instm_ld_h_reg <= inste_ld_h_reg;
      instm_ld_bu_reg <= inste_ld_bu_reg;
      instm_ld_hu_reg <= inste_ld_hu_reg;
      //MEM-WB

      final_result_wb <= final_result_mem;
      rf_we_w_reg <= rf_we_m_reg;
      pcw_reg <= pcm_reg;
      rf_wa_w_reg <= rf_wa_m_reg;
      res_from_mem_w_reg <= res_from_mem;
      mdr_reg <= mem_result;
      yw_reg <= y_reg;
      // rdw_reg <= rdm_reg;
      // irw_reg <= irm_reg;
    end
  end


  //IF Section------------------------------------------------
  assign seq_pc = pc + 3'h4;
  assign nextpc = br_taken ? br_target : seq_pc;  //TODO: fix this

  always @(posedge clk) begin
    if (reset) begin
      pc <= 32'h1bfffffc;  //trick: to make nextpc be 0x1c000000 during reset 
    end else begin
      pc <= (stall_pc || stall_all) ? pc : nextpc;
    end
  end

  assign inst_sram_we    = 1'b0;
  assign inst_sram_re    = valid;
  assign inst_sram_addr  = pc;
  assign inst_sram_wdata = 32'b0;


  //IF2 Section------------------------------------------------
  
  assign inst            = inst_sram_rdata;

  //ID Section------------------------------------------------
  assign op_31_26        = ir_reg[31:26];
  assign op_25_22        = ir_reg[25:22];
  assign op_21_20        = ir_reg[21:20];
  assign op_19_15        = ir_reg[19:15];

  assign rd              = ir_reg[4:0];
  assign rj              = ir_reg[9:5];
  assign rk              = ir_reg[14:10];

  assign i5              = ir_reg[14:10];
  assign i12             = ir_reg[21:10];
  assign i20             = ir_reg[24:5];
  assign i16             = ir_reg[25:10];
  assign i26             = {ir_reg[9:0], ir_reg[25:10]};

  decoder_6_64 u_dec0 (
      .in (op_31_26),
      .out(op_31_26_d)
  );
  decoder_4_16 u_dec1 (
      .in (op_25_22),
      .out(op_25_22_d)
  );
  decoder_2_4 u_dec2 (
      .in (op_21_20),
      .out(op_21_20_d)
  );
  decoder_5_32 u_dec3 (
      .in (op_19_15),
      .out(op_19_15_d)
  );

  assign inst_add_w = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h00];
  assign inst_sub_w = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h02];
  assign inst_slt = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h04];
  assign inst_sltu = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h05];
  assign inst_nor = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h08];
  assign inst_and = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h09];
  assign inst_or = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0a];
  assign inst_xor = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0b];
  assign inst_slli_w = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h01];
  assign inst_srli_w = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h09];
  assign inst_srai_w = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h11];
  assign inst_addi_w = op_31_26_d[6'h00] & op_25_22_d[4'ha];
  assign inst_ld_w = op_31_26_d[6'h0a] & op_25_22_d[4'h2];
  assign inst_st_w = op_31_26_d[6'h0a] & op_25_22_d[4'h6];
  assign inst_jirl = op_31_26_d[6'h13];
  assign inst_b = op_31_26_d[6'h14];
  assign inst_bl = op_31_26_d[6'h15];
  assign inst_beq = op_31_26_d[6'h16];
  assign inst_bne = op_31_26_d[6'h17];
  assign inst_lu12i_w = op_31_26_d[6'h05] & ~ir_reg[25];
  assign inst_pcaddu12i = op_31_26_d[6'h07] & ~ir_reg[25];
  assign inst_slti = op_31_26_d[6'h00] & op_25_22_d[4'h8];
  assign inst_sltui = op_31_26_d[6'h00] & op_25_22_d[4'h9];
  assign inst_andi = op_31_26_d[6'h00] & op_25_22_d[4'b1101];
  assign inst_ori = op_31_26_d[6'h00] & op_25_22_d[4'b1110];
  assign inst_xori = op_31_26_d[6'h00] & op_25_22_d[4'b1111];
  assign inst_sll_w=op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'b01110];
  assign inst_srl_w = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'b01111];
  assign inst_sra_w = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'b10000];
  assign inst_st_b = op_31_26_d[6'h0a] & op_25_22_d[4'h4];
  assign inst_st_h = op_31_26_d[6'h0a] & op_25_22_d[4'h5];
  assign inst_ld_b = op_31_26_d[6'h0a] & op_25_22_d[4'h0];
  assign inst_ld_h = op_31_26_d[6'h0a] & op_25_22_d[4'h1];
  assign inst_ld_hu = op_31_26_d[6'h0a] & op_25_22_d[4'h9];
  assign inst_ld_bu = op_31_26_d[6'h0a] & op_25_22_d[4'h8];
  assign inst_blt = op_31_26_d[6'b011000];
  assign inst_bge = op_31_26_d[6'b011001];
  assign inst_bltu = op_31_26_d[6'b011010];
  assign inst_bgeu = op_31_26_d[6'b011011];
  //end 


  //alu
  assign alu_op[ 0] = inst_add_w | inst_addi_w | inst_ld_w|inst_ld_b|inst_ld_h|inst_ld_hu|inst_ld_bu | inst_st_w|inst_st_b|inst_st_h
                    | inst_jirl | inst_bl| inst_pcaddu12i;
  assign alu_op[1] = inst_sub_w;
  assign alu_op[2] = inst_slt | inst_slti;
  assign alu_op[3] = inst_sltu | inst_sltui;
  assign alu_op[4] = inst_and | inst_andi;
  assign alu_op[5] = inst_nor;
  assign alu_op[6] = inst_or | inst_ori;
  assign alu_op[7] = inst_xor | inst_xori;
  assign alu_op[8] = inst_slli_w | inst_sll_w;
  assign alu_op[9] = inst_srli_w | inst_srl_w;
  assign alu_op[10] = inst_srai_w | inst_sra_w;
  assign alu_op[11] = inst_lu12i_w;

  //immgen
  assign need_ui5 = inst_slli_w | inst_srli_w | inst_srai_w;
  assign need_si12  =  inst_addi_w | inst_ld_w|inst_ld_h|inst_ld_hu|inst_ld_b|inst_ld_bu | inst_st_w|inst_st_b|inst_st_h | inst_slti|inst_sltui;
  assign need_ui12 = inst_andi | inst_ori | inst_xori;
  assign need_si16 = inst_jirl | inst_beq | inst_bne | inst_blt | inst_bltu | inst_bge | inst_bgeu;
  assign need_si20 = inst_lu12i_w | inst_pcaddu12i;
  assign need_si26 = inst_b | inst_bl;
  assign src2_is_4 = inst_jirl | inst_bl;

  assign imm = src2_is_4 ? 32'h4                      :
             need_si20 ? {i20[19:0], 12'b0}         :
             need_si12?{{20{i12[11]}}, i12[11:0]}   :
             need_ui12?{20'b0, i12[11:0]}           :
             need_ui5?{27'b0, i5[4:0]}:
             need_si26?{{4{i26[25]}}, i26[25:0], 2'b0}:
      /*need_si16*/{{14{i16[15]}}, i16[15:0], 2'b0};  //瀵逛簬涓や釜鐗规畩鐨勶紝宸茬粡宸︾Щ瀹屾垚

  assign br_offs = need_si26 ? {{4{i26[25]}}, i26[25:0], 2'b0} : {{14{i16[15]}}, i16[15:0], 2'b0};

  assign src_reg_is_rd = inst_beq | inst_bne |inst_blt|inst_bltu|inst_bge|inst_bgeu| inst_st_w|inst_st_b|inst_st_h;//鐗规畩鎯呭喌锛宺d浣滀负璇诲彇鐨勬簮
  assign rf_we         = (~inst_st_w&~inst_st_b&~inst_st_h& ~inst_beq & ~inst_bne & ~inst_b&~inst_blt&~inst_bltu&~inst_bge&~inst_bgeu) && valid && (pcd_reg!=0);//鍦ㄨ繖浜涙儏鍐典笅锛屼笉鍚憆f鍐欏叆
  assign rf_wa_ = dst_is_r1 ? 5'd1 : rd;

  assign rf_raddr1 = rj;
  assign rf_raddr2 = src_reg_is_rd ? rd : rk;
  regfile u_regfile (
      .clk   (clk),
      .raddr1(rf_raddr1),
      .rdata1(rf_rdata1),
      .raddr2(rf_raddr2),
      .rdata2(rf_rdata2),
      .we    (rf_we_w_reg),
      .waddr (rf_waddr),
      .wdata (rf_wdata)
  );
  assign src1_is_pc = inst_jirl | inst_bl | inst_pcaddu12i;

  assign src2_is_imm   = inst_slli_w |
                       inst_srli_w |
                       inst_srai_w |
                       inst_addi_w |
                       inst_ld_w   |inst_ld_h|inst_ld_hu|inst_ld_b|inst_ld_bu|
                       inst_st_w   |inst_st_b|inst_st_h|
                       inst_lu12i_w|
                       inst_jirl   |
                       inst_bl     |
                       inst_pcaddu12i|
                       inst_slti    |
                       inst_sltui|
                       inst_andi|
                       inst_ori|
                       inst_xori;

  assign dst_is_r1 = inst_bl;
  assign mem_we = inst_st_w | inst_st_b | inst_st_h;
  assign res_from_mem = inst_ld_w | inst_ld_h | inst_ld_hu | inst_ld_b | inst_ld_bu;

  //EX Section------------------------------------------------

  assign rj_value = rf_rd0_fe ? rf_rd0_fd : a_reg;  //靠forward
  assign rkd_value = rf_rd1_fe ? rf_rd1_fd : b_reg;

  wire rj_eq_rd;
  wire rj_lt_rd;
  wire rj_ltu_rd;
  assign rj_eq_rd = (rj_value == rkd_value);
  assign rj_lt_rd = ($signed(rj_value) < $signed(rkd_value));
  assign rj_ltu_rd = ($unsigned(rj_value) < $unsigned(rkd_value));
  assign br_taken = ( inst_beq_reg  &&  rj_eq_rd
                   || inst_bne_reg  && !rj_eq_rd
                   || inst_blt_reg && rj_lt_rd
                   || inst_bltu_reg && rj_ltu_rd
                   || inst_bge_reg && ~rj_lt_rd
                   || inst_bgeu_reg && ~rj_ltu_rd
                   || inst_jirl_reg
                   || inst_bl_reg
                   || inst_b_reg
                  ) && valid;
  assign br_target = (inst_beq_reg || inst_bne_reg || inst_bl_reg || inst_b_reg||inst_blt_reg||inst_bltu_reg||inst_bge_reg||inst_bgeu_reg) ? (pce_reg + br_offs_reg) :
      /*inst_jirl*/ (rj_value + br_offs_reg);
  // assign flush = br_taken&& br_target!=pcd_reg;  //濡傛灉纰板埌璺宠浆锛屽氨鎶婂墠涓や釜宸茬粡杩涘叆鐨勬寚浠lush鎺?

  assign alu_src1 = src1_is_pc_reg ? pce_reg[31:0] : rj_value;
  assign alu_src2 = src2_is_imm_reg ? imm_reg : rkd_value;

  alu u_alu (
      .alu_op    (alu_op_reg),
      .alu_src1  (alu_src1),
      .alu_src2  (alu_src2),
      .alu_result(alu_result)
  );



  //MEM Section------------------------------------------------
  assign data_sram_we   = mem_wem_reg && valid;
  assign data_sram_addr = y_reg;  //&(~32'h3);

  always @(*) begin
    data_sram_wdata = 32'b0;
    if (instm_st_w_reg) data_sram_wdata = mdw_reg;
    else if (instm_st_h_reg) begin
      case (data_sram_addr & 32'h3)
        32'h0: data_sram_wdata = {data_sram_rdata[31:16], mdw_reg[15:0]};
        32'h2: data_sram_wdata = {mdw_reg[15:0], data_sram_rdata[15:0]};
      endcase
    end else if (instm_st_b_reg) begin
      case (data_sram_addr & 32'h3)
        32'h0: data_sram_wdata = {data_sram_rdata[31:8], mdw_reg[7:0]};
        32'h1: data_sram_wdata = {data_sram_rdata[31:16], mdw_reg[7:0], data_sram_rdata[7:0]};
        32'h2: data_sram_wdata = {data_sram_rdata[31:24], mdw_reg[7:0], data_sram_rdata[15:0]};
        32'h3: data_sram_wdata = {mdw_reg[7:0], data_sram_rdata[23:0]};
      endcase
    end
  end
  always @(*) begin
    mem_result = 32'h0;
    // tmp_mem_result=32'h0;
    if (instm_ld_w_reg) mem_result = data_sram_rdata;
    else if (instm_ld_h_reg || instm_ld_hu_reg) begin
      case (data_sram_addr & 32'h3)
        32'h0: mem_result = {{16{instm_ld_h_reg & data_sram_rdata[15]}}, data_sram_rdata[15:0]};
        32'h2: mem_result = {{16{instm_ld_h_reg & data_sram_rdata[31]}}, data_sram_rdata[31:16]};
      endcase
    end else if (instm_ld_b_reg || instm_ld_bu_reg) begin
      case (data_sram_addr & 32'h3)
        32'h0: mem_result = {{24{instm_ld_b_reg & data_sram_rdata[7]}}, data_sram_rdata[7:0]};
        32'h1: mem_result = {{24{instm_ld_b_reg & data_sram_rdata[15]}}, data_sram_rdata[15:8]};
        32'h2: mem_result = {{24{instm_ld_b_reg & data_sram_rdata[23]}}, data_sram_rdata[23:16]};
        32'h3: mem_result = {{24{instm_ld_b_reg & data_sram_rdata[31]}}, data_sram_rdata[31:24]};
      endcase
    end
  end
  assign final_result_mem  = res_from_mem_m_reg ? mem_result : y_reg;
  //wb

  assign rf_waddr          = rf_wa_w_reg;
  assign rf_wdata          = final_result_wb;

  // debug info generate
  assign debug_wb_pc       = pcw_reg;
  assign debug_wb_rf_we    = {4{rf_we_w_reg}};
  assign debug_wb_rf_wnum  = rf_waddr;
  assign debug_wb_rf_wdata = rf_wdata;

  forward fwd (
      .rf_we_mem(rf_we_m_reg),
      .rf_we_wb(rf_we_w_reg),
      .rf_wa_mem(rf_wa_m_reg),
      .rf_wa_wb(rf_wa_w_reg),
      .rf_wd_mem(y_reg),  //靠靠靠靠靠forward
      .rf_wd_wb(final_result_wb),
      .rf_ra0_ex(rf_ra0_ex),
      .rf_ra1_ex(rf_ra1_ex),
      .rf_rd0_fe(rf_rd0_fe),
      .rf_rd1_fe(rf_rd1_fe),
      .rf_rd0_fd(rf_rd0_fd),
      .rf_rd1_fd(rf_rd1_fd)
  );
  hazard hzd (
      .memread_ex(res_from_mem_e_reg),
      .rf_we_ex(rf_we_e_reg),
      .rf_wa_ex(rf_wa_e_reg),
      .rf_ra0_id(rf_raddr1),
      .rf_ra1_id(rf_raddr2),
      .npc_sel_ex(br_taken),
      .stall_pc(stall_pc),
      .stall_if_id(stall_ifid),
      .flush_if_id(flush_ifid),
      .flush_id_ex(flush_idex),
      .flush_if1_if2(flush_if1if2),
      .stall_if1_if2(stall_if1if2),
      .stall_all(stall_all),
      .inst_sram_miss(inst_sram_miss),
      .inst_sram_rstn(inst_sram_rstn)
  );
endmodule
//TODO: 靠?
