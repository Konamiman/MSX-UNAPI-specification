; Example of Nextor driver containing a UNAPI implementation + a BASIC CALL statement
; By Konamiman, 5/2019
;
; This driver does not implement any actual Nextor device, and
; implements a sample UNAPI mathematical specification, "SIMPLE_MATH",
; which has just two functions:
;    Function 1: Returns HL = L + E
;    Function 2: Returns HL = L * E
;
; Search for "TODO" comments for what to change/extend when creating your own implementation.
;
; Also, it implements a very simple BASIC CALL statement command:
; CALL SAY("whatever"), which will just print whatever string is supplied
; as a parameter.
;
; Additionally to this driver, a string with the UNAPI implementation identifier 
; must be placed in the ROM so that it is visible at address APIINFO
; when either the Nextor kernel ROM bank 0 or 3 is switched
; (the MKNEXROM tool does that when using the /e option).
;
; The Nextor related code is just succintly commented, please see
; the Nextor Driver Development Guide or the example dummy driver
; in https://github.com/Konamiman/Nextor for more details.
;
; How to build:
;
; 1. Get sjasm (https://github.com/Konamiman/Sjasm/releases)
;
; 2. Get MKNEXROM.EXE and the Nextor kernel base file (Nextor-<version>.base.dat) 
;    from the latest release of Nextor (https://github.com/Konamiman/Nextor/releases)
;
; 3. Build the driver and the identifier string:
;    sjasm unapi-nextor.asm unapi-nextor.drv
;    sjasm unapi-nextor-id.asm unapi-nextor-id.dat
;
; 4. Build the Nextor kernel ROM:
;    mknexrom Nextor-<version>.base.dat nextor.rom /d:unapi-nextor.dat /e:unapi-nextor-id.dat
;
; 5. Done! nextor.rom is a full Nextor kernel with ASCII16 mapper and a dummy driver.


	org	4000h

    ds 256  ;Required for MKNEXROM.EXE

DRV_START:


;=======================
;===  MSX CONSTANTS  ===
;=======================

;--- BIOS

CALSLT:	equ	001Ch
CHPUT:	equ	00A2h
CALBAS: equ 0159H	;Call a routine in the BASIC interpreter, IX=routine

;--- BASIC interpreter
;    See MSX2 Technical Handbook chapter 2 for details on these

SYNERR:	equ	4055h ;Throw "Syntax Error"
TYPEM:	equ	406Dh ;Throw "Type Mismatch"
CHRGTR:	equ	4666h
FRMEVL:	equ	4C64h
FRESTR:	equ	67D0h	

;--- Page 3 work area

VALTYP:	equ	0F663h
DAC: 	equ	0F7F6h
ARG:	equ	0F847h
PROCNM:	equ	0FD89h
EXPTBL:	equ	0FCC1h


;=================================
;===  NEXTOR DRIVER CONSTANTS  ===
;=================================

;Nextor driver version

VER_MAIN	equ	1
VER_SEC		equ	0
VER_REV		equ	0

;Invoke the routine at CODE_ADD with kernel main bank swithced on
CALLB0: equ 403Fh

;Call a routine in another bank
CALBNK	equ	4042h

;Get the current slot for page 1
GSLOT1	equ	402Dh

;First direct driver call entry point
DRV_DIRECT0: equ 7850h

;Start of unused space in Nextor kernel, used here for the UNAPI implementation name
APIINFO: equ 7BD0h

;Address of the routine to be executed by CALLB0
CODE_ADD: equ 0F1D0h


;=========================
;===  UNAPI CONSTANTS  ===
;=========================

;--- API version and implementation version

;TODO: Adjust for your implementation

API_V_P:	equ	1
API_V_S:	equ	0
ROM_V_P:	equ	1
ROM_V_S:	equ	0

;--- Maximum number of available standard and implementation-specific function numbers

;TODO: Adjust for your implementation

;Maximum function number
;Must be 0 to 127
MAX_FN:		equ	2

;Maximum implementation-specific function number
;Must be either zero (if no implementation-specific functions available), or 128 to 254
MAX_IMPFN:	equ	0


;==============================
;===  NEXTOR DRIVER HEADER  ===
;==============================

; See the Nextor Driver Development Guide in https://github.com/Konamiman/Nextor for more details.

	db	"NEXTOR_DRIVER",0	;Driver signature
	db	1	;Device-based driver
	db	0	;Reserved

DRV_NAME:
    ;TODO: Adjust for your implementation
	db	"Driver with UNAPI example"
	ds	32-($-DRV_NAME)," "


    ; Jump table for the driver public routines

	jp	DRV_TIMI
	jp	DRV_VERSION
	jp	DRV_INIT
	jp	DRV_BASSTAT
	jp	DRV_BASDEV
	;;; Relevant for UNAPI
    jp  UNAPI_EXTBIO
    jp  UNAPI_ENTRY	;Calling DRV_DIRECT0 in bank 0 or 3 redirects here
	;;; END of relevant for UNAPI
    jp  GO_DRV_DIRECT1	;This one would be used if a second UNAPI specification is implemented
    jp  GO_DRV_DIRECT2
    jp  GO_DRV_DIRECT3
    jp  GO_DRV_DIRECT4

	ds	15

	jp	DEV_RW
	jp	DEV_INFO
	jp	DEV_STATUS
	jp	LUN_INFO


;================================
;===  NEXTOR DRIVER ROUTINES  ===
;================================

; See the Nextor Driver Development Guide in https://github.com/Konamiman/Nextor for more details.

; Timer interrupt routine, it will be called on each timer interrupt
DRV_TIMI:
	ret

; Driver initialization routine
DRV_INIT:
	xor	a
	ld	hl,0
	ret

; Obtain driver version
DRV_VERSION:
	ld	a,VER_MAIN
	ld	b,VER_SEC
	ld	c,VER_REV
	ret

; BASIC expanded device handler
DRV_BASDEV:
	scf
	ret

; Direct calls entry points
; (we only use DRV_DIRECT0, which jumps to UNAPI_ENTRY)
GO_DRV_DIRECT1:
GO_DRV_DIRECT2:
GO_DRV_DIRECT3:
GO_DRV_DIRECT4:
	ret

; Read or write logical sectors from/to a logical unit
DEV_RW:
	ld	a,0FCh	;.NRDY
	ld	b,0
	ret

; Device information gathering
DEV_INFO:
	ld	a,1
	ret

; Obtain device status
DEV_STATUS:
	xor	a
	ret

; Obtain logical unit information
LUN_INFO:
	ld	a,1
	ret


;==============================
;===  UNAPI EXTBIO HANDLER  ===
;==============================

; Works the expected way, except that it must return
; D'=1 if the old hook must be called, D'=0 otherwise.
; It is entered with D'=1.

UNAPI_EXTBIO:
    push	hl
	push	bc
	push	af
	ld	a,d
	cp	22h
	jr	nz,JUMP_OLD
	cp	e
	jr	nz,JUMP_OLD

	;Check API ID

	ld	hl,UNAPI_ID
	ld	de,ARG
LOOP:	ld	a,(de)
	call	TOUPPER
	cp	(hl)
	jr	nz,JUMP_OLD2
	inc	hl
	inc	de
	or	a
	jr	nz,LOOP

	;A=255: Jump to old hook

	pop	af
	push	af
	inc	a
	jr	z,JUMP_OLD2

	;A=0: B=B+1 and jump to old hook

	pop	af
	pop	bc
	or	a
	jr	nz,DO_EXTBIO2
	inc	b
    pop hl
    ld	de,2222h
	ret
DO_EXTBIO2:

	;A=1: Return A=Slot, B=Segment, HL=UNAPI entry address

	dec	a
	jr	nz,DO_EXTBIO3
	pop	hl
    xor a
    ld ix,GSLOT1
    call CALBNK
	ld	b,0FFh
	ld	hl,DRV_DIRECT0
	ld	de,2222h
    exx
    ld d,0  ;D'=0 --> don't execute old hook
    exx
	ret

	;A>1: A=A-1, and jump to old hook

DO_EXTBIO3:	;A=A-1 already done
	pop hl
	ld	de,2222h
	ret

	;--- Jump here to execute old EXTBIO code

JUMP_OLD2:
	ld	de,2222h
JUMP_OLD:	;Assumes "push hl,bc,af" done
	pop af
    pop bc
    pop hl
	ret

UNAPI_ID:
	db	"SIMPLE_MATH",0	

TOUPPER:
	cp	"a"
	ret	c
	cp	"z"+1
	ret	nc
	and	0DFh
	ret
	

;================================
;===  UNAPI ENTRY POINT CODE  ===
;================================

UNAPI_ENTRY:
	push	hl
	push	af
	ld	hl,FN_TABLE
	bit	7,a

	if MAX_IMPFN >= 128

	jr	z,IS_STANDARD
	ld	hl,IMPFN_TABLE
	and	01111111b
	cp	MAX_IMPFN-128
	jr	z,OK_FNUM
	jr	nc,UNDEFINED
IS_STANDARD:

    else

	jr	nz,UNDEFINED

    endif

	cp	MAX_FN
	jr	z,OK_FNUM
	jr	nc,UNDEFINED

OK_FNUM:
	add	a,a
	push	de
	ld	e,a
	ld	d,0
	add	hl,de
	pop	de

	ld	a,(hl)
	inc	hl
	ld	h,(hl)
	ld	l,a

	pop	af
	ex	(sp),hl
	ret

	;--- Undefined function: return with registers unmodified

UNDEFINED:
	pop	af
	pop	hl
	ret


;=========================================
;===  UNAPI FUNCTIONS ADDRESSES TABLE  ===
;=========================================

;TODO: Adjust for the routines of your implementation

;--- Standard routines addresses table

FN_TABLE:
FN_0:	dw	FN_INFO
FN_1:	dw	FN_ADD
FN_2:	dw	FN_MULT


;--- Implementation-specific routines addresses table

	if MAX_IMPFN >= 128

IMPFN_TABLE:
FN_128:	dw	FN_DUMMY

	endif


;==============================
;===  UNAPI FUNCTIONS CODE  ===
;==============================

;--- Mandatory routine 0: return API information
;    Input:  A  = 0
;    Output: HL = Descriptive string for this implementation, on this slot, zero terminated
;            DE = API version supported, D.E
;            BC = This implementation version, B.C.
;            A  = 0 and Cy = 0
;
; REMEMBER: The API identifier string must be visible at APIINFO address in bank 0

FN_INFO:
	ld	bc,256*ROM_V_P+ROM_V_S
	ld	de,256*API_V_P+API_V_S
	ld	hl,APIINFO
	xor	a
	ret

;TODO: Replace the FN_* routines below with the appropriate routines for your implementation

;--- Sample routine 1: adds two 8-bit numbers
;    Input: E, L = Numbers to add
;    Output: HL = Result

FN_ADD:
	ld	h,0
	ld	d,0
	add	hl,de
	ret


;--- Sample routine 2: multiplies two 8-bit numbers
;    Input: E, L = Numbers to multiply
;    Output: HL = Result

FN_MULT:
	ld	b,e
	ld	e,l
	ld	d,0
	ld	hl,0
MULT_LOOP:
	add	hl,de
	djnz	MULT_LOOP
	ret


;=======================================
;===  BASIC CALL STATEMENTS HANDLER  ===
;=======================================

;Implements CALL SAY("whatever"), which just prints back whatever string is supplied.

DRV_BASSTAT:

	push	hl	;BASIC program pointer, must be kept up to date!

	;--- Check if it's our command
	
	ld	hl,PROCNM
	ld	de,SAY_S
	call COMP_STR

	pop	hl
	scf
	ret nz	;Not our command

	;--- Extract next char, throw "Syntax error" if it's not '('
	
	call	GETCHAR
	cp	"("
	ld	ix,SYNERR
	jp	nz,DO_CALBAS
	
	;--- Extract argument and check if it's a string, throw "Type mismatch" if not
	
	ld	ix,FRMEVL
	call	DO_CALBAS	;Will throw "Syntax error" if parameter is missing
	
	ld	a,(VALTYP)
	cp	3	;Is it a string?
	ld	ix,TYPEM
	jp	nz,DO_CALBAS

	;--- Print "You said..."
	
	ld	de,YOUSAID_S
	call PRINTZ

	;--- Get the string pointer to DE and the string length to B, it's a bit tricky:
	;    DAC+2 contains a pointer to a 3 byte area which in turn
	;    contains the string length (1 byte) and a pointer to the string (2 bytes).
	
	ex	de,hl
	
	ld	hl,DAC+2
	ld	a,(hl)
	inc	hl
	ld	h,(hl)
	ld	l,a	;HL=pinter to (length, string pointer)
	
	ld	b,(hl)
	inc	hl
	ld	a,(hl)
	inc	hl
	ld	h,(hl)
	ld	l,a	;B=length, HL=string pointer
	
	ex	de,hl	
	
	;--- Print the string passed as parameter
	
	call PRINTB
	
	;--- If there were more parameters, we would extract the ',' with GETCHAR,
	;    then we would extract the parameter with FRMEVL, and so on.
	;    Since there aren't, we just extract the final ')'.
	
	call	GETCHAR
	cp	")"
	ld	ix,SYNERR
	jp	nz,DO_CALBAS
	
	;--- The end, note that HL points to the BASIC program after our CALL statement
	
	or	a	;Cy must be 0
	ret


;=======================================================
;===  SUBROUTINES FOR BASIC CALL STATEMENTS HANDLER  ===
;=======================================================


    ;--- Extract the next character from the BASIC program

    ;Note that CHRGTR requires HL to point BEFORE the character to be extracted,
    ;but FRMEVL requires HL to point exactly to the expression to evaluate.
    ;That's why we 'dec hl' before and 'inc hl' after doing the call to CHRGTR.

GETCHAR:
	dec	hl
	ld	ix,CHRGTR
	call	DO_CALBAS
	inc	hl
	ret

	;--- Invoke routine in the BASIC interpreter, IX = routine address

DO_CALBAS:
	push ix
	ld ix,CALBAS
	ld (CODE_ADD),ix
	pop ix
	jp CALLB0

	;--- Compare zero terminated strings at HL and DE
	;    Returns Z if they are equal, NZ otherwise

COMP_STR:
	ld	a,(de)
	cp	(hl)
	ret nz
	inc	hl
	inc	de
	or	a
	jr	nz,COMP_STR
	ret

	;--- Print zero-terminated string pointed by DE

PRINTZ:
	ld a,(de)
	or a
	ret z
	call CHPUT
	inc de
	jr PRINTZ

	;--- Print string with length B pointed by DE

PRINTB:
	ld a,(de)
	call CHPUT
	inc de
	djnz PRINTB
	ret

SAY_S: db "SAY",0
YOUSAID_S: db "You said: ",0

;-----------------------------------------------------------------------------
;
; End of the driver code

DRV_END:

	;ds	3FD0h-(DRV_END-DRV_START)

	end
