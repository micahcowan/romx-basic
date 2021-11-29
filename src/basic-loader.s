.macpack apple2

        KYBD = $C000
        KYBD_STROBE = $C010

;.macro inc16 addr
;.scope
;        inc addr
;        bne skip
;        inc addr+1
;    skip:
;.endscope
;.endmacro

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

        .org $8000

Launch:
        cld
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
        ;rts
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
        rts

LaunchErrorMsg:
.include "launch-error-msg.inc"
