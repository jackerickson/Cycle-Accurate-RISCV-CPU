`define LUI     7'b0110111      // lui   rd,imm[31:12]    // lui   rd,imm[31:12]
`define AUIPC   7'b00101_11      // auipc rd,imm[31:12]
`define JAL     7'b11011_11      // jal   rd,imm[xxxxx]
`define JALR    7'b11001_11      // jalr  rd,rs1,imm[11:0] 
`define BCC     7'b11000_11      // bcc   rs1,rs2,imm[12:1]
`define LCC     7'b00000_11      // lxx   rd,rs1,imm[11:0]
`define SCC     7'b01000_11      // sxx   rs1,rs2,imm[11:0]
`define MCC     7'b00100_11      // xxxi  rd,rs1,imm[11:0]
`define RCC     7'b01100_11      // xxx   rd,rs1,rs2 
`define FCC     7'b00011_11      // fencex

//FOR CCC, only ident ECALL, not other opcodes
`define CCC     7'b11100_11      // exx, csrxx



//ALU constants
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


//WBSel options
`define MEM 2'd0
`define ALU 2'd1
`define PC_NEXT 2'd2
