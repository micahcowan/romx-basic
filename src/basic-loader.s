.macpack apple2

        KYBD = $C000
        KYBD_STROBE = $C010
        RAM_LOC = $4500
        RMXStrt = $DFD8 ; per API docs = $DFD9, but ex. code has DFD8?
        RMXInit = $1012
        RMXDoMenu = $103C
        ASOFTStart = $C100
        ASOFT_RAMStart = $800
        RealBank = $2A6
        BANK0 = $CFE0
        SavedFirstTwo = $45FA
        SavedProgStart = $45FC
        SavedProgEnd = $45FE
        KSWL = $38
        KSWH = $39
        ASOFT_COLDSTART = $f128
        KEYIN = $fd1b
        PRGEND = $AF
        TEXTTAB = $67
        Mon_SETKBD = $FE89
        Mon_SETVID = $FE93
        Mon_INIT = $FB2F
        Mon_SETNORM = $FE84
        RAM_Offset = (Launch - RAM_LOC)
        ChrIdx = $1D
        ChrVal = $1E

.macro inc16 addr
        inc addr
        bne :+
        inc addr+1
:
.endmacro

; NOTE: all these macros assume Y = 0
.macro incThenReadA src
        inc16 src
        lda (src), y
.endmacro

.macro incThenRead src, dest
        incThenReadA src
        sta dest
.endmacro

.macro incThenRead16 src, dest
        incThenRead src, dest
        incThenRead src, {dest+1}
.endmacro

.macro SelBank0
        bit $C0E0    ;ZipSlow
        bit $CACA
        bit $CACA
        bit $CAFE
.endmacro

        .org $FE00

Launch:
        cld
        jsr ClearScreen
        jmp DisplayError
ClearScreen:
        lda #$A0        ; load space character
        ldx #$04        ;   write to $400 (text display)
        ldy #$00
        sty $00         ; save our dest addr to $00-$01
@np:        stx $01
            ldy #$F8    ; omit screenholes (actually unneeded, but good habit)
@lo:            dey
                sta ($00),y
            bne @lo
            inx
            cpx #$08
        bne @np
        rts
DisplayError:
        lda #<(LaunchErrorMsg-1)
        sta $02
        lda #>(LaunchErrorMsg-1)
        sta $03
        ldy #$00
@prOneL:    incThenRead16 $02, $00
            beq AwaitKeypress   ; zero in high byte of zero? done writing.
@readAndPr:     incThenReadA $02
                beq @prOneL     ; On NUL, this line is done; read next
                sta ($00), y
                inc16 $00
            bne @readAndPr  ; always
AwaitKeypress:
        lda KYBD
        bpl AwaitKeypress
        lda KYBD_STROBE
        ; TODO: copy jump-to-bank0-menu routine to RAM, then execute it
        jsr RamCpy
        jmp Bk2Menu - RAM_Offset

LaunchErrorMsg:
.include "launch-error-msg.inc"

RamCpy:
        ldy #0
@lp:    lda Launch, y
        sta RAM_LOC, y
        iny
        bne @lp
        rts
Bk2Menu:
        SelBank0
        jsr RMXStrt
        jsr RMXInit
        jmp RMXDoMenu

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ASOFTLoad:
        cld
        jsr ClearScreen
        ; initialize our debug marker
        ldy #$00
        lda #$C1    ; 'A'
        sty ChrIdx
        sta ChrVal
        jsr PrintMark

ASOFTCopy:
        ; Then, load the stored BASIC program into RAM
        ldx #>ASOFTStart
        lda #>ASOFT_RAMStart
        ldy #0
        stx $3
        sta $1
        sty $2
        sty $0
CpOnePg:        lda ($2), y     ; copy one page
                sta ($0), y
                iny
            bne CpOnePg
            inc $1              ; then move onto next page
            inc $3
        bne CpOnePg             ; ...until we've reached this page
        jsr PrintMark

        ; Then switch the ROM bank to the final one (containing AppleSoft
        ;   and Monitor). (We won't check for language card ROM
        ;   - we want AppleSoft!)
        jmp RAMCont - RAM_Offset  ; continue execution in RAM
RAMCont:SelBank0
        ldx RealBank
        lda BANK0, x
        jsr PrintMark - RAM_Offset

        ; Run the Monitor/AppleSoft initialization code
        jsr Mon_SETNORM
        jsr Mon_INIT
        jsr Mon_SETVID
        jsr Mon_SETKBD
        jsr PrintMark - RAM_Offset

        ; We save away the first two bytes of our program after the
        ; required 00 byte - AppleSoft's cold-start will erase them,
        ; so we need to restore them again afterward
        ldx $801
        ldy $802
        stx SavedFirstTwo
        sty SavedFirstTwo+1
        jsr PrintMark - RAM_Offset

        ; Set up program initialization code to run after AppleSoft's
        ; cold-start has completed, the first time it prompts for input.
        ldx #<(ASOFT_ProgSetup - RAM_Offset)
        ldy #>(ASOFT_ProgSetup - RAM_Offset)
        stx KSWL
        sty KSWH
        jsr PrintMark - RAM_Offset

        jmp ASOFT_COLDSTART

ASOFT_ProgSetup:
        ; The first time input is checked, we restore our saved
        ; AppleSoft program, then hand control to our "input" routine.
        lda SavedFirstTwo
        sta $801
        lda SavedFirstTwo+1
        sta $802
        lda SavedProgStart
        sta TEXTTAB
        lda SavedProgStart+1
        sta TEXTTAB+1
        lda SavedProgEnd
        sta PRGEND
        lda SavedProgEnd+1
        sta PRGEND+1

        ; After we've finished init, we successively feed characters
        ; from the string "RUN"
.macro setksw label
        lda #<label
        sta KSWL
        lda #>label
        sta KSWH
.endmacro
SayR:   setksw (SayU - RAM_Offset)
        lda #$D2    ; R
        rts
SayU:   setksw (SayN - RAM_Offset)
        lda #$D5    ; U
        rts
SayN:   setksw (SayCR - RAM_Offset)
        lda #$CE    ; N
        rts
        ; Finally, restore normal user input and return final <CR>
SayCR:  setksw KEYIN
        lda #$8D    ; <CR>
        rts

PrintMark:
        ; Print a letter to indicate how far into our code we've run
        ; so we have some idea where things screwed up, if they do
        ldy ChrIdx
        lda ChrVal
        sta $500,y
        inc ChrIdx
        inc ChrVal
        rts

        ; Fill to end of ROM
        .res $FFFC-*

        .org $FFFC

RESTART:.word Launch
BREAK:  .word ASOFTLoad
