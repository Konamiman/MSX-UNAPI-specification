;--- Sample implementation of a MSX-UNAPI specification in ROM
;    By Konamiman, 5-2019
;
;    This code implements a sample mathematical specification, "SIMPLE_MATH",
;    which has just two functions:
;       Function 1: Returns HL = L + E
;       Function 2: Returns HL = L * E
;
;    You can compile it with Nestor80 (https://github.com/Konamiman/Nestor80/releases):
;    N80 unapi-rom.asm math.rom
;
;    Search for "TODO" comments for what to change/extend when creating your own implementation.

;*******************
;***  CONSTANTS  ***
;*******************

; 0: Copy the old EXTBIO hook directly to the area for our slot in SLTWRK
;    (enough if we don't need space in page 3 for anything else).
;
; 1: Allocate 5 bytes in page 3, copy old EXTBIO hook there, set allocated address
;    in the area for our slot in SLTWRK.

ALLOC_P3: equ 0

;--- System variables and routines

CHPUT:  equ  00A2h
HOKVLD:  equ  0FB20h
EXPTBL:  equ  0FCC1h
EXTBIO:  equ  0FFCAh
SLTWRK:  equ  0FD09h
ARG:  equ  0F847h

;--- API version and implementation version

;TODO: Adjust for your implementation

API_V_P:  equ  1
API_V_S:  equ  0
ROM_V_P:  equ  1
ROM_V_S:  equ  0

;--- Maximum number of available standard and implementation-specific function numbers

;TODO: Adjust for your implementation

;Must be 0 to 127
MAX_FN:    equ  2

;Must be either zero (if no implementation-specific functions available), or 128 to 254
MAX_IMPFN:  equ  0


;********************************************
;***  ROM HEADER AND INITIALIZATION CODE  ***
;********************************************

  org  4000h

  ;--- ROM header

  db  "AB"
  dw  INIT
  ds  12

INIT:
  ;--- Initialize EXTBIO hook if necessary

  ld  a,(HOKVLD)
  bit  0,a
  jr  nz,OK_INIEXTB

  ld  hl,EXTBIO
  ld  de,EXTBIO+1
  ld  bc,5-1
  ld  (hl),0C9h  ;code for RET
  ldir

  or  1
  ld  (HOKVLD),a
OK_INIEXTB:

  ;--- Save previous EXTBIO hook

  if ALLOC_P3

  ld hl,5
  call ALLOC
  push hl
  call GETSLT
  call GETWRK
  pop de
  ld (hl),e
  inc hl
  ld (hl),d

  else

  call GETSLT
  call GETWRK
  ex  de,hl

  endif

  ld  hl,EXTBIO
  ld  bc,5
  ldir

  ;--- Patch EXTBIO hook

  di
  ld  a,0F7h  ;code for "RST 30h"
  ld  (EXTBIO),a
  call  GETSLT
  ld  (EXTBIO+1),a
  ld  hl,DO_EXTBIO
  ld  (EXTBIO+2),hl
  ld a,0C9h
  ld (EXTBIO+4),a
  ei

  ;>>> UNAPI initialization finished, now perform
  ;    other ROM initialization tasks.

ROM_INIT:

  ;TODO: extend (or replace) with other initialization code as needed by your implementation

  ;--- Show informative message

  ld  hl,INITMSG
PRINT_LOOP:
  ld  a,(hl)
  or  a
  jp  z,INIT2
  call  CHPUT
  inc  hl
  jr  PRINT_LOOP
INIT2:

  ret


;*******************************
;***  EXTBIO HOOK EXECUTION  ***
;*******************************

DO_EXTBIO:
  push  hl
  push  bc
  push  af
  ld  a,d
  cp  22h
  jr  nz,JUMP_OLD
  cp  e
  jr  nz,JUMP_OLD

  ;Check API ID

  ld  hl,UNAPI_ID
  ld  de,ARG
LOOP:  ld  a,(de)
  call  TOUPPER
  cp  (hl)
  jr  nz,JUMP_OLD2
  inc  hl
  inc  de
  or  a
  jr  nz,LOOP

  ;A=255: Jump to old hook

  pop  af
  push  af
  inc  a
  jr  z,JUMP_OLD2

  ;A=0: B=B+1 and jump to old hook

  call  GETSLT
  call  GETWRK

  if ALLOC_P3

  ld a,(hl)
  inc hl
  ld h,(hl)
  ld l,a

  endif

  pop  af
  pop  bc
  or  a
  jr  nz,DO_EXTBIO2
  inc  b
  ex  (sp),hl
  ld  de,2222h
  ret
DO_EXTBIO2:

  ;A=1: Return A=Slot, B=Segment, HL=UNAPI entry address

  dec  a
  jr  nz,DO_EXTBIO3
  pop  hl
  call  GETSLT
  ld  b,0FFh
  ld  hl,UNAPI_ENTRY
  ld  de,2222h
  ret

  ;A>1: A=A-1, and jump to old hook

DO_EXTBIO3:  ;A=A-1 already done
  ex  (sp),hl
  ld  de,2222h
  ret

  ;--- Jump here to execute old EXTBIO code

JUMP_OLD2:
  ld  de,2222h
JUMP_OLD:  ;Assumes "push hl,bc,af" done
  push  de
  call  GETSLT
  call  GETWRK

  if ALLOC_P3

  ld a,(hl)
  inc hl
  ld h,(hl)
  ld l,a

  endif

  pop  de
  pop  af
  pop  bc
  ex  (sp),hl
  ret
  

;************************************
;***  FUNCTIONS ENTRY POINT CODE  ***
;************************************

UNAPI_ENTRY:
  push  hl
  push  af
  ld  hl,FN_TABLE
  bit  7,a

  if MAX_IMPFN gte 128

  jr  z,IS_STANDARD
  ld  hl,IMPFN_TABLE
  and  01111111b
  cp  MAX_IMPFN-128
  jr  z,OK_FNUM
  jr  nc,UNDEFINED
IS_STANDARD:

  else

  jr  nz,UNDEFINED

  endif

  cp  MAX_FN
  jr  z,OK_FNUM
  jr  nc,UNDEFINED

OK_FNUM:
  add  a,a
  push  de
  ld  e,a
  ld  d,0
  add  hl,de
  pop  de

  ld  a,(hl)
  inc  hl
  ld  h,(hl)
  ld  l,a

  pop  af
  ex  (sp),hl
  ret

  ;--- Undefined function: return with registers unmodified

UNDEFINED:
  pop  af
  pop  hl
  ret


;***********************************
;***  FUNCTIONS ADDRESSES TABLE  ***
;***********************************

;TODO: Adjust for the routines of your implementation

;--- Standard routines addresses table

FN_TABLE:
FN_0:  dw  FN_INFO
FN_1:  dw  FN_ADD
FN_2:  dw  FN_MULT


;--- Implementation-specific routines addresses table

  if MAX_IMPFN gte 128

IMPFN_TABLE:
FN_128:  dw  FN_DUMMY

  endif


;************************
;***  FUNCTIONS CODE  ***
;************************

;--- Mandatory routine 0: return API information
;    Input:  A  = 0
;    Output: HL = Descriptive string for this implementation, on this slot, zero terminated
;            DE = API version supported, D.E
;            BC = This implementation version, B.C.
;            A  = 0 and Cy = 0

FN_INFO:
  ld  bc,256*ROM_V_P+ROM_V_S
  ld  de,256*API_V_P+API_V_S
  ld  hl,APIINFO
  xor  a
  ret

;TODO: Replace the FN_* routines below with the appropriate routines for your implementation

;--- Sample routine 1: adds two 8-bit numbers
;    Input: E, L = Numbers to add
;    Output: HL = Result

FN_ADD:
  ld  h,0
  ld  d,0
  add  hl,de
  ret


;--- Sample routine 2: multiplies two 8-bit numbers
;    Input: E, L = Numbers to multiply
;    Output: HL = Result

FN_MULT:
  ld  b,e
  ld  e,l
  ld  d,0
  ld  hl,0
MULT_LOOP:
  add  hl,de
  djnz  MULT_LOOP
  ret


;****************************
;***  AUXILIARY ROUTINES  ***
;****************************

;--- Get slot connected on page 1
;    Input:  -
;    Output: A = Slot number
;    Modifies: AF, HL, E, BC

GETSLT:
  di
  exx
  in  a,(0A8h)
  ld  e,a
  and  00001100b
  sra  a
  sra  a
  ld  c,a  ;C = Slot
  ld  b,0
  ld  hl,EXPTBL
  add  hl,bc
  bit  7,(hl)
  jr  z,NOEXP1
EXP1:  inc  hl
  inc  hl
  inc  hl
  inc  hl
  ld  a,(hl)
  and  00001100b
  or  c
  or  80h
  ld  c,a
NOEXP1:  ld  a,c
  exx
  ei
  ret


;--- Obtain slot work area (8 bytes) on SLTWRK
;    Input:  A  = Slot number
;    Output: HL = Work area address
;    Modifies: AF, BC

GETWRK:
  ld  b,a
  rrca
  rrca
  rrca
  and  01100000b
  ld  c,a  ;C = Slot * 32
  ld  a,b
  rlca
  and  00011000b  ;A = Subslot * 8
  or  c
  ld  c,a
  ld  b,0
  ld  hl,SLTWRK
  add  hl,bc
  ret


;--- Convert a character to upper-case if it is a lower-case letter

TOUPPER:
  cp  "a"
  ret  c
  cp  "z"+1
  ret  nc
  and  0DFh
  ret
  

;**************
;***  DATA  ***
;**************

;TODO: Adjust this data for your implementation

  ;--- Specification identifier (up to 15 chars)

UNAPI_ID:
  db  "SIMPLE_MATH",0

  ;--- Implementation identifier (up to 63 chars and zero terminated)

APIINFO:
  db  "Konamiman's ROM implementation of SIMPLE_MATH UNAPI",0

  ;--- Other data

INITMSG:
  db  13,10,"UNAPI Sample ROM 1.0 (SIMPLE_MATH)",13,10
  db  "(c) 2019 by Konamiman",13,10
  db  13,10
  db  0


  if ALLOC_P3

;
;-----------------------------------------------------------------------
;
;       ALLOC allocates specified amount of memory downward from current
;       HIMEM
;
;       Routine borrowed from MSX-DOS2/Nextor:
;       https://github.com/Konamiman/Nextor/blob/v2.1/source/kernel/bank0/alloc.mac
;
; Inputs:
;       HL = memory size to allocate
; Outputs:
;       if successful, carry flag reset, HL points to the beginning
;                      of allocated area
;       otherwise, carry flag set, allocation not done.
;
BOOTAD	equ	0C000h		;Where boot sector is executed
;
BOTTOM	equ	0FC48h		;Pointer to bottom of RAM
HIMEM	equ	0FC4Ah		;Top address of RAM which can be used
MEMSIZ	equ	0F672h		;Pointer to end of string space
STKTOP	equ	0F674h		;Pointer to bottom of stack
SAVSTK	equ	0F6B1h		;Pointer to valid stack bottom
MAXFIL	equ	0F85Fh		;Maximum file number
FILTAB	equ	0F860h		;Pointer to file pointer table
NULBUF	equ	0F862h		;Pointer to buffer #0
;
ALLOC:
	ld	a,l		;is requested size 0?
	or	h
	ret	z		;yes, allocation always succeeds
	ex	de,hl		;calculate -size
	ld	hl,0
	sbc	hl,de
	ld	c,l		;remember specified size
	ld	b,h
	add	hl,sp		;[HL] = [SP] - size
	ccf
	ret	c		;size too big
	ld	a,h
	cp	high (BOOTAD+512)
	ret	c		;no room left

	ld	de,(BOTTOM)	;get current RAM bottom
	sbc	hl,de		;get memory space left after allocation
	ret	c		;no space left
	ld	a,h		;do we still have breathing room?
	cp	high 512
	ret	c		;no, not enough space left
;
;       Now, requested size is legal, begin allocation
;
	push	bc		;save -size
	ld	hl,0
	add	hl,sp		;get current stack pointer to [HL]
	ld	e,l		;move source address to [DE]
	ld	d,h
	add	hl,bc
	push	hl		;save destination
	ld	hl,(STKTOP)
	or	a
	sbc	hl,de
	ld	c,l		;move byte count to move to [BC]
	ld	b,h
	inc	bc
	pop	hl		;restore destination
	ld	sp,hl		;destination becomes the new SP
	ex	de,hl
	ldir			;move stack contents
	pop	bc		;restore -size
	ld	hl,(HIMEM)
	add	hl,bc
	ld	(HIMEM),hl
	ld	de,-2*(2+9+256)
	add	hl,de
	ld	(FILTAB),hl	;pointer to first FCB
	ex	de,hl
	ld	hl,(MEMSIZ)	;update MEMSIZ
	add	hl,bc
	ld	(MEMSIZ),hl
	ld	hl,(NULBUF)	;update NULBUF
	add	hl,bc
	ld	(NULBUF),hl
	ld	hl,(STKTOP)	;update STKTOP
	add	hl,bc

  if 0 ;Apparently this part of the original code is not needed for our use case

	jr	CLRFCB

;
;       Re-build BASIC's file structures
;
DEFILE:
	ld	a,1		;load default MAXFIL
	ld	(MAXFIL),a
	ld	hl,(HIMEM)
	ld	de,-2*(256+9+2)
	add	hl,de
	ld	(FILTAB),hl	;pointer to first FCB
	ld	e,l
	ld	d,h
	dec	hl
	dec	hl
	ld	(MEMSIZ),hl
	ld	bc,200		;load default string space
	or	a
	sbc	hl,bc
	push	hl		;save new STKTOP
	ld	hl,2*2+9	;4 for two FCB pointers, 9 for flags
	add	hl,de
	ld	(NULBUF),hl
	pop	hl
CLRFCB:

  endif

	ld	(STKTOP),hl
	dec	hl		;and SAVSTK
	dec	hl
	ld	(SAVSTK),hl
	ld	l,e		;get FILTAB in [HL]
	ld	h,d
	inc	hl		;point to first FCB
	inc	hl
	inc	hl
	inc	hl
	ld	a,2
DSKFLL:
	ex	de,hl
	ld	(hl),e		;set address in FILTAB
	inc	hl
	ld	(hl),d
	inc	hl
	ex	de,hl
	ld	bc,7
	ld	(hl),b		;make it look closed
	add	hl,bc
	ld	(hl),b		;clear flag byte
	ld	bc,9+256-7
	add	hl,bc		;point to next FCB
	dec	a
	jr	nz,DSKFLL
	ret

  endif

  ds  0C000h-$  ;Padding to make a 32K ROM
