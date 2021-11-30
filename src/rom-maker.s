.macpack apple2

COUT = $fded
CtrlD = $04
CR   = $0D
SavedProgStart = $35FC
SavedProgEnd = $35FE
PRGEND = $AF
TEXTTAB = $67
GETLN1 = $fd6f
INBUF = $200
INBUF_Cpy = $4200
INBUF_OrigSave = $4300
DOS_Munge = $AA59

        .org $4000

.macro printLine_   addr
        lda #<addr
        sta $06
        lda #>addr
        sta $07
        jsr printLine
.endmacro

Start:
    ; save x and y, and DOS's stack marker that it will later try to
    ; fuck up.
        txa
        pha
        tya
        pha
        lda DOS_Munge
        sta DOS_Munge_save

        ; save away input buffer (because DOS is still executing it)
        ldy #>INBUF
        lda #>INBUF_OrigSave
        jsr copyInBuf

        ; output an initial CR
        lda #$8D
        jsr COUT

        ; BLOAD ASOFT LOADER at $3600
        printLine_ (BLOAD_str+1)    ; once without Ctrl-D to echo to screen
        printLine_ BLOAD_str

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
        ; overwrite when we BSAVE next
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

        ; Copy saved input buffer back, so DOS can continue doing
        ; whatever it had been doing
        ldy #>INBUF_OrigSave
        lda #>INBUF
        jsr copyInBuf

        ; restore x and y
        pla
        tay
        pla
        tax
        lda DOS_Munge_save
        sta DOS_Munge

        rts

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
    scrcode $04, "BLOAD ASOFT LOADER,A$3600", $0D
    .byte $00
PROMPT_str:
    scrcode "ROM FILE NAME? "
    .byte $00
BSAVE_str_pre:
    scrcode $04, "BSAVE "
    .byte $00
BSAVE_str_post:
    scrcode ",A$800,L$3000", $0D
    .byte $00
DOS_Munge_save:
    .byte $00
