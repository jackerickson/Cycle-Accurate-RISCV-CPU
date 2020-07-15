`define LUI     7'b011_0111      // lui   rd,imm[31:12]    // lui   rd,imm[31:12]
`define AUIPC   7'b001_0111      // auipc rd,imm[31:12]
`define JAL     7'b110_1111      // jal   rd,imm[xxxxx]
`define JALR    7'b110_0111      // jalr  rd,rs1,imm[11:0] 
`define BCC     7'b110_0011      // bcc   rs1,rs2,imm[12:1]
`define LCC     7'b000_0011      // lxx   rd,rs1,imm[11:0]
`define SCC     7'b010_0011      // sxx   rs1,rs2,imm[11:0]
`define MCC     7'b001_0011      // xxxi  rd,rs1,imm[11:0]
`define RCC     7'b011_0011      // xxx   rd,rs1,rs2 
`define FCC     7'b000_1111      // fencex

//FOR CCC, only ident ECALL, not other opcodes
`define CCC     7'b111_0011      // exx, csrxx



//ALU select codes
`define ADD 0
`define AND 1
`define OR 2
`define SLL 3
`define SLT 4
`define SRA 5
`define SRL 6
`define SUB 7
`define XOR 8
`define SLTU 9
`define LUIOP 11
`define JADD 12

//ALUinput mux bypass ops
`define MX 2'd0
`define WX 2'd1
`define NONE 2'd2

//WBSel options
`define MEM 2'd0
`define ALU 2'd1
`define PC_NEXT 2'd2

//Access size
`define BYTE 2'd0
`define HALFWORD 2'd1
`define WORD 2'd2
