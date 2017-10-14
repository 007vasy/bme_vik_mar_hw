
; Vass Bence - IID12X

;-----------------
; Feladatkiírás:
;-----------------

;***************************************************************
; A belső memóriában található 32 bites bitsorozatba adott számú 
; (max. 8) bit beszúrása/kivétele tetszőleges helyre/helyről. 
; A beszúrás feletti rész felfelé csúszik (a teteje kilép), 
; kivételkor lefelé csúszik és felül 0-k lépnek be.
; Bemenet: a bitsorozat címe (1 regiszterben),
; a beszúrandó/kiveendő bitek száma (1 regiszterben),
; a beszúrandó/kivett bitek (1 regiszterben),
; a beszúrás/kivétel helye (legkisebb érintett bit száma 0..31),
; az elvégzendő művelet kódja (1 regiszterben).
; Kimenet: a módosított bitsorozat, kivett bitek (regiszterben).
;***************************************************************

;**********************************************************
; - INPUT:  R0= 32 BITES BITSOROZAT KEZDOCIME (R0)=MSB
;           R1=BITCIM (HANYADIK BITTOL SZURJUNK BE)
;           R2=BITSZAM (HANY BITET SZURJUNK BE)
;           R3=BESZURANDO MINTA/KIVETT MINTA
;           R4=ELVEGZENDO MUVELET 0x0F -> BESZURAS , 0x00 -> KIVETEL
; - OUTPUT: R4-R5-R6-R7 = BITSOROZAT BOVITVE
; - VÁLTOZIK: A, PSW, R4-R5-R6-R7
;**********************************************************

	ORG	0x00
	SJMP	MAIN		;UGRÓTÁBLA RESET UTASÍTÁS

;**********************************************************

MAIN:	


	MOV	0x30,#0x11	;BITMEZO FELTOLTESE
	MOV	0x31,#0x22
	MOV	0x32,#0x33
	MOV	0x33,#0x44

	MOV	R0,#0x30	;BITMEZO KEZDOCIME
	MOV	R1,#9		;MUVELETVEGZES KEZDOCIME A BITMEZON BELUL
	MOV	R2,#4		;BITEK SZÁMA
	MOV	R3,#0xF5   ;BESZURANDO MINTA
	MOV R4,#0x00   ;ELVEGZENDO MUVELET 0x00 -> KIVETEL
	
	ACALL BIT_PUSH_POP

	MOV	R0,#0x30	;BITMEZO KEZDOCIME
	MOV	R1,#9		;MUVELETVEGZES KEZDOCIME A BITMEZON BELUL
	MOV	R2,#4		;BITEK SZÁMA
	MOV	R3,#0x00	;kivett bitek
	MOV R4,#0x0F   ;ELVEGZENDO MUVELET 0x0F -> BESZURAS

	ACALL BIT_PUSH_POP
LOOP:	SJMP	LOOP

;**********************************************************
; BITEK BESZURASA BITMEZOBE
; - INPUT:  R0=BITMEZO MSB KEZDOCIME
;           R1=BITCIM (HANYADIK BITTOL SZURJUNK BE)
;           R2=BITSZAM (HANY BITET SZURJUNK BE/VEGYUNK KI = 1..8)
;           R3=BITMINTA (1..8)
; - OUTPUT: R4-R5-R6-R7 = BITSOROZAT BOVITVE
; - VÁLTOZIK: A, PSW, R3, R4-R5-R6-R7
;**********************************************************
BIT_PUSH_POP:	
	
	CJNE R4,#0x00,CUT
	PUSH AR4
	MOV	A,@R0	;BITMEZO 3.BAJT (MSB)
	MOV	R4,A	;R4-BE
	INC	R0
	MOV	A,@R0	;BITMEZO 2.BAJT 
	MOV	R5,A	;R5-BE
	INC	R0
	MOV	A,@R0	;BITMEZO 1.BAJT
	MOV	R6,A	;R6-BA
	INC	R0
	MOV	A,@R0	;BITMEZO 0.BAJT (LSB)
	MOV	R7,A	;R7-BE
	PUSH	AR1	;REGISZTEREK MENTESE
	PUSH	AR2

	

	
;**********************************************************
;BESZURAS
;**********************************************************

INS0:	MOV	A,R3	;A=MINTA
	RRC	A	;CY=BESZURANDO MINTA LSB
	MOV	R3,A
	MOV	F0,C	;F0=BESZURANDO MINTA LSB
	ACALL	BITBE	;1 BIT BESZURASA
	INC	R1	;KOVETKEZO CIM
	CJNE	R1,#32,INS1
	SJMP	MEM_UPDATE
INS1:	
	DJNZ	R2,INS0

