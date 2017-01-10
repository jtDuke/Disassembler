****************************************************************************************************************
* Beginning of Variables & EQUates Section
****************************************************************************************************************
            OPT     CRE                 
start       EQU     $1000               * Starting Address
data        EQU     $4000               * Data Address
stack       EQU     $A000               * Stack Address
minAdd      EQU     $00000000           * start of address space
maxAdd      EQU     $00FFFFFF           * end of address space
badFlag     EQU     0                   * Bad flag
goodFlag    EQU     1                   * Good flag
shift4      EQU     4                   * Shift 4 bits
shift8      EQU     8                   * Shift 8 bits 
shift12     EQU     12                  * Shift 12 bits
shift16     EQU     16                  * Shift 16 bits
task0       EQU     00                  * output command
task1       EQU     01                  * output command
task2       EQU     02                  * output command
task13      EQU     13                  * output command
length      EQU     0                   * length of effective address to be stored in data register
printCount  EQU     20                  * Amount of lines to display to console at once
CR          EQU     $0D                 * carriage return
LF          EQU     $0A                 * line feed

****************************************************************************************************************
* Initializing program
****************************************************************************************************************
            ORG     start
            
            BSR     print_intro         * Intro
mainStart   BSR     CLEAR               
            LEA     stack,SP            * Load stack pointer       
            LEA     goodbuff,A2         * buffer resides in A2
            MOVEA.L A2,A6               * reference to start of good buffer
    
in_start    BSR     INPUT


****************************************************************************************************************
* User Input
****************************************************************************************************************
            BSR     CHECK_ADD            
            CMP     #badFlag,D5
            BEQ     in_start 
            
            BSR     buffPrep
            
            MOVE.B  #task1,D0
            LEA     str_more,A1
            MOVE.W  strMore_len,D1
            TRAP    #15
            
            MOVE.B  #task2,D0
            TRAP    #15
            
            MOVE.B  (A1),D3     * copy input to D3
            
            MOVE.B  #$57,(A1)+  * write in 'W'
            MOVE.B  #$6F,(A1)   * write in 'u'
            
            CMP.B   #$31,D3     * compare ASCII 1 to D3
            BEQ     mainStart
             
            BEQ     mainStart
            
            BSR     print_exit
                         
            JMP     end
        

****************************************************************************************************************
* Purpose: looks at the address entered by the user by checking the following:
*1. checks if addresses are odd*  if yes, subtracts 1 bit to make it even.
*2. checks if starting address < $00FFFFFF*  if no, display error and prompt user for inputs
*3. checks if ending address <= $00FFFFFF*  if no, display error and prompt user for inputs
*4. checks if ending address > starting address*  if no, display error and prompt user for inputs
*5. when all conditions pass, subroutine returns to main  
* parameters:
*-A0: starting address
*-A4: ending address
*-D2: copy of address
*-D3: utility register
****************************************************************************************************************


print_intro
            MOVE.B  #13,D0
            LEA     intro,A1
            MOVE.W  intro_len,D1
            TRAP    #15
            RTS

print_exit            
            MOVE.B  #task1,D0
            LEA     exit,A1
            MOVE.W  exit_len,D1
            TRAP    #15
            RTS        

CLEAR:
            CLR     D0
            CLR     D1
            CLR     D2
            CLR     D3
            CLR     D4
            CLR     D5
            CLR     D6
            CLR     D7
            
            RTS
               
CHECK_ADD:
ca_Start
            CMP.B   #$00,D5
            BEQ     ca_error
            MOVE.B  #goodFlag,D5   * set flag to good

firstAdd    MOVE.L  A0,D2       * load address to data register
            MOVE.L  D2,D3
            ANDI.B  #1,D3       * check last bit in D2
            CMP.B   #1,D3
            BNE     lastAdd      * if 0, jump to even branch
            
            * force odd address to be even
sub1        SUBI.B  #$1,D2
            MOVE.L  D2,A0
            
            
lastAdd     MOVE.L  A4,D2
            MOVE.L  D2,D3
            ANDI.B  #1,D3
            CMP.B   #1,D3
            BNE     equ1 

            
            * force odd address to be even
sub2        SUBI.B  #$1,D2
            MOVE.L  D2,A4
   
            
equ1      * Check if starting address < $00FFFFFF 
            CMP.L   #maxAdd,A0
            BLT     equ2
         
            JMP     ca_Error
            
            * Check if ending address <= $00FFFFFF 
equ2        CMP.L   #maxAdd,A4
            BLE     equ3
            JMP     ca_Error                     
            
            * Check if ending address > starting address
equ3        CMPA.L  A0,A4
            BGT     ca_End
               
ca_Error    ***print error***
            MOVE.B  #task0,D0
            LEA     string3,A1
            MOVE.W  str_len3,D1
            TRAP    #15            
            MOVE.B  #badFlag,D5
                        
ca_End      RTS

INPUT:
            MOVE.B  #task1,D0
            LEA     string1,A1
            MOVE.W  str_len1,D1         
            TRAP    #15
            ADDA.L  #str_len1,A1         * add input immediately after string
            MOVE.B  #task2,D0      
            TRAP    #15
            JSR     asciiTOhex            * conv an A!! check for bad / good flag after checking user's address
            CMP.B   #$00,D5
            BEQ     endInput
            
            MOVEA.L A0,A4         
            MOVE.B  #task1,D0
            LEA     string2,A1
            MOVE.W  str_len2,D1         
            TRAP    #15         
            ADDA.L  #str_len2,A1
            MOVE.B  #task2,D0
            TRAP    #15
            JSR     asciiTOhex
            CMP.B   #$00,D5
            BEQ     endInput
            
           
           **********swap************
            MOVEA.L A4,A3               *store starting into register
            MOVEA.L A0,A4               *copy ending to A4
            MOVEA.L A3,A0               *store starting in A0                    
endInput    RTS

