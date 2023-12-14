\ recv - recv files

\ This file is licensed under the terms of the 2-clause BSD license. Please
\ see the COPYING file in the root project directory for the full text.

\   C version: 2051 bytes
\ asm version: 1024 bytes (w/ flags)

.include "cpm65.inc"
.include "drivers.inc"


.bss buffer, 128
.bss offset, 1
.bss blkcnt, 1
.bss blkwaiter, 1
.bss checksum, 1


.zp ptr1, 2 \ clobbered by print
.zp ptr2, 2 \ idem

.zp tmp, 4
.zp ret, 1
count=ret
endcondx=tmp+3

.zp drvaux, 2 


SOH = 1         \     H001          Start Of Header
EOT = 4         \     H004          End Of Transmission
ACK = 6         \     H006          Acknowledge (positive)
DLE = 16        \     H010          Data Link Escape
XON =  17       \     H011          Transmit On
XOFF = 19       \     H013          Transmit Off
NAK =   21      \     H015          Negative Acknowledge
SYN =   22      \     H016          Synchronous idle
CAN =   24      \     H018          Cancel5



start:
.expand 1


    ldy #BDOS_GET_BIOS
    jsr BDOS
    sta BIOS+1
    stx BIOS+2

    lda #<DRVID_AUX
	ldx #>DRVID_AUX
    ldy #BIOS_FINDDRV
    jsr BIOS
    sta drvaux+0
    stx drvaux+1
  

    

    bcc found_aux 
    .label aux_not_found
    lda #<aux_not_found
    ldx #>aux_not_found
    jmp print_string    \ exits

found_aux:
    .label aux_found
    lda #<aux_found
    ldx #>aux_found
    jsr print_string    

    lda drvaux+1
    jsr print_hex_number
    lda drvaux+0
    jsr print_hex_number

    lda #'\r'
    jsr putchar    
    lda #'\n'
    jsr putchar  

    lda cpm_fcb+1
    cmp #' '
    .label filename_not_given
    .zif eq
        \ No parameter given.
        lda #<filename_not_given
        ldx #>filename_not_given
        jmp print_string    \ exits

    .zendif
    jsr create_file_from_fcb
    .label cant_open_file
    .zif cs
        lda #<cant_open_file
        ldx #>cant_open_file
        jmp print_string    \ exits
    .zendif
    
    .label start_transmission
    lda #<start_transmission
    ldx #>start_transmission
    jsr print_string    

    jsr aux_open


mainloop: 


    jsr receive_file
   \ bcs mainloop    
    lda #<cpm_fcb
    ldx #>cpm_fcb
    ldy #BDOS_CLOSE_FILE
    jsr BDOS


    .label done_transmission
    lda #<done_transmission
    ldx #>done_transmission
    jmp print_string     \ exit


receive_file:
    lda #200   
    sta blkwaiter
    lda #0
    sta blkcnt

getblock:      
    lda #NAK        \ start transmission
getblock2:    
    jsr putaux
    lda #0
    sta offset
    jsr getblockchar
    bcs no_char
    cmp #SOH
    beq got_header 
    cmp #EOT
    beq end_of_tranmission
    cmp #CAN
    beq abort_transmission
no_char:
    dec blkwaiter
    lda #'.'
    jsr putchar
    lda blkwaiter
    beq abort_transmission
    jmp getblock    

end_of_tranmission:
    lda #ACK
    jsr putaux

    jsr aux_close
    .label transmission_done
    lda #<transmission_done
    ldx #>transmission_done
    jsr print_string  
    clc
    rts

abort_transmission:
    jsr aux_close
    .label transmission_stopped
    lda #<transmission_stopped
    ldx #>transmission_stopped
    jsr print_string   
    sec
    rts


got_header:
    lda #$00
    sta checksum
    jsr getblockchar
    sta blkcnt

got_blkcnt:
    jsr getblockchar    
    eor #$ff
    cmp blkcnt
    beq got_invblkcnt    
    jmp getblock     \ retry transmission

got_invblkcnt:
    jsr getblockchar    
    ldy offset
    sta buffer,y
    clc
    adc checksum
    sta checksum
    iny
    sty offset
    cpy #$80
    bne got_invblkcnt