MEM_UPDATE:	
	POP	AR2	;REGISZTEREK VISSZAALLITASA
	POP	AR1
	MOV	A,R7	;BITMEZO 0.BAJT (LSB)
	MOV	@R0,A	;TAROLASA
	DEC	R0
	MOV	A,R6	;BITMEZO 1.BAJT
	MOV	@R0,A	;TAROLASA
	DEC	R0
	MOV	A,R5	;BITMEZO 2.BAJT
	MOV	@R0,A	;TAROLASA
	DEC	R0
	MOV	A,R4	;BITMEZO 3.BAJT (MSB)
	MOV	@R0,A	;TAROLASA

	POP AR4

	RET

;**********************************************************
; 1 BIT BESZURASA R4-R5-R6-R7-BE
; - INPUT:  R4-R5-R6-R7 = BITSOROZAT (R4.7=MSB)
;           R1=BITCIM, F0=BESZURANDO BIT
; - OUTPUT: R4-R5-R6-R7 = BITSOROZAT BOVITVE
; - VÁLTOZIK: A, PSW, R4-R5-R6-R7
;**********************************************************

BITBE:	PUSH	AR1	;BITCIM MENTESE
	MOV	A,R1	;BESZURAS HELYE (BITCIM)
	CLR	C
	SUBB	A,#8
	JC	BITBE2	;UGRAS, HA A 0.BAJTBA (LSB)
	MOV	R1,A	;BITCIM-8
	SUBB	A,#8
	JC	BITBE1	;UGRAS, HA AZ 1.BAJTBA
	MOV	R1,A	;BITCIM-16
	SUBB	A,#8
	JC	BITBE0	;UGRAS, HA A 2.BAJTBA
	MOV	R1,A	;BITCIM-24

	;*** BESZURAS A 3. BAJTBA (MSB) ***

	MOV	A,R4
	ACALL	ABESZ	;BESZURAS R4-BE
	SJMP	BITBE6	;KESZ

	;*** BESZURAS A 2. BAJTBA ***

BITBE0:	MOV	A,R5
	ACALL	ABESZ	;BESZURAS R5-BE
	SJMP	BITBE5	;R4 LEPTETESE

	;*** BESZURAS AZ 1. BAJTBA ***

BITBE1:	MOV	A,R6
	ACALL	ABESZ	;BESZURAS R6-BA
	SJMP	BITBE4	;R4-R5 LEPTETESE
	;*** BESZURAS A 0.BAJTBA (LSB) ***

BITBE2:	MOV	A,R7
	ACALL	ABESZ	;BESZURAS R7-BE
	MOV	R7,A
	MOV	A,R6	;R6 LEPTETESE (LSB=CY)
	RLC	A
BITBE4:	MOV	R6,A
	MOV	A,R5	;R5 LEPTETESE (LSB=CY)
	RLC	A
BITBE5:	MOV	R5,A
	MOV	A,R4	;R4 LEPTETESE (LSB=CY)
	RLC	A
BITBE6:	MOV	R4,A
	POP	AR1	;BITCIM HELYREALLITASA
	RET
;**********************************************************
; 1 BIT BESZURASA A-BA (EZEN EGY KICSIT GONDOLKOZNI KELL)
; - INPUT:  A = BITSOROZAT
;           R1=BITCIM (0..7), F0=BESZURANDO BIT
; - OUTPUT: A = BITSOROZAT BOVITVE
;           CY= A MSB-JE
; - VÁLTOZIK: A, PSW; R1
;**********************************************************

ABESZ:	XCH	A,R1	;A=BITCIM
	JZ	ABESZ1	;UGRAS, HA 0.BIT
	XCH	A,R1	;EREDETI A ES R1
	PUSH	AR1	;BITCIM MENTESE
ABESZ0:	RR	A	;BITCIMSZER JOBBRA (CY NELKUL)
	DJNZ	R1,ABESZ0
	POP	AR1	;R1=BITCIM
	XCH	A,R1	;GYORSABB, MINT EGY SJMP
ABESZ1:	XCH	A,R1	;A=BITSOROZAT, R1=BITCIM
	INC	R1	;R1=BITCIM+1
	MOV	C,F0	;CY=F0 (BESZURANDO BIT)
ABESZ2:	RLC	A	;BITCIMSZER BALRA (CY-VEL)
	DJNZ	R1,ABESZ2
	RET

;**********************************************************
; BITEK KIVETELE BITMEZOBOL
; - INPUT:  R0=BITMEZO MSB KEZDOCIME
;           R1=BITCIM (HANYADIK BITTOL SZURJUNK BE)
;           R2=BITSZAM (HANY BITET SZURJUNK BE/VEGYUNK KI = 1..8)
;           
; - OUTPUT: R3 = KIVETT BITEK
; - VÁLTOZIK: A, PSW, R3, R5-R6-R7
;**********************************************************

