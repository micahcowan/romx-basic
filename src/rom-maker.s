.macpack apple2

COUT = $fded
CtrlD = $04
CR   = $0D
LOADER_ROM_Start = $FE00
LOADER_RAM_Start = (LOADER_ROM_Start - ($C100 - $800))
MAX_ProgEnd = (LOADER_RAM_Start - 6)
SavedProgStart = (LOADER_RAM_Start - 4)
SavedProgEnd = (LOADER_RAM_Start - 2)
PRGEND = $AF
TEXTTAB = $67
GETLN1 = $fd6f
INBUF = $200
PRBYTE = $FDDA

        .org $6000

.macro printLine_   addr
        lda #<addr
        sta $06
        lda #>addr
        sta $07
        jsr printLine
.endmacro

Start:
        ; output an initial CR
        lda #$8D
        jsr COUT

        ; BLOAD ASOFT LOADER at $4600
        printLine_ (BLOAD_str+1)    ; once without Ctrl-D to echo to screen
        printLine_ BLOAD_str

        ; Check if the BASIC program is too large
        ;   Subtract low bytes first to get carry/borrow
        sec
        lda #<MAX_ProgEnd
        sbc PRGEND
        ;   then subtract the high bytes to get the real answer
        lda #>MAX_ProgEnd
        sbc PRGEND+1
        bcs HaveSpace

        ; We don't have enough space for the BASIC program!
        printLine_ InsufficientSpace_str
        ; print prog end
        lda PRGEND+1
        jsr PRBYTE
        lda PRGEND
        jsr PRBYTE
        lda #$8D
        jsr COUT

        jmp Exit

HaveSpace:
        ; Save program start/end info
        lda TEXTTAB
        ldy TEXTTAB+1
        sta SavedProgStart
        sty SavedProgStart+1
        lda PRGEND
        ldy PRGEND+1
        sta SavedProgEnd
        sty SavedProgEnd+1

        ; Prompt for rom filename
        printLine_ PROMPT_str
        jsr GETLN1
        lda #00
        sta INBUF, x        ; CR-terminated -> NUL-terminated

        ; Copy input buffer, because Ctrl-D DOS processing will
        ; overwrite when we send BSAVE next
        ldy #>INBUF
        lda #>INBUF_Cpy
        jsr copyInBuf

        ; BSAVE rom file (echoing first)
        printLine_ (BSAVE_str_pre+1)    ; echo
        printLine_ INBUF_Cpy
        printLine_ BSAVE_str_post
        printLine_ BSAVE_str_pre        ; execute
        printLine_ INBUF_Cpy
        printLine_ BSAVE_str_post

        ; Exit by jumping directly to DOS warm start ($3D0).
        ; set the stack to something high, first.
Exit:
        ldx #$fb
        txs

        jmp $3D0

copyInBuf:
        sty $9
        sta $7
        ldy #$00
        sty $6
        sty $8
:           lda ($8),y
            sta ($6),y
            iny
        bne :-
        rts

printLine:
        ldy #$00
        sec
:           lda ($06), y
            beq :+          ; end if NUL
            jsr COUT        ; output one char
            iny
        bcs :-
:       rts

BLOAD_str:
        scrcode $04, "BLOAD ASOFT.LOADER,A"
        scrcode .sprintf("$%X", LOADER_RAM_Start), $0D
        .byte $00
PROMPT_str:
        scrcode "ROM FILE NAME? "
        .byte $00
BSAVE_str_pre:
        scrcode $04, "BSAVE "
        .byte $00
BSAVE_str_post:
        scrcode ",A$700,L$4000", $0D
        .byte $00
InsufficientSpace_str:
        scrcode "NOT ENOUGH SPACE IN ROM IMAGE", $0D
        scrcode "FOR THE CURRENT APPLESOFT PROGRAM!", $0D
        scrcode "YOUR PROGRAM MUST END AT "
        scrcode .sprintf("$%X", MAX_ProgEnd), $0D
        scrcode "BUT IT ENDS AT $"
        .byte $00

.out ""
.out .sprintf ("MAKE ASOFT ROM ends at $%X", *)
        .org (.hibyte(*) + 1) * $100

INBUF_Cpy:  ; where ROM filename gets saved after prompt

.out .sprintf ("INBUF_Cpy        is at $%X", *)
.out ""