got_block:
    jsr getblockchar    
    cmp checksum
    bne getblock    \ retransmit block
    jsr write_buffer
    lda #ACK        \ confirm block 
    jmp getblock2


chrwait: .byte 0,0

getblockchar:       
    lda #0
    sta chrwait
    sta chrwait+1
getblockchar2:    
    jsr getaux
    .zif cs
       inc chrwait
       lda chrwait
       bne getblockchar2                   
       inc chrwait+1
       lda chrwait+1
       cmp #$09
       bne getblockchar2                   
       lda #0
       sec 
       rts
    .zendif    
   
 
    \jsr print_hex_number
    \ Abort : 18181818080808
    \ get#98,a$:a=asc(a$+chr$(0)):ifa<>1anda<>4anda<>24then540

    rts

write_buffer:

    ldy #BDOS_SET_DMA
    lda #<buffer
    ldx #>buffer
    jsr BDOS

    ldy #BDOS_WRITE_SEQUENTIAL
    lda #<cpm_fcb
    ldx #>cpm_fcb
    jmp BDOS



create_file_from_fcb:
    
    .label writing_to
    lda #<writing_to
    ldx #>writing_to
    jsr print_string    

    jsr print_fcb

    lda #0
    sta cpm_fcb+0x20

    lda #<cpm_fcb
    ldx #>cpm_fcb
    ldy #BDOS_MAKE_FILE
    jsr BDOS
      
    rts

aux_open:
    ldy #AUX_OPEN
    jmp (drvaux)

aux_close:
    ldy #AUX_CLOSE
    jmp (drvaux)

getaux:
    ldy #AUX_IN
    jmp (drvaux)

putaux:
    ldy #AUX_OUT
    jmp (drvaux)

\ Prints the name of the file in cpm_fcb.

print_fcb:
    \ Drive letter.

    lda cpm_fcb+0
    .zif ne
        clc
        adc #'@'
        jsr putchar

        lda #':'
        jsr putchar
    .zendif

    \ Main filename.

    ldy #FCB_F1
    .zrepeat
        tya
        pha

        lda cpm_fcb, y
        and #0x7f
        cmp #' '
        .zif ne
            jsr putchar
        .zendif

        pla
        tay
        iny
        cpy #FCB_T1
    .zuntil eq

    lda cpm_fcb+9
    and #0x7f
    cmp #' '
    .zif ne
        lda #'.'
        jsr putchar

        ldy #FCB_T1
        .zrepeat
            tya
            pha

            lda cpm_fcb, y
            and #0x7f
            cmp #' '
            .zif ne
                jsr putchar
            .zendif

            pla
            tay
            iny
            cpy #FCB_T3+1
        .zuntil eq
    .zendif

    lda #'\r'
    jsr putchar    
    lda #'\n'
    jsr putchar  
    rts


\ Print string wrapper

.zproc print_string
    ldy #BDOS_PRINTSTRING
    jmp BDOS
.zendproc

\ Prints XA in decimal. Y is the padding char or 0 for no padding.

\ Prints an 8-bit hex number in A.
.zproc print_hex_number
    pha
    lsr a
    lsr a
    lsr a
    lsr a
    jsr h4
    pla
h4:
    and #0x0f 
    ora #'0'
    cmp #'9'+1
	.zif cs
		adc #6
	.zendif
   	pha
    jsr putchar
	pla
	rts
.zendproc

.zproc putchar

	ldy #BDOS_CONOUT
    jmp BDOS

.zendproc



BIOS:
    jmp 0

aux_not_found:
    .byte "error : cannot find auxilary devices\r\n$"

filename_not_given:
    .byte "error : please add filename to save as parameter\r\n$"

transmission_stopped:
    .byte "error : transmission stopped\r\n$"


cant_open_file:
    .byte "cannot open file\r\n$"


aux_found:
    .byte "info : found auxilary device at :$"

writing_to:
    .byte "info : writing to file : $"

start_transmission:
    .byte "info : Start transmission now \r\n$"

done_transmission:
    .byte "info : Everything finished. Bye \r\n$"


transmission_done:
    .byte "\r\ninfo : reception complete\r\n$"