*********************************************************************************************************************
* Ascii To Hex
* 
*   Register Usage:
*       D3 - Placeholder for current ascii byte (based off of User's Inputted Address)   
*     D4 - Translated Address
*           A0 - At the end of the routine, store the converted address here
* 
*   TODO:          
*       - Replace clear commands with a an official subroutine call (not critical)
*       - Test for the length of the address given (critical)
*
*
*
*********************************************************************************************************************
asciiTOhex

            MOVEM.L D0-D4,-(SP)         * save data registers to the stack
            MOVE.B  #goodFlag,D5        * set flag to good (until proven otherwise)
            JSR     clrRegs
            MOVE    #length,D6      
      
loop2       MOVE.B  (A1)+,D3            * store current ascii byte into D3 (user's input)
            CMP.B   #$30,D3             * is ascii byte < 30??  if so, throw ascii exception
            BLT     asciiError
            CMP.B   #$3A,D3             * is ascii byte < 3A??  if so, convert to number
            BLT     num_to_hex      
            CMP.B   #$41,D3             * is ascii byte < 41??  if so, error
            BLT     asciiError
            CMP.B   #$47,D3             * is ascii byte < 47?   if so, convert to capital letter
            BLT     cap_to_hex
            CMP.B   #$61,D3             * is ascii byte < 61?   if so, error
            BLT     asciiError
            CMP.B   #$67,D3             * is ascii byte < 67?   if so, convert to lowercase letter
            BLT     lower_to_hex
            CMP.B   #$66,D3             * is ascii byte > 66?   if so, error
            BGT     asciiError  
      
resume    
            ADD     #1,D6               * increment length counter
            CMP     #6,D6               * compare to 6
            BEQ     return              * if length is 6 digits long, jump to return              
            CMP.B   #$00,(A1)           * null terminator? if so, we are done
            BEQ     return              * move to clean-up duties
            ASL.L   #4,D4               * shift D4 left by 4 bits in order to make room for next value            
            JMP     loop2               * perform clean-up duties & exit subroutine

num_to_hex
            SUBI.B  #$30,D3             * subtracting hex values leaves us with appropriate single-digit hex value
            ADD.B   D3,D4               * add latest hex value to temporary storage
            JMP     resume              * resume regularly sheduled programming

cap_to_hex

            SUBI.B  #$37,D3             * subtracting hex values leaves us with appropriate capital letter hex value
            ADD.B   D3,D4               * add latest hex value to temporary storag
            JMP     resume              * resume regularly sheduled programming

lower_to_hex
            SUBI.B  #$57,D3             * subtracting hex values leaves us with appropriate lowercase letter hex value
            ADD.B   D3,D4               * add latest hex value to temporary storag
            JMP     resume              * resume regularly sheduled programming

asciiError  MOVE.B  #00,D5              * set bad flag      
            JMP     return              * perform clean-up duties & exit subroutine

return      MOVE.L  D4,A0
            CLR     D6                  * clear counter
            MOVEM.L (SP)+,D0-D4         * load data registers from stack      
            RTS                         * return from subroutine
        
            
***************************** End of asciiTOhex routine **************************************************************




**********************************************************************************************************************
* Fills the buffer with the current address
* Parameters:
* A1: Trap Address
* A2: Pointer of buffer
FILL_ADDRESS:
            MOVEA.L  A2,A1              *load trap address with A2            
            JSR      getLong
            MOVE.B   #$09,(A2)+                                   
            RTS
          
            

* prepares buffer for filling in current address, OpCode, and EA
* Parameters:
* A0: Current address
* A1: Trap Address
* A2: Buffer Pointer
* A4: Ending Address
* D0: task number
* D1: length of str_enter
* D7: counter for number of lines printed
**********************************************************************************************************************   
buffPrep    MOVEA.L A6,A2         
            BSR     FILL_ADDRESS        * fill buffer with current address
            JSR     opDecode
            MOVE.B  #00,(A2)            * null terminater
            MOVE.B  #task13,D0
            TRAP    #15                 * print decoded Op
                              
            CMPA.L   A0,A4              * have we reached the end of our address range?
            BLE      endBuff
            
            ADDI    #1,D7               * increment counter
            CMP     #printCount,D7
            BNE     buffPrep
            
            MOVE.B  #task1,D0
            LEA     str_enter,A1
            MOVE.W  str_en_len,D1
            TRAP    #15
            
            MOVE.B  #task2,D0
            TRAP    #15
            
            MOVE.B  #$50,(A1)
            
            CLR     D7                  *reset counter
            JMP     buffPrep
            
endBuff     RTS         
          
********************************************************************************************************************** 
* Start of opDecode section - setup process for decoding instruction
* Registers used: 
*   A0/A5 = Memory pointer
*   A2 = Good buffer pointer
*   A5 = Index for jump tables      (Dynamically used)
*   A6 = Holds previous buffer spot (Dynamically used)
*   D2 = Size returned from getSize function(s)      (Dynamically used)
*   D4 = Size of Shift              (Dynamically used)
*   D5 = Pass/Fail Flag
*   D6 = Copy of D7 to shift        (Dynamically used)
*   D7 = Current Word Value
*   (A1, D0, D1 = Trap Commands) 
*   (A7 = SP)
********************************************************************************************************************** 
opDecode    MOVEM.L A4-A6/D0-D4/D6-D7,-(SP)      * Save registers
            JSR     clrRegs             * Clear registers for use
            MOVE.B  #goodFlag,D5        * Set good flag until fail
            MOVE.W  (A0)+,D7            * Move instruction to D7 & Increment pointer
            MOVEA.L A2,A3               * Store buffer location                 
            JSR     getOp               * Decode instruction Test



********************************************************************************************************************** 
* Start of opReturn section - clean up process and return to IO
********************************************************************************************************************** 
opReturn    MOVEM.L (SP)+,D6-D7/D0-D4/A4-A6   * Clean up, restore registers
            RTS              * replace with IO Call
            
            
            
            
********************************************************************************************************************** 
* Start of getOp section - decode 1st 4 bits
**********************************************************************************************************************                              
getOp       MOVE.W  D7,D6               * Move instruction to shift
            MOVE.B  #shift12,D4         * Load shifter register
            LSR.W   D4,D6               * Shift right 12 bits
            MULU    #6,D6               * Form offset           
            LEA     tbl_op,A5           * Index into the table                                                                                   
            JSR     00(A5,D6)           * Jump indirect with index (00 indicates word movement)
            RTS



********************************************************************************************************************** 
* Beginning of the main table: tbl_op
* Contains the functions per the first 4 bits of current instruction.
********************************************************************************************************************** 
tbl_op      
            JMP     hex1_0000            
            JMP     hex1_0001            
            JMP     hex1_0010
            JMP     hex1_0011
            JMP     hex1_0100
            JMP     hex1_0101
            JMP     hex1_0110
            JMP     hex1_0111
            JMP     hex1_1000
            JMP     hex1_1001
            JMP     hex1_1010
            JMP     hex1_1011
            JMP     hex1_1100
            JMP     hex1_1101
            JMP     hex1_1110
            JMP     hex1_1111

********************************************************************************************************************** 
* Case for: first four bits = 0000
* --(ORI,ANDI,SUBI,ADDI,EORI,CMPI) 
********************************************************************************************************************** 
hex1_0000   MOVE.W  D7,D6               * Fresh copy of instruction to shift
            ANDI.W  #$0F00,D6           * Isolate second byte
            MOVE.B  #shift8,D4          * Load shifter
            LSR.L   D4,D6               * Shift to LSB
            CMP.B   #$0,D6              * Is this ORI?
            BEQ     opORI               * Jump to opORI section
            CMP.B   #$2,D6              * Is this ANDI?
            BEQ     opANDI              * Jump to opANDI section
            CMP.B   #$4,D6              * Is this SUBI?
            BEQ     opSUBI              * Jump to opSUBI section
            CMP.B   #$6,D6              * Is this ADDI?
            BEQ     opADDI              * Jump to opADDI section
            CMP.B   #$A,D6              * Is this EORI?
            BEQ     opEORI              * Jump to opEORI section
            CMP.B   #$C,D6              * Is this CMPI?
            BNE     badInst             * No - bad instruction                  

opCMPI      MOVE.B  #'C',(A2)+          * Yes - Put CMPI into buff
            MOVE.B  #'M',(A2)+
            MOVE.B  #'P',(A2)+
            MOVE.B  #'I',(A2)+
            MOVE.B  #'.',(A2)+
            JSR     size2Buffer         * determine & add size to buffer
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+            
            MOVE.B  #'#',(A2)+
            JSR     getAddr             * Add immediate source
            MOVE.B  #',',(A2)+          * Add comma
            JSR     getEA               * Print off desitination operand
            JMP     end0000             * Skip to end of sub: hex1_0000
                        
opORI       MOVE.B  #'O',(A2)+          * Populate ORI into buffer
            MOVE.B  #'R',(A2)+
            MOVE.B  #'I',(A2)+
            MOVE.B  #'.',(A2)+
            JSR     size2Buffer         * determine & add size to buffer
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+            
            MOVE.B  #'#',(A2)+            
            JSR     getAddr             * Add immediate source
            MOVE.B  #',',(A2)+          * Add comma
            JSR     getEA               * Print off desitination operand
            JMP     end0000             * Skip to end of sub: hex1_0000

opANDI      MOVE.B  #'A',(A2)+          * Populate ANDI into buffer
            MOVE.B  #'N',(A2)+
            MOVE.B  #'D',(A2)+
            MOVE.B  #'I',(A2)+
            MOVE.B  #'.',(A2)+
            JSR     size2Buffer         * determine & add size to buffer
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+            
            MOVE.B  #'#',(A2)+           
            JSR     getAddr             * Add immediate source            
            MOVE.B  #',',(A2)+          * Add comma
            JSR     getEA               * Print off desitination operand
            JMP     end0000             * Skip to end of sub: hex1_0000
            
opSUBI      MOVE.B  #'S',(A2)+          * Populate SUBI into buffer
            MOVE.B  #'U',(A2)+
            MOVE.B  #'B',(A2)+
            MOVE.B  #'I',(A2)+
            MOVE.B  #'.',(A2)+
            JSR     size2Buffer         * determine & add size to buffer
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+            
            MOVE.B  #'#',(A2)+
            
            JSR     getAddr             * Add immediate source
            MOVE.B  #',',(A2)+          * Add comma
            JSR     getEA               * Print off desitination operand
            JMP     end0000             * Skip to end of sub: hex1_0000
            
opADDI      MOVE.B  #'A',(A2)+          * Populate ADDI into buffer
            MOVE.B  #'D',(A2)+
            MOVE.B  #'D',(A2)+
            MOVE.B  #'I',(A2)+
            MOVE.B  #'.',(A2)+
            JSR     size2Buffer         * Determine & add size to buffer
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+            
            MOVE.B  #'#',(A2)+
            JSR     getAddr             * Add immediate source
            MOVE.B  #',',(A2)+          * Add comma
            JSR     getEA               * Print off desitination operand
            JMP     end0000             * Skip to end of sub: hex1_0000

opEORI      MOVE.B  #'E',(A2)+          * Populate EORI into buffer
            MOVE.B  #'O',(A2)+
            MOVE.B  #'R',(A2)+
            MOVE.B  #'I',(A2)+
            MOVE.B  #'.',(A2)+
            JSR     size2Buffer         * Determine & add size to buffer
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+            
            MOVE.B  #'#',(A2)+
            JSR     getAddr             * Add immediate source
            MOVE.B  #',',(A2)+          * Add comma
            JSR     getEA               * Print off desitination operand
            JMP     end0000             * Skip to end of sub: hex1_0000
end0000     RTS
********************************************************************************************************************** 
* Case for: first four bits = 0001                                    
* MOVE.B
********************************************************************************************************************** 

hex1_0001   MOVE.B  #'M',(A2)+          * Start of MOVE.B OpCode
            MOVE.B  #'O',(A2)+
            MOVE.B  #'V',(A2)+
            MOVE.B  #'E',(A2)+
            MOVE.B  #'.',(A2)+
            MOVE.B  #'B',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+  
            JSR     getEA               * get source destination
            MOVE.B  #',',(A2)+
            JSR     swap4Move           * swap destination and source regs for getEA
            JSR     getEA     
end0001     RTS 
            
            
            
            
********************************************************************************************************************** 
* Case for: first four bits = 0010                                    
* MOVE.L, MOVEA.L
********************************************************************************************************************** 
hex1_0010   MOVE.B  #'M',(A2)+          * Start of MOVE/A.L OpCodes
            MOVE.B  #'O',(A2)+
            MOVE.B  #'V',(A2)+
            MOVE.B  #'E',(A2)+
            MOVE.B  D7,D6               * copy fresh instruction to Shift
            LSR.L   #6,D6               * shift by 6 to isolate bits 6-8 in LSB
            ANDI.W  #$07,D6             * determine if MoveA?
            CMP.B   #$1,D6              * is this a MOVEA Function?
            BNE     moveL               * no then move to . portion
            MOVE.B  #'A',(A2)+
            MOVE.B  #'.',(A2)+
            MOVE.B  #'L',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            JMP     moveLEA             * skip to filling out source destination
moveL       MOVE.B  #'.',(A2)+
            MOVE.B  #'L',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+  
moveLEA     JSR     getEA               * get source destination
            MOVE.B  #',',(A2)+
            JSR     swap4Move           * swap destination and source regs for getEA
            JSR     getEA     
end0010     RTS
 
 
 
********************************************************************************************************************** 
* Case for: first four bits = 0011                                    
* MOVE.W, MOVEA.W
********************************************************************************************************************** 
hex1_0011   MOVE.B  #'M',(A2)+          * Start of MOVE/A.W OpCodes
            MOVE.B  #'O',(A2)+
            MOVE.B  #'V',(A2)+
            MOVE.B  #'E',(A2)+
            MOVE.B  D7,D6               * copy fresh instruction to Shift
            LSR.L   #6,D6               * shift by 6 to isolate bits 6-8 in LSB
            ANDI.W  #$07,D6             * determin if move A?
            CMP.B   #$1,D6              * is this a MOVEA Function?
            BNE     moveW               * no then move to . portion
            MOVE.B  #'A',(A2)+          * yes - populate A
            MOVE.B  #'.',(A2)+
            MOVE.B  #'W',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            JMP     moveWEA             * skip to filling out source destination
moveW       MOVE.B  #'.',(A2)+
            MOVE.B  #'W',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+  
moveWEA     JSR     getEA               * get source destination
            MOVE.B  #',',(A2)+
            JSR     swap4Move           * swap destination and source regs for getEA
            JSR     getEA     
end0011     RTS 



swap4Move   CLR.L   D3                  * Clear (0000) D3 to hold swap value
            MOVE.W  D7,D6               * Copy to initial shift get reg bits 9-11
            LSR.W   #shift8,D6          * shift by 8 (9 total)
            LSR.W   #1,D6               * shift by 1 (9 total)
            ANDI.W  #$0007,D6           * Mask/Isolate last 3 bits
            OR.W    D6,D3               * Place Reg Bits Into D3 for swap
            MOVE.W  D7,D6               * Copy to get mode bits 6-8
            LSR.W   #3,D6               * shift bits 6-8 down 3 to normal ea position 3-5
            ANDI.W  #$0038,D6           * mask bits 3-5
            OR.W    D6,D3               * add the move bits into D3
            JSR     moveSize            * add the move size bits (6-7) into D3 for ea
            MOVE.W  D3,D7               * swap register mode to determine destination from ea functions
            RTS
            
            
moveSize    MOVE.W  D7,D6               * get fresh copy to determine MOVE size
            LSR.W   #shift8,D6          * shift move size bits 12-13 to LSB
            LSR.W   #shift4,D6          
            ANDI.W  #$0003,D6           * Isolate move bits
            CMP.B   #$1,D6              * is this a byte?
            BEQ     mSizeEnd            * yes - byte size already in bits 6-7 of D3
            CMP.B   #$2,D6              * is this a L?
            BEQ     moveSizeL           * yes - Or L size to D3 bits 6-7
            CMP.B   #$3,D6              * is this a W?
            BNE     badInst             * No- then badInst        
moveSizeW   ORI.W   #$0040,D3           * add size 01 in bits 6-7 (4) into D3
            JMP     mSizeEnd            * skip to end once done
moveSizeL   ORI.W   #$0080,D3           * add size 10 in bits 6-7 (4) into D3
mSizeEnd    RTS 



********************************************************************************************************************** 
* Case for: first four bits = 0100
* --(CLR,NEG,NOT,MOVEM,SWAP,JMP,JSR,NOP,RTS,LEA) 
********************************************************************************************************************** 
hex1_0100   MOVE.W  D7,D6               * Fresh copy of instruction to shift
            ANDI.W  #$0100,D6           * Test isolate 8th bit for LEA
            CMP.W   #$0100,D6           * Test if LEA
            BEQ     opLEA               * Yes finish testing for LEA
            MOVE.W  D7,D6               * Copy fresh copy of instruction to shift
            MOVE.B  #shift8,D4          * Load 8 bit shifter
            LSR.W   D4,D6               * Shift current instruction
            ANDI.W  #$000F,D6           * Isolate last 4 bits (LSB)
            MULU    #6,D6               * Form offset for next JMP table
            LEA     tbl_0100,A5         * Load next JMP table 
            JSR     00(A5,D6)           * Jump to next instruction per next 4 bits
            JMP     end0100             * Once returned from jump table, skip to end
            
opLEA       MOVE.B  #'L',(A2)+          * Start input of LEA
            MOVE.B  #'E',(A2)+
            MOVE.B  #'A',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #$09,(A2)+ 
            JSR     getEA               * Determine address to go to buffer
            MOVE.B  #',',(A2)+          * Add comma
            MOVE.B  #'A',(A2)+          * Add A(x)
            MOVE.W  D7,D6               * Copy fresh copy of instruction to shift
            MOVE.B  #9,D4               * Load 9 bit shifter
            LSR.W   D4,D6               * Shift current instruction
            ANDI.W  #$000F,D6           * Isolate last 4 bits (LSB)
            ADD.B   #$30,D6             * convert data register # to hex digit
            MOVE.B  D6,(A2)+            * register # to buffer
end0100     RTS

hex1_0101   JSR     badInst             * Invalid Instruction
            RTS
            
            ***** MOVEM Command
hex1_0110   JSR     badInst
            ADDQ.W  #2,A0
            RTS

hex1_0111   JSR     badInst             * Invalid Instruction
            RTS
            
            
********************************************************************************************************************** 
* Case for: first four bits = 1000
* --(OR) 
********************************************************************************************************************** 
hex1_1000   MOVE.W  D7,D6               * grab fresh copy to test for DIV Cases
            LSR.L   #6,D6               * shift for testing bits 6-7
            ANDI.W  #$03,D6             * mask for last 2 bits
            CMP.B   #$3,D6              * is this a badInst?
            BNE     opOR
            JMP     badInst             

opOR        MOVE.B  #'O',(A2)+          * start filling OR
            MOVE.B  #'R',(A2)+
            MOVE.B  #'.',(A2)+            
            JSR     size2Buffer         * Determine Size and add to Buffer
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            JSR     getDirBit           * get Direction Bit 0 = EA 1 =regs
            CMP.B   #%0,D6              * is this EA first?
            BNE     opOR01              * no, jmp to reg mode first
            JSR     getEA               * print off effective address
            MOVE.B  #',',(A2)+          * add comma
            MOVE.B  #'D',(A2)+          * add register BAM!
            JSR     highRegBits         * Add register number to buffer
            JMP     end1000             * jump to exit of sub: hex1_1101
            
opOR01      MOVE.B  #'D',(A2)+          * start register entry
            JSR     highRegBits         * add register number
            MOVE.B  #',',(A2)+          * add comma
            JSR     getEA               * finish with EA         

end1000     RTS



********************************************************************************************************************** 
* Case for: first four bits = 1001
* --(SUB,SUBA) - Need to look into possibilites with immediate
********************************************************************************************************************** 
hex1_1001   MOVE.B  #'S',(A2)+          * Put ADD into Buff
            MOVE.B  #'U',(A2)+
            MOVE.B  #'B',(A2)+
            JSR     getSize             * return size  in 6 & 7 into D6
            CMP.B   #%11,D6             * determine if a ADD or ADDA
            BNE     opSUB               * not size 11, then skip to ADD
            MOVE.B  #'A',(A2)+          * yep, detected 11 then ADDA
            MOVE.B  #'.',(A2)+
            MOVE.W  D7,D6               * fresh copy of instruction
            LSR.L   #shift8,D6          * shift to right to isolate 8th bits
            ANDI.W  #$0001,D6           * Isolate last bit for size
            CMP.B   #%1,D6              * compare for a 1 to determine
            BEQ     subaL               * jump to long, else word
            MOVE.B  #'W',(A2)+          * add word size into buffer
            JMP     opSUBA
subaL       MOVE.B  #'L',(A2)+          * add long size into buffer           
opSUBA      MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            **** NOTE NEED TO TEST FOR EA to ADD $
            JSR     getEA               * get source operand
            MOVE.B  #',',(A2)+
            MOVE.B  #'A',(A2)+  
            JSR     highRegBits         * Add register number to buffer
            JMP     end1101
            
opSUB       MOVE.B  #'.',(A2)+          * finish putting Add.x to buffer
            JSR     size2Buffer         * Determine Size and Add to Buffer
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            JSR     getDirBit           * get Direction Bit 0 = EA 1 =regs
            CMP.B   #%0,D6              * is this EA first?
            BNE     opSUB01             * no, jmp to reg mode first
            JSR     getEA               * print off effective address
            MOVE.B  #',',(A2)+          * add comma
            MOVE.B  #'D',(A2)+          * add register BAM!
            JSR     highRegBits         * Add register number to buffer
            JMP     end1001             * jump to exit of sub: hex1_1101
            
opSUB01     MOVE.B  #'D',(A2)+          * start register entry
            JSR     highRegBits         * add register number
            MOVE.B  #',',(A2)+          * add comma
            JSR     getEA               * finish with EA          
            
end1001     RTS            

hex1_1010   JSR     badInst             * Invalid Instruction
            RTS



********************************************************************************************************************** 
* Case for: first four bits = 1011
* --(CMP,CMPA,EOR) - Need to look into possibilites with immediate
********************************************************************************************************************** 
hex1_1011   JSR     getSize             * return size  in 6 & 7 into D6
            CMP.B   #%11,D6             * determine if a CMPA
            BNE     opCMPEOR
            MOVE.B  #'C',(A2)+          * Put SUBA into Buff
            MOVE.B  #'M',(A2)+
            MOVE.B  #'P',(A2)+
            MOVE.B  #'A',(A2)+
            MOVE.B  #'.',(A2)+
            MOVE.W  D7,D6               * fresh copy of instruction
            LSR.L   #shift8,D6          * shift to right to isolate 8th bits
            ANDI.W  #$0001,D6           * Isolate last bit for size
            CMP.B   #%1,D6              * compare for a 1 to determine
            BEQ     cmpaL               * jump to long, else word
            MOVE.B  #'W',(A2)+          * add word size into buffer
            JMP     opCMPA              * Skip to adding padding and destination
cmpaL       MOVE.B  #'L',(A2)+          * add long size into buffer           
opCMPA      MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+

            JSR     getEA               * get source operand
            MOVE.B  #',',(A2)+
            MOVE.B  #'A',(A2)+
            JSR     highRegBits         * Get address register number
            JMP     end1011             * Skip to end of sub: hex1_1011
            
opCMPEOR    MOVE.W  D7,D6               * fresh value
            JSR     getDirBit           * determine the direction bit 1 = eor 0 = cmp
            CMP.B   #%0,D6              * yes, go into CMP
            BNE     opEOR               * no, go into EOR            
                   
opCMP       MOVE.B  #'C',(A2)+          * Populate CMP
            MOVE.B  #'M',(A2)+
            MOVE.B  #'P',(A2)+
            MOVE.B  #'.',(A2)+
            JSR     size2Buffer         * Determine & add size to buffer
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            JSR     getEA               * Source Operand
            MOVE.B  #',',(A2)+
            MOVE.B  #'D',(A2)+  
            JSR     highRegBits         * Add register number to buffer
            JMP     end1011             * Skip to end of sub: hex1_1011
      
                        
opEOR       MOVE.B  #'E',(A2)+          * Populate EOR
            MOVE.B  #'O',(A2)+
            MOVE.B  #'R',(A2)+
            MOVE.B  #'.',(A2)+
            JSR     size2Buffer         * Determine & add size to buffer
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #'D',(A2)+  
            JSR     highRegBits         * Add register number to buffer            
            MOVE.B  #',',(A2)+
            JSR     getEA               * Destination Operand
                             
end1011     RTS




********************************************************************************************************************** 
* Case for: first four bits = 1100
* --(EXG,AND) 01000 DN,DN; 01001 AN,AN; 10001 DN,AN
********************************************************************************************************************** 
hex1_1100   MOVE.W  D7,D6               * copy instruction for testing
opMULU      LSR.L   #6,D6               * shift 6 to prep for mulu testing
            ANDI.W  #$3,D6              * mask last 3 bits
            CMP.B   #$3,D6              * is this MULU or MULS?
            BEQ     muluMode            * head to mulu  mode to determine immediate   
            JMP     opANDEXG            * go to bad instruction
muluMode    MOVE.W  D7,D6               * fresh copy
            LSR.L   #3,D6               * shift bits 3-5 into LSB
            ANDI.W  #$7,D6              * mask for mode bits
            CMP.B   #$7,D6              *
            BEQ     movePTR             * increment pointer by word
            JMP     badInst     

movePTR     ADDQ.W  #2,A0               * increment pointer
            JMP     badInst
        
opANDEXG    MOVE.W  D7,D6               * else copy instruction for testing EXG and AND         
            LSR.L   #3,D6               * shift by three to isolate M bits
            ANDI.B  #$1F,D6             * mask the last 5 bits
            CMP.B   #$08,D6             * is this EXG data reg to data reg?
            BEQ     opEXGd2d            * yes - head to opEXGd2d region
            CMP.B   #$09,D6             * is this EXG add reg to add reg?
            BEQ     opEXGa2a            * yes - head to opEXGa2a region
            CMP.B   #$11,D6             * is this EXG data reg to add reg?
            BEQ     opEXGd2a            * yes - head to opEXGd2a region
            
            
opAND       MOVE.B  #'A',(A2)+          * - no - start filling AND
            MOVE.B  #'N',(A2)+
            MOVE.B  #'D',(A2)+
            MOVE.B  #'.',(A2)+            
            JSR     size2Buffer         * Determine Size and add to Buffer
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            JSR     getDirBit           * get Direction Bit 0 = EA 1 =regs
            CMP.B   #%0,D6              * is this EA first?
            BNE     opAND01              * no, jmp to reg mode first
            JSR     getEA               * print off effective address
            MOVE.B  #',',(A2)+          * add comma
            MOVE.B  #'D',(A2)+          * add register BAM!
            JSR     highRegBits         * Add register number to buffer
            JMP     end1100             * jump to exit of sub: hex1_1101
            
opAND01     MOVE.B  #'D',(A2)+          * start register entry
            JSR     highRegBits         * add register number
            MOVE.B  #',',(A2)+          * add comma
            JSR     getEA               * finish with EA                  
            JMP     end1100

opEXGd2d    MOVE.B #'E',(A2)+           * start of EXG d2d:
            MOVE.B #'X',(A2)+           
            MOVE.B #'G',(A2)+
            MOVE.B #' ',(A2)+
            MOVE.B #' ',(A2)+
            MOVE.B #' ',(A2)+
            MOVE.B #' ',(A2)+
            MOVE.B #' ',(A2)+
            MOVE.B #' ',(A2)+
            MOVE.B #'D',(A2)+           * put in DXn then(,DYn) - source
            JSR    highRegBits          * put in register number n
            MOVE.B #',',(A2)+
            JSR    getEA                * get Destination register
            JMP    end1100              * skip to end of sub: hex1_1100
                        
opEXGa2a    MOVE.B #'E',(A2)+           * start of EXG a2a:
            MOVE.B #'X',(A2)+           
            MOVE.B #'G',(A2)+
            MOVE.B #' ',(A2)+
            MOVE.B #' ',(A2)+
            MOVE.B #' ',(A2)+
            MOVE.B #' ',(A2)+
            MOVE.B #' ',(A2)+
            MOVE.B #' ',(A2)+
            MOVE.B #'A',(A2)+           * put in AXn then(,AYn) - source
            JSR    highRegBits          * put in register number n
            MOVE.B #',',(A2)+
            JSR    getEA                * get destination register
            JMP    end1100              * skip to end of sub: hex1_1100
            
opEXGd2a    MOVE.B #'E',(A2)+           * start of EXG d2a:
            MOVE.B #'X',(A2)+           
            MOVE.B #'G',(A2)+
            MOVE.B #' ',(A2)+
            MOVE.B #' ',(A2)+
            MOVE.B #' ',(A2)+
            MOVE.B #' ',(A2)+
            MOVE.B #' ',(A2)+
            MOVE.B #' ',(A2)+
            MOVE.B #'D',(A2)+           * put in DXn then(,DYn) - source
            JSR    highRegBits          * put in register number n
            MOVE.B #',',(A2)+
            JSR    getEA                * get destination register
            JMP    end1100              * skip to end of sub: hex1_1100

end1100     RTS

********************************************************************************************************************** 
* Case for: first four bits = 1101
* --(ADD,ADDA)
********************************************************************************************************************** 
hex1_1101   MOVE.B  #'A',(A2)+          * Put ADD into Buff
            MOVE.B  #'D',(A2)+
            MOVE.B  #'D',(A2)+
            JSR     getSize             * return size  in 6 & 7 into D6
            CMP.B   #%11,D6             * determine if a ADD or ADDA
            BNE     opADD               * not size 11, then skip to ADD
            MOVE.B  #'A',(A2)+          * yep, detected 11 then ADDA
            MOVE.B  #'.',(A2)+
            MOVE.W  D7,D6               * fresh copy of instruction
            LSR.L   #shift8,D6          * shift to right to isolate 8th bits
            ANDI.W  #$0001,D6           * Isolate last bit for size
            CMP.B   #%1,D6              * compare for a 1 to determine
            BEQ     addaL               * jump to long, else word
            MOVE.B  #'W',(A2)+          * add word size into buffer
            JMP     opADDA
addaL       MOVE.B  #'L',(A2)+          * add long size into buffer           
opADDA      MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            **** NOTE NEED TO TEST FOR EA to ADD $
            JSR     getEA               * get source operand
            MOVE.B  #',',(A2)+
            MOVE.B  #'A',(A2)+  
            JSR     highRegBits         * Add register number to buffer
            JMP     end1101
            
opADD       MOVE.B  #'.',(A2)+          * finish putting Add.x to buffer
            JSR     size2Buffer         * Determine Size and Add to Buffer
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            JSR     getDirBit           * get Direction Bit 0 = EA 1 =regs
            CMP.B   #%0,D6              * is this EA first?
            BNE     opADD01             * no, jmp to reg mode first
            JSR     getEA               * print off effective address
            MOVE.B  #',',(A2)+          * add comma
            MOVE.B  #'D',(A2)+          * add register BAM!
            JSR     highRegBits         * Add register number to buffer
            JMP     end1101             * jump to exit of sub: hex1_1101
            
opADD01     MOVE.B  #'D',(A2)+          * start register entry
            JSR     highRegBits         * add register number
            MOVE.B  #',',(A2)+          * add comma
            JSR     getEA               * finish with EA 

end1101     RTS



********************************************************************************************************************** 
* Case for: first four bits = 1110
* --(ASd,LSd,ROd)
********************************************************************************************************************** 
hex1_1110   JSR     getSize             * returns size in bits 6 and 7 to D6
            CMP.B   #%11,D6             * yes? - jump to memory shifts
            BEQ     opShMems
opShRegs    MOVE.W  D7,D6               * fresh copy to shift by 3
            LSR.B   #3,D6               * isolate bits 3-4
            ANDI.B  #$03,D6             * mask and isolate
            CMP.B   #%00,D6             * is this a AS(d) function?
            BEQ     opASd               * yes go to AS portion
            CMP.B   #%01,D6             * is this an LS(d) function?
            BEQ     opLSd               * yes go to LS portion
            CMP.B   #%11,D6             * is this a RO(d) function?
            BNE     badInst             * no - then bad instruction
opROd       MOVE.B  #'R',(A2)+          * yes - start RO opcode
            MOVE.B  #'O',(A2)+          
            JSR     dir2Buff            * add direction to buffer
            MOVE.B  #'.',(A2)+
            JSR     size2Buffer         * determine size and add to buffer
            MOVE.B  #' ',(A2)+          * padding
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            JSR     getIR               * function for determine register and ea
            JMP     end1110 
    
opASd       MOVE.B  #'A',(A2)+          * Start AS opcode
            MOVE.B  #'S',(A2)+          
            JSR     dir2Buff            * add direction to buffer
            MOVE.B  #'.',(A2)+
            JSR     size2Buffer         * determine size and add to buffer
            MOVE.B  #' ',(A2)+          * padding
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            JSR     getIR               * function for determine register and ea
            JMP     end1110     

opLSd       MOVE.B  #'L',(A2)+          * Start LS opcode
            MOVE.B  #'S',(A2)+          
            JSR     dir2Buff            * add direction to buffer
            MOVE.B  #'.',(A2)+
            JSR     size2Buffer         * determine size and add to buffer
            MOVE.B  #' ',(A2)+          * padding
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            JSR     getIR               * function for determine register and ea
            JMP     end1110     

*Area for Memory Shifting
opShMems    MOVE.W  D7,D6               * get fresh copy to isolate bits 9-11
            LSR.L   #shift8,D6          * shift by 8 (9 total)
            LSR.L   #1,D6               * shift by 9
            ANDI.W  #$0007,D6           * isolate bits 9-11
            CMP.B   #%00,D6             * Is this a AS function?
            BEQ     opASm               * go to AS location
            CMP.B   #%01,D6             * is this a LS function?
            BEQ     opLSm               * go to LS location
            CMP.B   #%11,D6             * is this a RO function?
            BNE     badInst             * no - then bad instruction
            
opROm       MOVE.B  #'R',(A2)+          * yes - start RO opcode location
            MOVE.B  #'O',(A2)+          
            JSR     dir2Buff            * add in direction of shift
            MOVE.B  #'.',(A2)+
            MOVE.B  #'W',(A2)+          * always a word size for mem shifts
            MOVE.B  #' ',(A2)+          * padding
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            JSR     getEA               * load in effective address
            JMP     end1110             * skip to end of instructio
            
opASm       MOVE.B  #'A',(A2)+          * yes - start AS opcode location
            MOVE.B  #'S',(A2)+          
            JSR     dir2Buff            * add in direction of shift
            MOVE.B  #'.',(A2)+
            MOVE.B  #'W',(A2)+          * always a word size for mem shifts
            MOVE.B  #' ',(A2)+          * padding
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            JSR     getEA               * load in effective address
            JMP     end1110             * skip to end of instructionn

opLSm       MOVE.B  #'L',(A2)+          * yes - start AS opcode location
            MOVE.B  #'S',(A2)+          
            JSR     dir2Buff            * add in direction of shift
            MOVE.B  #'.',(A2)+
            MOVE.B  #'W',(A2)+          * always a word size for mem shifts
            MOVE.B  #' ',(A2)+          * padding
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            JSR     getEA               * load in effective address        
end1110     RTS

dir2Buff    JSR     getDirBit           * get direction bit returnd in D6
            CMP.B   #%0,D6              * is this a Right?
            BEQ     dirR                * yes populate right  
dirL        MOVE.B  #'L',(A2)+          * no populate L for left
            JMP     endDir              * then jump to ennd
dirR        MOVE.B  #'R',(A2)+
endDir      RTS
  

getIR       MOVE.W  D7,D6               * copy a fresh instrution to shift
            LSR.L   #5,D6               * shift bit 5 into LSB
            ANDI.W  #$0001,D6           * isolate 5th bit
            CMP.B   #%0,D6              * is this a count shift?
            BEQ     irCNT               * yes, populate value source
            MOVE.B  #'D',(A2)+          * no populate register source
            JMP     irSZ                * done skip to size
irCNT       MOVE.B  #'#',(A2)+          * populate value source
irSZ        JSR     highRegBits         * populate count or register number
            MOVE.B  #',',(A2)+          * populate comma
            MOVE.B  #'D',(A2)+          * populate destination register
            MOVE.W  D7,D6               * get fresh copy to isolate bits 0-2
            ANDI.W  #$0007,D6           * mask/isolate bits 0-2
            ADD.B   #$30,D6             * convert D6 to ASCII
            MOVE.B  D6,(A2)+            * add low reigster number to buffer
endIR       RTS
            
hex1_1111   JSR     badInst             * Invalid Instruction
            RTS



********************************************************************************************************************** 
* Beginning of 4xxx Op Codes table: tbl_0100 
* Contains the functions per the second  4 bits of current instruction.
********************************************************************************************************************** 
tbl_0100    *Jump table for all op codes that start with 4XXX
            JMP     hex4_0000            
            JMP     hex4_0001            
            JMP     hex4_0010
            JMP     hex4_0011
            JMP     hex4_0100
            JMP     hex4_0101
            JMP     hex4_0110
            JMP     hex4_0111
            JMP     hex4_1000
            JMP     hex4_1001
            JMP     hex4_1010
            JMP     hex4_1011
            JMP     hex4_1100
            JMP     hex4_1101
            JMP     hex4_1110
            JMP     hex4_1111
            
hex4_0000   JSR     badInst
            RTS
            
hex4_0001   JSR     badInst
            RTS
            
hex4_0010   MOVE.B  #'C',(A2)+
            MOVE.B  #'L',(A2)+
            MOVE.B  #'R',(A2)+
            MOVE.B  #'.',(A2)+
            JSR     size2Buffer         * Determine & add size to buffer
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+         
            JSR     getEA       
            RTS
            
hex4_0011   JSR     badInst
            RTS
                          
hex4_0100   MOVE.B  #'N',(A2)+
            MOVE.B  #'E',(A2)+
            MOVE.B  #'G',(A2)+
            MOVE.B  #'.',(A2)+
            JSR     size2Buffer         * Determine & add size to buffer
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+         
            JSR     getEA       
            RTS
            
hex4_0101   JSR     badInst
            RTS
            
hex4_0110   MOVE.B  #'N',(A2)+
            MOVE.B  #'O',(A2)+
            MOVE.B  #'T',(A2)+
            MOVE.B  #'.',(A2)+
            JSR     size2Buffer         * Determine & add size to buffer
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+         
            JSR     getEA       
            RTS
            
hex4_0111   JSR     badInst
            RTS
            
            
********************************************************************************************************************** 
* Case for: 0100 1000 (SWAP,MOVEM)                                                          
********************************************************************************************************************** 
hex4_1000   MOVE.W  D7,D6           * copy instruction
            LSR.L   #shift4,D6      * shift by 4 bits
            ANDI.W  #$000F,D6       * isolate last byte
            CMP.B   #$4,D6          * Determine if SWAP
            BNE     opMOVEM         * No - go to MOVEM
            MOVE.B  #'S',(A2)+      * Populate SWAP
            MOVE.B  #'W',(A2)+      * Populate SWAP
            MOVE.B  #'A',(A2)+      * Populate SWAP
            MOVE.B  #'P',(A2)+      * Populate SWAP
            MOVE.B  #$09,(A2)+      * Pad
            MOVE.B  #'D',(A2)+
            MOVE.W  D7,D6           * copy fresh instruction
            ANDI.W  #$000F,D6       * isolate last byte to detremine register of swap
            ADD.B   #$30,D6         * convert D6 to ASCII
            MOVE.B  D6,(A2)+        * populate buffer with reg number

            RTS            

opMOVEM     JSR     badInst
            RTS   

hex4_1001   JSR     badInst
            RTS   
hex4_1010   JSR     badInst
            RTS   
hex4_1011   JSR     badInst
            RTS
hex4_1100   JSR     badInst
            RTS
hex4_1101   JSR     badInst
            RTS
hex4_1111   JSR     badInst
            RTS   


********************************************************************************************************************** 
* Case for: 0100 1110 (NOP, RTS, JSR, JMP)                                                          
********************************************************************************************************************** 
hex4_1110   JSR     getSize             * determine the size for (JSR,JMP)
            CMP.B   #%10,D6             * test size bits is this JSR? (0100 1110 10..)
            BEQ     opJSR               * yes
            CMP.B   #%11,D6             * is this JMP? (0100 1110 11..)
            BEQ     opJMP               * yes
            CMP.W   #$4E75,D7           * is this RTS?
            BEQ     opRTS               * yes            
            CMP.W   #$4E71,D7           * is this NOP? (final case for valid 4EXX)
            BNE     badInst             * No set badFlag for illegal instruction
             
            MOVE.B  #'N',(A2)+          * yes - print NOP to goodBuff
            MOVE.B  #'O',(A2)+
            MOVE.B  #'P',(A2)+
            RTS
                                      
opJSR       MOVE.B  #'J',(A2)+          * yes - print JSR to goodBuff
            MOVE.B  #'S',(A2)+
            MOVE.B  #'R',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #$09,(A2)+          * adds 5 padded spaces
            JMP     getEA           

            RTS
                       
opJMP       MOVE.B  #'J',(A2)+          * yes - print JMP to goodBuff
            MOVE.B  #'M',(A2)+
            MOVE.B  #'P',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #$09,(A2)+          * adds 5 padded spaces
            *** need to call EA here, pointer at EA
            JSR     getEA               * calling EA - may the force be with you!            
            RTS
                                 
opRTS       MOVE.B  #'R',(A2)+          * yes - print RTS to goodBuff
            MOVE.B  #'T',(A2)+
            MOVE.B  #'S',(A2)+             
            RTS
            
hex2_1111   RTS    



********************************************************************************************************************** 
* Beginning of functions: badInst, getSize, size2Buffer, 
********************************************************************************************************************** 
getSize     MOVE.W  D7,D6               * copy current instruction to shift
            LSR.W   #6,D6               * move the size bits in 6-7 to LSB
            ANDI.W  #$0003,D6           * remove other non-size bits and store result into D6
            RTS

size2Buffer JSR     getSize             * run sizing Commands
            CMP.B   #%00,D6             * is tihs a byte?
            BEQ     mainB               * yes, add B to buffer
            CMP.B   #%01,D6             * is this a word?
            BEQ     mainW               * yes, add teh W to buffer
            CMP.B   #%10,D6             * is this a long?
            BNE     badInst             * No? then bad instruction
      
            MOVE.B  #'L',(A2)+          * add L to buffer
            JMP     mainEnd             * end size2Buffer sub  
            
mainB       MOVE.B  #'B',(A2)+          * add B to buffer
            JMP     mainEnd             * end size2Buffer sub
            
mainW       MOVE.B  #'W',(A2)+          * add W to buffer
mainEnd     RTS                         * end size2Buffer sub                        

highRegBits MOVE.W  D7,D6               * get fresh copy of instruction
            LSR.L   #shift8,D6          * shift by 8 (9total)
            LSR.L   #1,D6               * shift by 1
            ANDI.B  #$7,D6              * isolate last 7 bits for register number
            ADD.B   #$30,D6             * convert register number to ascii
            MOVE.B  D6,(A2)+            * put register numbert into buffer
            RTS

getDirBit   MOVE.W  D7,D6               * get fresh copy of instruction
            LSR.L   #shift8,D6          * shift to right to isolate 8th bits
            ANDI.B  #01,D6              * isolate last bit for testing & return in D6
            RTS  
            
getAddr     CMP.B   #%00,D6             * test if value is a byte - assumes D6 already loaded
            BEQ     byte2Buffer         * yes? - load B worth of address into buffer
            CMP.B   #%01,D6             * test if value is a word - assumes D6 already loaded
            BEQ     word2Buffer         * yes? - load W worth of address into buffer
            CMP.B   #%10,D6             * test if value is a long - assumes D6 already loaded
            BEQ     long2Buffer         * yes? - load L worth of address into buffer
            RTS

getLong     JSR     cmdSh1              * Clear D6 and load value for shift
            MOVE.B  #shift12,D4         * Load shifter w/12
            JSR     cmdSh2              * Shift
            MOVE.B  #shift8,D4          * Load shifter w/8
            JSR     cmdSh2              * Shift
            MOVE.B  #shift4,D4          * Load shifter w/4
            JSR     cmdSh2              * Shift
            MOVE.B  #0,D4
            JSR     cmdSh4              * Shift
            MOVE.B  #shift12,D4         * Load shifter w/12
            JSR     cmdSh4              * Shift
            MOVE.B  #shift8,D4          * Load shifter w/8
            JSR     cmdSh4              * Shift
            MOVE.B  #shift4,D4          * Load shifter w/4
            JSR     cmdSh4              * Shift
            MOVE.B  #0,D4               * Load shifter
            LSR.L   D4,D6               * Shift
            ANDI.L  #$0000000F,D6       * Isolate last bit
            JSR     Hex2ASCII           * Place value in D6 into buffer

cmdSh1      MOVEQ   #$0,D6              * Clear D6
            MOVE.L  A0,D6               * Load current address to print
            SWAP    D6                  * Swap high and low word
            RTS

cmdSh2      LSR.L   D4,D6               * Shift
            ANDI.L  #$0000000F,D6       * Isolate last bit
            JSR     Hex2ASCII           * Place value in D6 into buffer
            JSR     cmdSh1              * Reset D6 for next shift
            RTS

cmdSh3      MOVEQ   #$0,D6              * Clear D6
            MOVE.L  A0,D6               * Load current address to print
            RTS
            
cmdSh4      LSR.L   D4,D6               * Shift
            ANDI.L  #$0000000F,D6       * Isolate last bit
            JSR     Hex2ASCII           * Place value in D6 into buffer
            JSR     cmdSh3              * Reset D6 for next shift
            RTS
            
badInst     MOVE.B  #badFlag,D5         * set bad flag
            MOVEA.L A3,A2               * reset the buffer pointer 
            MOVE.B  #'D',(A2)+          * add bad syntax to goodBuff
            MOVE.B  #'A',(A2)+
            MOVE.B  #'T',(A2)+
            MOVE.B  #'A',(A2)+
            MOVE.B  #$09,(A2)+
            MOVE.B  #'$',(A2)+          * add in shift/pad
            JSR     getBadWord          * add the bad word to the buffer
            RTS          

getBadWord  MOVEQ   #$0,D6              * clear out D6 to use for copying word
            MOVE.W  D7,D6               * copy word instruction to D6
            MOVE.B  #shift12,D4         * load shifter
            LSR.L   D4,D6               * Shift D6
            ANDI.W  #$000F,D6           * isolate last 4 bits
            JSR     Hex2ASCII           * add 1st character to buffer
            MOVE.W  D7,D6
            MOVE.B  #shift8,D4
            LSR.L   D4,D6
            ANDI.W  #$000F,D6
            JSR     Hex2ASCII           * add 2nd character to buffer
            MOVE.W  D7,D6
            MOVE.B  #shift4,D4
            LSR.L   D4,D6
            ANDI.W  #$000F,D6
            JSR     Hex2ASCII           * add 3rd character to buffer
            MOVE.W  D7,D6
            ANDI.W  #$000F,D6
            JSR     Hex2ASCII           * add 4th character to buffer
            RTS
            
clrRegs     CLR.L   D0                  * clear all registers but D5 flag
            CLR.L   D1
            CLR.L   D2
            CLR.L   D3
            CLR.L   D4
            CLR.L   D6
            CLR.L   D7
            RTS



********************************************************************************************************************** 
* Hex to ASCII Routine
********************************************************************************************************************** 
Hex2ASCII   CMP.B   #$A,D6              * Confirm hex character?
            BGE     letter              * Is it a letter or number?
            ADDI.B  #$30,D6             * Convert decimal to ASCII
            BRA     write2Buff          * save to good buffer
letter      ADDI.B  #$37,D6
write2Buff  MOVE.B  D6,(A2)+
            RTS
            
            
********************************************************************************************************************** 
* EA Routine
********************************************************************************************************************** 
getEA       
            LEA         ea_mode_table,A5 * load EA_mode jump table
            CLR.L   D2
            CLR.L   D3
            CLR.L   D4           
            CLR.L   D6
            MOVE.W  D7,D6                 * move word into D6 for manipulation
            ANDI.W  #$003F,D6             * leave only the mode bits
            MOVE.B      #3,D1                 * Store number of bits we wish to shift            
            LSR.W       D1,D6                 * Shift to the Right to isolate mode bits            

            MULU      #6,D6            * Form Offset for passing to Jump Index table            
            JSR         00(A5,D6)          * Now we have the index, back to Index table        

            RTS                                * return from EA routine
        
            JMP         END                    * Return

*************************************** EA_mode jump table ************************************************************   
ea_mode_table                             * table holds the different EA modes
            JMP     EAcode000             * Direct Data Register
            JMP     EAcode001             * Direct Address Register
            JMP     EAcode010             * Indirect Address Register
            JMP     EAcode011             * Indirect Address Register with Post Increment
            JMP     EAcode100             * Indirect Address Register with Pre Decrement
            JMP     EAcode101             * Indirect Address Register using Index
            JMP     EAcode110             * 
            JMP     EAcode111             * Absolute or Immediate EA

*********  Data Register Direct Dn ***********************************************************************************   
EAcode000
            MOVE.W      D7,D6                   * move current working word into temp storage
            ANDI.W      #$7,D6                  * isolate register bits (last 3)
            MOVE.B      #$44,(A2)+              * add "D" to buffer
            ADD.B       #$30,D6                 * convert data register # to hex digit
            MOVE.B      D6,(A2)+                * register # to buffer                  
            
        RTS                                     * Return

********* Address Register Direct An **********************************************************************************   
EAcode001
            MOVE.W      D7,D6                   * move current working word into temp storage
            ANDI.W      #$7,D6                  * isolate register bits (last 3)
            MOVE.B      #$41,(A2)+              * add "A" to buffer
            ADD.B       #$30,D6                 * convert data register # to hex digit
            MOVE.B      D6,(A2)+                * register # to buffer
              
        RTS                                 * Return

****** Address Register Indirect (An) *********************************************************************************  
EAcode010
            MOVE.W      D7,D6                   * move current working word into temp storage
            ANDI.W      #$7,D6                  * isolate register bits (last 3)
            MOVE.B      #$28,(A2)+              * add "(" to buffer            
            MOVE.B      #$41,(A2)+              * add "A" to buffer
            ADD.B       #$30,D6                 * convert data register # to hex digit
            MOVE.B      D6,(A2)+                * register # to buffer
            MOVE.B      #$29,(A2)+              * add ")" to buffer
             
        RTS                                 * Return

********* Address Register Indirect w/ Post-Increment (An)+ ***********************************************************  
EAcode011
            
            MOVE.W      D7,D6                   * move current working word into temp storage
            ANDI.W      #$7,D6                  * isolate register bits (last 3)
            MOVE.B      #$28,(A2)+              * add "(" to buffer            
            MOVE.B      #$41,(A2)+              * add "A" to buffer
            ADD.B       #$30,D6                 * convert data register # to hex digit
            MOVE.B      D6,(A2)+                * register # to buffer
            MOVE.B      #$29,(A2)+              * add ")" to buffer
            MOVE.B      #$2B,(A2)+              * add "+" to buffer
                 
        RTS                                 * Return

*************** Address Register Indirect w/ Pre-Decrement -(An) ******************************************************  
EAcode100
           
            MOVE.W      D7,D6                   * move current working word into temp storage
            ANDI.W      #$7,D6                  * isolate register bits (last 3)
            MOVE.B      #$2D,(A2)+              * add "-" to buffer
            MOVE.B      #$28,(A2)+              * add "(" to buffer            
            MOVE.B      #$41,(A2)+              * add "A" to buffer
            ADD.B       #$30,D6                 * convert data register # to hex digit
            MOVE.B      D6,(A2)+                * register # to buffer
            MOVE.B      #$29,(A2)+              * add ")" to buffer
            
        RTS                                     * Return



******************** Address Register Indirect w/ Displacement *********************************************************
EAcode101
             JMP    badInst          * set bad instruction flag


********************* Address Register w/ Index ************************************************************************
EAcode110
            JMP       badInst             * set bad instruction flag



******* Absolute (.W | .L) | Immediate | PC w/ Index | PC w/ Displacement **********************************************
EAcode111
            JSR      regBits             * Get Register bits
            CMPI.B   #$0,D6              * compare to determine if it's a word
            BEQ      word2Buffer         * put word address in buffer
            CMPI.B   #$1,D6              * compare to determine if it's a long
            BEQ      long2Buffer         * put long address in buffer
            CMPI.B   #$2,D6

            CMPI.B   #$2,D6              * compare to determine if it's PC w/ Displacement
            BEQ      PCwDisp             
            CMPI.B   #$4,D6              * compare to determine if it's Immediate
            BEQ      imm2Buffer          * DON"T HAVE THIS CASE YET
           
            RTS

*************************************************************************************************************************
* EA SubRoutines   
*************************************************************************************************************************  

*** regBits ***
regBits     MOVE.W  D7,D6     * change D2 to A0  (simulating address)
            ANDI.W  #$07,D6
            RTS
            
**** imm2Buffer ***
imm2Buffer
            MOVE.B      #'#',(A2)+
            JSR         moveSize
            CMPI.B      #$1,D6              * compare to determine if it's a word
            BEQ         byte2Buffer         * put word address in buffer
            CMPI.B      #$3,D6              * compare to determine if it's a long
            BEQ         word2Buffer         * put long address in buffer.            
            CMPI.B      #$2,D6
            BEQ         long2Buffer
            RTS
            
**** PCwDisp ***********************************************************************************************************
PCwDisp
            JSR         word2Buffer
            MOVE.B      #$28,(A2)+              * add "(" to buffer            
            MOVE.B      #$50,(A2)+              * add "P" to buffer
            MOVE.B      #$43,(A2)+              * add "C" to buffer
            MOVE.B      #$29,(A2)+              * add ")" to buffer                        
            RTS
            
**** byte2Buffer *******************************************************************************************************
byte2Buffer   
            MOVE.B  #'$',(A2)+
            CLR.L   D4          * pre-emptive clearout
            MOVE.W  (A0),D2       * move current word into D2 for rolling purposes
            CLR.L   D4          * pre-emptive clearout
            MOVE.B  #2,D4       * load a counter

b2bLoop                 
            CMP.B   #$00,D4     * compare counter with 0
            BEQ     rtnEA0      * if zero, return
            ROL.B   #4,D2       * roll the bits in D2 to the left
            MOVE.W  D2,D6       * move rolled bits into temp storage
            ANDI.W  #$000F,D6   * and the bits to isolate ascii char   
            JSR     Hex2ASCII   * load ascii char into buffer            
            SUBQ.B  #$1,D4      * subtract from counter
            JMP     b2bLoop     * keep looping until counter hits zero
            
rtnEA0      MOVE.W  D7,D6       * re-load current word for temp storage            
            ADDQ.W  #2,A0       * advancing memory pointer by word   
            RTS                 * return from subroutine
            
**** word2Buffer *******************************************************************************************************
word2Buffer 
            MOVE.B  #'$',(A2)+  
            CLR.L   D4          * pre-emptive clearout
            *MOVE.B  #$24,(A2)+  * put dollar sign in buffer (before address)
            MOVE.W  (A0),D2       * move current word into D2 for rolling purposes
            CLR.L   D4          * pre-emptive clearout
            MOVE.B  #4,D4       * load a counter

w2bLoop                 
            CMP.B   #$00,D4     * compare counter with 0
            BEQ     rtnEA1      * if zero, return
            ROL.W   #4,D2       * roll the bits in D2 to the left
            MOVE.W  D2,D6       * move rolled bits into temp storage
            ANDI.W  #$000F,D6   * and the bits to isolate ascii char   
            JSR     Hex2ASCII   * load ascii char into buffer            
            SUBQ.B  #$1,D4      * subtract from counter
            JMP     w2bLoop     * keep looping until counter hits zero
            
rtnEA1      MOVE.W  D7,D6       * re-load current word for temp storage            
            ADDQ.W  #2,A0       * advancing memory pointer by word   
            RTS                 * return from subroutine

**** long2Buffer *******************************************************************************************************
long2Buffer
            MOVE.B  #'$',(A2)+
            CLR.L   D4          * pre-emptive clearout
            MOVE.L  (A0),D2       * move current word into D2 for rolling purposes
            CLR.L   D4          * pre-emptive clearout
            MOVE.B  #8,D4       * load a counter

l2bLoop                 
            CMP.B   #$00,D4     * compare counter with 0
            BEQ     rtnEA2      * if zero, return
            ROL.L   #4,D2       * roll the bits in D2 to the left
            MOVE.W  D2,D6       * move rolled bits into temp storage
            ANDI.W  #$000F,D6   * and the bits to isolate ascii char   
            JSR     Hex2ASCII   * load ascii char into buffer            
            SUBQ.B  #$1,D4      * subtract from counter
            JMP     l2bLoop     * keep looping until counter hits zero
            
rtnEA2      MOVE.W  D7,D6       * re-load current word for temp storage
            ADDQ.W  #4,A0       * advancing memory pointer by long
            RTS                 * return from subroutine

*********************************************************************************************************************
* Beginning of data space:
*********************************************************************************************************************     
            ORG     data
intro        DC.B    '************************************************************************',CR,LF     
             DC.B    '*            (    (       ( /( ',CR,LF
             DC.B    '*            )\ ) )\ (    )\())',CR,LF
             DC.B    '*           (()/(((_))\ |((_)\          ',CR,LF
             DC.B    '*             /(_)) _((_)|_ ((_)',CR,LF
             DC.B    '*           (_) / ( _ ) | |/ / ',CR,LF
             DC.B    '*            / _ \/ _ \   . <',CR,LF
             DC.B    '*            (___/\___/  _|\_\',CR,LF
             DC.B    '*       /(  (          )            (     )    ( /(  )\   (   (    ',CR,LF
             DC.B    '*     /(_)) )\  (   ( /(  (   (    ))\   (     )\())((_) ))\  )(   ',CR,LF
             DC.B    '*    (_))_ ((_) )\  )(_)) )\  )\  /((_)  )\  ((_)\  _  /((_)(()\  ',CR,LF
             DC.B    '*     |   \ (_)((_)((_)_ ((_)((_)(_))  _((_)) | |(_)| |(_))   ((_) ',CR,LF
             DC.B    '*     | |) || |(_-</ _` |(_-<(_-</ -_)| .  \()| ._ \| |/ -_) | ._| ',CR,LF
             DC.B    '*     (___/ |_|/__/\__,_|/__//__/\___||_|_|_| |_.__/|_|\___| |_|   ',CR,LF
             DC.B    '*          (()/( (         (     (       ( /( ',CR,LF
             DC.B    '*          /(_)))(    (   )\   ))\  (   )\())',CR,LF
             DC.B    '*         (_)) (()\   )\ ((_) /((_) )\ (_))/ ',CR,LF
             DC.B    '*         | _ \ ((_) ((_)  ! (_))  ((_)| |_  ',CR,LF
             DC.B    '*         |  _/| ._|/ _ \ | |/ -_)/ _| |  _|',CR,LF
             DC.B    '*         |_|  |_|  \___/_/ |\___|\__|  \__|',CR,LF
             DC.B    '*                       |__/                            ',CR,LF
             DC.B    '************************************************************************',CR,LF,CR,LF
             DC.B    '**Please enter a starting and ending address, per the below guidelines**:',CR,LF
             DC.B    'Any Odd starting address will be converted to an Even address',CR,LF
             DC.B    'Only the first 6 characters of input will be read, all other characters',CR,LF,CR,LF
             DC.B    'All other characters past 6 characters will be ignored',CR,LF,0

intro_len   DC.W    intro_len-intro
        
string1     DC.B    'Enter starting address: $',0
str_len1    DC.W    str_len1-string1  *Get the length of the string

string2     DC.B    'Enter ending address: $',0
str_len2    DC.W    str_len2-string2  *Get the length of the string

string3     DC.B    'Error: starting or ending address has equality error',0
str_len3    DC.W    str_len3-string3

err_start   DC.B    'Error: invalid hex values for starting address.',0
err_len1    DC.W    err_start-err_len1

err_end     DC.B    'Error: invalid hex values for ending address.',0
err_len2    DC.W    err_end-err_len2

str_enter   DC.B    'Press enter to read more data',0
str_en_len  DC.W    str_enter-str_en_len

str_more    DC.B    'Would you like to disassemble more code? YES = 1, NO = 0: ',0
strMore_len DC.W    strMore_len-str_more       

str_test    DC.B    'test string',0
str_te_len  DC.W    str_test-str_te_len

exit        DC.B    'Exiting program. Have a wonderful day!',0
exit_len    DC.W    exit_len-exit           

goodbuff    DC.B   1
                                 
*************************************************************************************************************************
* End of program:
*************************************************************************************************************************        
END         STOP    #$2700
            END     start










*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