;**********************************************************
;R0-TOL VALO BYTE ES BIT TAVOLSAG SZAMITASA
;**********************************************************
CUT:
	PUSH AR4
	MOV R5,#0x00 ;R0 eltolása
	MOV A,#32
	SUBB A,R1 ;eltolás számítása
	CLR C

;**********************************************************
;CIKLUS A TAVOLGAS FELMERESERE
;R5= R0-TOL VALO MUNKABYTE TAVOLSAGA
;**********************************************************
LOOP_CUT:
	MOV R1,A
	SUBB A,#8
	JC CUT_1bit
	INC R5  ;könnyebb ciklust szervezni, ha így van növelve
	CJNE R5,#0x03,LOOP_CUT

;**********************************************************
;A KIVETEL FELADAT VISSZA VAN VEZETVE 1 BIT KIVETELERE
;**********************************************************

CUT_1bit:

;**********************************************************
;R6= A MUNKABYTE-BAN LEVO MUNKABIT TAVOLSAGA AZ LSB-TOL
;**********************************************************

	CLR C
	MOV F0,C
	MOV A,#7
	SUBB A,R1
	MOV R6,A ;MSB-LSB helyes eltolás

;**********************************************************
;A BAZISCIM MENTESE A BITEK KOPERGETESEHEZ HASZNALT CIKLUS
;UJBOLI LEFUTTATASAHOZ
;**********************************************************
PUSH AR2

;**********************************************************
;A CIKLUS R2-SZER KIVESZ 1 bitet az (R2+R5).R6 HELYROL 
;FELULROL (MSB) BECSUSZO NULLAKKAL KIEGESZÍTVE
;**********************************************************
LOOP_CUT_big:
PUSH AR0 ;BAZIS CIM MENTESE, VALTOZIK A CIKLUS KOZBEN
PUSH AR5 ;MUNKABYTE TAVOLGAS MENTESE, VALTOZIK A CIKLUS KOZBEN

;**********************************************************
;A MUNKABYTE ES A AZ FELETITTI BYTE-OK LEJJEB CSUSZTATASA
;1 BIT-TEL
;**********************************************************
LOOP_CUT_byte:
	
	MOV C,F0
	DEC R5;
	MOV A,@R0
	RRC A
	MOV @R0,A
	INC R0
	MOV F0,C
	CJNE R5,#0xFF,LOOP_CUT_byte
	DEC R0 ;KOMPENZALAS AZ UJBOLI LEFUTAS MIATT
	;MOV C,F0 ;CJNE MODOSÍTJA A C-T
	MOV C,F0
	RLC A ;KOMPENZALAS AZ UJBOLI LEFUTAS MIATT



PUSH AR6;ELTOLAS TAROLASA A VISSZAFORGATASOKHOZ


INC R6 ; 0-la kezelése

;**********************************************************
;1 BIT KIFORGATASA A MUNKABYTE-BOL
; A FELUROL BECSUSZO 0
;**********************************************************

LOOP_CUT_1bit_out:
	
	RRC A
	DJNZ R6,LOOP_CUT_1bit_out

POP AR6
PUSH AR6


;**********************************************************
;BIT KIVETELE UTANI VISSZAALLITAS
;**********************************************************
MOV F0,C
CJNE R6,#0x00,LOOP_CUT_1bit_restore

R6_0:;0 VISSZAFORGATAS KEZELESE

POP AR6 ;VISSZAALLITAS UJABB CIKLUSHOZ

;KIVETT BIT TAROLASA
;TODO forgatás helyesség
MOV @R0,A
MOV A,R3
MOV C,F0
RRC A
MOV R3,A

CLR C

MOV F0,C

POP AR5 
POP AR0 ;BAZIS CIM MENTESE

DJNZ R2,LOOP_CUT_big ;R2 ADJA MEG A KIVEENDO BITEK SZAMAT
POP AR2

CLR C


;**********************************************************
;KIVETT BITEK FORGATASA AZ LSB HELYES TAROLASHOZ
;**********************************************************
MOV A,#8
SUBB A,R2
JZ END_CUT

MOV R2,A
MOV A,R3

;**********************************************************
;LSB HELYESSEG ELOALLITASA
;**********************************************************
LOOP_RESULT:
RR A
DJNZ R2,LOOP_RESULT

MOV R3,A
END_CUT:;0 VISSZAFORGATAS KEZELESE
POP AR4

RET

;**********************************************************
;VISSZAALLITO CIKLUS
;**********************************************************
LOOP_CUT_1bit_restore:

	DEC R6
	RL A
	CJNE R6,#0x00,LOOP_CUT_1bit_restore
JMP R6_0