		B main
width   DEFW 12


buffer  DEFB "01234567890123456789012345678901",0

                ALIGN
main
;8 bytes of memory available
;********************************************************
;BRANCH-RET	;COMMAND	;ACTION		;COMMENTS
;--------------------------------------------------------
		;BL ruleIn
		
	;initialising registers

		MOV R3,#0			;STORE Register 2 ==> space counter (tik-tok)
		MOV R10,#0
		MOV R2,#0
		MOV R4,#0			;R4 tracks the length of a word
		MOV R11,#0			;initialise pointer to start of buffer
		LDR R5,width
		MOV R6,R5
		ADD R6,R6,#1
start

;FIX: if linecount is 0 and backspace then RESTART
;ISSUE: NEED to fix printing newline before a word greater than 13
;ISSUE: with the space, R3 updating and not branching correctly in space function
;ISSUE: with ^L printing at the begining of some text, figure out why...
;ISSUE: when line > limit, doesnt print new line (carriage return does work)



							;SCAN input
	
	;initialising registers
	
		MOV R1,R0			;STORE Register 1
		MOV R8,#0
		ADR R8,buffer
		
		BL inStore			;CAPTURE keyboard input and store, analyse len
		BL read				;can be called by other loops (move R14 to R13 and back)
		B start	

		B end				;BRANCH

end		SWI 2

;*********************************************
;		PROGRAM END
;*********************************************
							;<Rdest>,[<Rbase>],<Roffset>

;		 FUNCTIONS
;		***********

		;INSTORE-------
carReset	;MOV R0,#10
		;MOV R2,#0
		;MOV R3,#0
		;MOV R10,#0
		;MOV R4,#0
		MOV R7,#1
		MOV R12,#0
		B carCont

bsCheck	CMP R0,#8
		BEQ bsCheckCont
		B bsCont

bsCheckCont	MOV R0,#32
		SWI 0
		B storeCond



multiCheck	CMP R1,#32
		BEQ bypMulti
		CMP R1,#10
		BEQ bypMulti
		B noMulti
									;while loop which copys into register location + wordLen
inStore		MOV R11,R8
		ADD R10,R10,#1				;counts calls to BL read per line
		ADD R3,R3,#1
		B storeCond
noMulti
loopStore	MOV R0,R1				;shift back R0
		STRB R0,[R8,#1]!			;loop 	;reg-shift compensation required
		ADD R2,R2,#1
		ADD R4,R4,#1

bypMulti	CMP R0,#35
		BEQ hashCq
		ADD R9,R9,#1
		B storeCond	;BRANCH

resetR12	MOV R12,#0
		B R2cont
backSub	SUB R12,R12,#2
		SUB R2,R2,#2
		B subCont

res		MOV R12,#0
		B resCont



storeCond	SWI 1
		ADD R12,R12,#1
		CMP R0,#35
		BEQ end
		CMP R0,#8
		BEQ backSub
subCont		SWI 0
		CMP R2,#0
		BEQ bsCheck					;if R2 (lineLen) < 1, disallow SWI 0
		MOV R1,R0
		MOV R13,R14
		CMP R12,#12
		BGT resetR12
R2cont		BL rubOut				;R0, returns number of chars been deleted
		CMP R12,#11
		BGE res
resCont
		MOV R14,R13
		MOV R10,R0					;shift return value (chars to delete to R10), as per brief
		MOV R0,R1					;return original R0 value
bsCont
		MOV R1,R0					;shift away R0 for comparison
		MOV R9,R8
		LDRB R0,[R9],#-1
		CMP R0,R1					;R0 is old value, R1, new value
		BEQ multiCheck
		MOV R0,R1
		CMP R0,#10
		BEQ carReset 		
		CMP R0,#32					;conditionals	;R4 = #32 (space)
		BNE loopStore				;BRANCH
		MOV R12,#0
		ADD R2,R2,#1
		CMP R2,R6
		BEQ bypass
carCont		STRB R0,[R8,#1]!		;STORE: space at word end 		(#32)
bypass		
		MOV R0,#0
		STRB R0,[R8,#1]!			;STORE: NULL char at end of string	(#0)
		ADD R11,R11,#1				;shift register to correct location for printing		
		MOV R8,R11
		CMP R2,R6
		BEQ toRead
		MOV PC,R14

toRead		MOV R0,#48	
		B readCond


		
		;READ-----

newline		MOV R0,#10				;just print newline without backspace
		SWI 0
		MOV R2,#0
		MOV R3,#0
		B break

finish
read		MOV R8,R11
		CMP R2,R5
		BGE readGr		
cont2		MOV R0,#48				;set to ASCII 0 for comparison conditional breaks on #0
		ADD R10,R10,#1				;counts calls to BL read
		B readCond					;shift R8=>R11 for next call

readLoop	LDRB R0,[R8],#1
		CMP R0,#35
		BEQ end
		CMP R0,#0
		BEQ break
		;CMP R0,#10		
		;BEQ nlSpace
		SWI 0
			;ADD R2,R2,#1
		B readCond	;BRANCH

readCond		;CMP R2,#11
			;BGE readGr
		CMP R0,#0					;loop counter against word len
		BNE readLoop
		CMP R7,#1
		BEQ resetLineCount
break		CMP R2,R6
		BGE newline
		B start

resetLineCount	MOV R2,#0
		MOV R7,#0
		B start
		
		;READGR-------

readGr			;MOV R0,#10
			;SWI 0
		CMP R7,#1
		BEQ resetLineCount
		CMP R3,#1					;if more than one word, and greater than 12 
		BGT delSpaceNl
cont		MOV R0,#48				;set to ASCII 0 for comparison conditional breaks on #0
		MOV R8,R11
		B readGrCond				;shift R8=>R11 for next call

		;CMP R2,#13
		;BEQ newline
readGrLoop	LDRB R0,[R8],#1
		CMP R0,#35
		BEQ end

		CMP R0,#32					;if equal to space, print newline instead
		BEQ rGend
		SWI 0
		
		CMP R0,#10
		BEQ reset
		
		B readGrCond				;BRANCH
reset		MOV R2,#0
		B start




readGrCond	CMP R0,#32				;if equal to space, print newline
		BNE readGrLoop
		B start						;BRANCH


rGend	MOV R0,#10
		SWI 0
		MOV R10,#0
		MOV R2,#0
		MOV R12,#0
		B start
delSpaceNl	CMP R2,R5
		BEQ cont
		MOV R0,#8
		SWI 0
		MOV R0,#10
		SWI 0
		MOV R3,#0
	;for now just set to 0
		ADD R4,R4,#1
		MOV R2,R4

					;possibly add 1 to account for newline on space

		B read
					;need to move word len to line len then branch to read
					;may not matter because should print until the NULL character	

		;HASH------

hashCq	MOV R12,R14
		SUB R2,R2,#1
		SUB R4,R4,#1
		MOV R0,#0
		STRB R0,[R8,#1]!			;STORE: NULL char at end of string	(#0)
		ADD R11,R11,#1				;shift register to correct location for printing		
		MOV R8,R11
		;SUB R4,R4,#1				;subtract 1 to remove space

		BL read
		MOV R14,R12

		B end



		;RULER-----

ruleIn	MOV R0,#1
		MOV R9,#9
		B ruleLp

rule	SWI 4
		ADD R0,R0,#1
		B ruleLp
	
ruleLp	CMP R9,R0
		BGE rule
		
		MOV R0,#0
		SWI 4
		MOV R0,#1
		SWI 4
		MOV R0,#2
		SWI 4
		MOV R0,#10
		SWI 0
		MOV R0,#0
		MOV R9,#0
		B start	

        SWI 2

;rubOut subroutine/function:

rubOut	CMP R0,#32
		BEQ startRub
		CMP R0,#10
		BEQ startRub
		MOV PC,R14

startRub	MOV R0,#8
		MOV R10,#0
		B rubCond

rubLoop	SWI 0
		ADD R10,R10,#1
		B rubCond

rubCond	CMP R10,R12
		BLT rubLoop

		MOV R0,R10
		MOV PC,R14		

;erroneous code
;code for call
;		MOV R13,R14
;		BL rubOut
;		MOV R4,R13