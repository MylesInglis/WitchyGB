;GameboY Audio Library
;by InvadrSoft

IF !DEF(GYAL_LIB) ;skip if already included
GYAL_LIB  SET  1

INCLUDE "MEMORY.ASM"
INCLUDE "gyalmacros.asm"

;channel variables struct

GYAL_CHN_STRUCT_SIZE EQU 4
GYAL_CHN_REPEAT EQU 0
GYAL_CHN_NOTE EQU 1
GYAL_CHN_POS_L EQU 2
GYAL_CHN_POS_H EQU 3

;envelope variables struct

GYAL_ENV_STRUCT_SIZE EQU 7
GYAL_ENV_ENABLED EQU 0
GYAL_ENV_VALUE EQU 1
GYAL_ENV_REPEAT EQU 2
GYAL_ENV_START_L EQU 3
GYAL_ENV_START_H EQU 4
GYAL_ENV_POS_L EQU 5
GYAL_ENV_POS_H EQU 6

;output buffer struct

GYAL_OUT_STRUCT_SIZE EQU 16
GYAL_OUT_PULSE1_D EQU 0
GYAL_OUT_PULSE1_V EQU 1
GYAL_OUT_PULSE1_L EQU 2
GYAL_OUT_PULSE1_H EQU 3
GYAL_OUT_PULSE2_D EQU 4
GYAL_OUT_PULSE2_V EQU 5
GYAL_OUT_PULSE2_L EQU 6
GYAL_OUT_PULSE2_H EQU 7
GYAL_OUT_WAVE_LEN EQU 8
GYAL_OUT_WAVE_V EQU 9
GYAL_OUT_WAVE_L EQU 10
GYAL_OUT_WAVE_H EQU 11
GYAL_OUT_NOISE_LEN EQU 12
GYAL_OUT_NOISE_V EQU 13
GYAL_OUT_NOISE_S EQU 14
GYAL_OUT_NOISE_T EQU 15

;SFX variables struct

GYAL_SFX_STRUCT_SIZE EQU 4 + (GYAL_OUT_STRUCT_SIZE * 2)
GYAL_SFX_ENABLED EQU 0
GYAL_SFX_REPEAT EQU 1
GYAL_SFX_POS_L EQU 2
GYAL_SFX_POS_H EQU 3
GYAL_SFX_BUF EQU 4 ;bytes = GYAL_OUT_STRUCT_SIZE
GYAL_SFX_FLAGS EQU 4 + GYAL_OUT_STRUCT_SIZE ;bytes = GYAL_OUT_STRUCT_SIZE

;Stream data enum

GYAL_STREAM_NOTE_OFF EQU 0
GYAL_STREAM_NEW_NOTE EQU 1
GYAL_STREAM_EMPTY_ROWS EQU 2
GYAL_STREAM_ENV EQU 3
GYAL_STREAM_SET EQU 4
GYAL_STREAM_JUMP EQU 5

PUSHS

SECTION "GYAL Variables", BSS

GYAL_PLAY_STATE: DS 1 ; 0 - paused/stopped, 1 - playing
GYAL_FRAME_CNT: DS 1
GYAL_SONG_SPEED: DS 1
GYAL_WAVETABLE_LIST: DS 2
GYAL_CH1_VARS: DS GYAL_CHN_STRUCT_SIZE
GYAL_CH2_VARS: DS GYAL_CHN_STRUCT_SIZE
GYAL_CH3_VARS: DS GYAL_CHN_STRUCT_SIZE
GYAL_CH4_VARS: DS GYAL_CHN_STRUCT_SIZE
GYAL_CH1_ENVS: DS GYAL_ENV_STRUCT_SIZE * 3 ;pitch, duty and arpeggio
GYAL_CH2_ENVS: DS GYAL_ENV_STRUCT_SIZE * 3 ;pitch, duty and arpeggio
GYAL_CH3_ENVS: DS GYAL_ENV_STRUCT_SIZE * 3 ;pitch, volume and arpeggio
;GYAL_CH4_ENVS: DS GYAL_ENV_STRUCT_SIZE ;none
GYAL_OUT_BUF: DS GYAL_OUT_STRUCT_SIZE
GYAL_OUT_FLAGS: DS GYAL_OUT_STRUCT_SIZE
GYAL_SFX_CHANNELS: DS GYAL_SFX_STRUCT_SIZE * 4

SECTION "GYAL Code", HOME

GyalInit:
    ld a, $FF
	ld a, %01110111
	ld [rAUDTERM], a
	xor a
	ld hl, GYAL_OUT_BUF
	ld bc, GYAL_OUT_STRUCT_SIZE * 2
	call mem_Set
	ld [rAUD1SWEEP], a
	ld [GYAL_CH1_VARS + GYAL_CHN_REPEAT], a
	ld [GYAL_CH2_VARS + GYAL_CHN_REPEAT], a
	ld [GYAL_CH3_VARS + GYAL_CHN_REPEAT], a
	ld [GYAL_CH4_VARS + GYAL_CHN_REPEAT], a
	ld [rAUD4LEN], a
	ld hl, GYAL_CH1_ENVS
	ld bc, GYAL_ENV_STRUCT_SIZE * 9
	call mem_Set
	ld hl, GYAL_SFX_CHANNELS
	ld bc, GYAL_SFX_STRUCT_SIZE * 4
	call mem_Set
	ld a, 1
	ld [GYAL_OUT_FLAGS + GYAL_OUT_PULSE1_D], a
	ld [GYAL_OUT_FLAGS + GYAL_OUT_PULSE2_D], a
	ld a, %10111111
	ld [GYAL_OUT_BUF + GYAL_OUT_PULSE1_D], a
	ld a, %10000000
	ld [GYAL_OUT_BUF + GYAL_OUT_PULSE2_D], a
	ld a, %11110111
	ld [GYAL_OUT_BUF + GYAL_OUT_PULSE1_V], a
	ld [GYAL_OUT_BUF + GYAL_OUT_PULSE2_V], a
	ld [rAUD1ENV], a
	ld [rAUD2ENV], a
	ld a, %00100000
	ld [rAUD3LEVEL], a
	ld a, %10000000
	ld [rAUD3ENA], a
	ld a, %11110100
	ld [rAUD4ENV], a
	ld a, %01000000
	ld [GYAL_OUT_BUF + GYAL_OUT_PULSE1_H], a
	ld a, 1
	ld [GYAL_OUT_FLAGS + GYAL_OUT_PULSE1_H], a
	ret
	
;start music stream
;in: HL - address of stream start

GyalMusicStart: 
	ld a, [HLI]
	ld [GYAL_SONG_SPEED], a
	;initialise stream positions for all channels
	ld a, [HLI] 
	ld [GYAL_CH1_VARS + GYAL_CHN_POS_L], a
	ld a, [HLI]
	ld [GYAL_CH1_VARS + GYAL_CHN_POS_H], a
	ld a, [HLI]
	ld [GYAL_CH2_VARS + GYAL_CHN_POS_L], a
	ld a, [HLI]
	ld [GYAL_CH2_VARS + GYAL_CHN_POS_H], a
	ld a, [HLI]
	ld [GYAL_CH3_VARS + GYAL_CHN_POS_L], a
	ld a, [HLI]
	ld [GYAL_CH3_VARS + GYAL_CHN_POS_H], a
	ld a, [HLI]
	ld [GYAL_CH4_VARS + GYAL_CHN_POS_L], a
	ld a, [HLI]
	ld [GYAL_CH4_VARS + GYAL_CHN_POS_H], a
	ld a, [HLI]
	ld [GYAL_WAVETABLE_LIST], a
	ld a, [HL]
	ld [GYAL_WAVETABLE_LIST + 1], a
	ld a, [GYAL_SONG_SPEED]
	ld [GYAL_FRAME_CNT], a
	ld a, 1
	ld [GYAL_PLAY_STATE], a
	ld c, 0
	call LoadWavetable
	ret
	
;play/pause toggle
	
GyalPlayPause:
	ld a, [GYAL_PLAY_STATE]
	or a
	jr z, .play
	jp .pause
.play
	ld a, 1
	ld [GYAL_PLAY_STATE], a
	ld a, $FF
	ld [rAUDTERM], a
	ret
.pause
	xor a
	ld [GYAL_PLAY_STATE], a
	ld [rAUDTERM], a
	ret

;Play sound effect
;in: hl - address of SFX
;    a - SFX channel number 
	
GyalSFXPlay:
	or a
	jr z, .ch0
	cp 1
	jr z, .ch1
	cp 2
	jr z, .ch2
	cp 3
	jr z, .ch3
.ch0
	PlaySFX 0
	jp .end
.ch1
	PlaySFX 1
	jp .end
.ch2
	PlaySFX 2
	jp .end
.ch3
	PlaySFX 3
.end
	ret
	
;call every frame
	
GyalUpdate:
	ld a, [GYAL_PLAY_STATE]
	or a
	jp z, .end ;if paused/stopped, do nothing
	ld a, [GYAL_FRAME_CNT]
	or a
	jr z, .nextrow 
	dec a
	ld [GYAL_FRAME_CNT], a
	call ProcessEnvelopes
	call ProcessSFX
	jp .output
.nextrow
	ld a, [GYAL_SONG_SPEED]
	ld [GYAL_FRAME_CNT], a ;reset frame counter
	call ProcessChannels
	call ProcessEnvelopes
	call ProcessSFX
.output
.pulse1sfx
.aud1ds
	CheckAllSFX rAUD1LEN, GYAL_OUT_PULSE1_D, .aud1vs
.aud1vs
	CheckAllSFX rAUD1ENV, GYAL_OUT_PULSE1_V, .aud1ls
.aud1ls
	CheckAllSFX rAUD1LOW, GYAL_OUT_PULSE1_L, .aud1hs
.aud1hs
	CheckAllSFX rAUD1HIGH, GYAL_OUT_PULSE1_H, .pulse2sfx
.pulse1mus
	ld a, b
	cp 1
	jr z, .pulse2sfx
.aud1d
	CheckChannel [rAUD1LEN], [GYAL_OUT_FLAGS + GYAL_OUT_PULSE1_D], [GYAL_OUT_BUF + GYAL_OUT_PULSE1_D], .aud1v, 0
.aud1v
	CheckChannel [rAUD1ENV], [GYAL_OUT_FLAGS + GYAL_OUT_PULSE1_V], [GYAL_OUT_BUF + GYAL_OUT_PULSE1_V], .aud1l, 0
.aud1l
	CheckChannel [rAUD1LOW], [GYAL_OUT_FLAGS + GYAL_OUT_PULSE1_L], [GYAL_OUT_BUF + GYAL_OUT_PULSE1_L], .aud1h, 0
.aud1h
	CheckChannel [rAUD1HIGH], [GYAL_OUT_FLAGS + GYAL_OUT_PULSE1_H], [GYAL_OUT_BUF + GYAL_OUT_PULSE1_H], .aud2d, 0
.pulse2sfx
.aud2d
	CheckAllSFX rAUD2LEN, GYAL_OUT_PULSE2_D, .aud2v
	CheckChannel [rAUD2LEN], [GYAL_OUT_FLAGS + GYAL_OUT_PULSE2_D], [GYAL_OUT_BUF + GYAL_OUT_PULSE2_D], .aud2v, 0
.aud2v
	CheckAllSFX rAUD2ENV, GYAL_OUT_PULSE2_V, .aud2l
	CheckChannel [rAUD2ENV], [GYAL_OUT_FLAGS + GYAL_OUT_PULSE2_V], [GYAL_OUT_BUF + GYAL_OUT_PULSE2_V], .aud2l, 0
.aud2l
	CheckAllSFX rAUD2LOW, GYAL_OUT_PULSE2_L, .aud2h
	CheckChannel [rAUD2LOW], [GYAL_OUT_FLAGS + GYAL_OUT_PULSE2_L], [GYAL_OUT_BUF + GYAL_OUT_PULSE2_L], .aud2h, 0
.aud2h
	CheckAllSFX rAUD2HIGH, GYAL_OUT_PULSE2_H, .aud3len
	CheckChannel [rAUD2HIGH], [GYAL_OUT_FLAGS + GYAL_OUT_PULSE2_H], [GYAL_OUT_BUF + GYAL_OUT_PULSE2_H], .aud3len, 0
.aud3len
	CheckAllSFX rAUD3LEN, GYAL_OUT_WAVE_LEN, .aud3v
	CheckChannel [rAUD3LEN], [GYAL_OUT_FLAGS + GYAL_OUT_WAVE_LEN], [GYAL_OUT_BUF + GYAL_OUT_WAVE_LEN], .aud3v, 0
.aud3v
	CheckAllSFX rAUD3LEVEL, GYAL_OUT_WAVE_V, .aud3l
	CheckChannel [rAUD3LEVEL], [GYAL_OUT_FLAGS + GYAL_OUT_WAVE_V], [GYAL_OUT_BUF + GYAL_OUT_WAVE_V], .aud3l, 0
.aud3l
	CheckAllSFX rAUD3LOW, GYAL_OUT_WAVE_L, .aud3h
	CheckChannel [rAUD3LOW], [GYAL_OUT_FLAGS + GYAL_OUT_WAVE_L], [GYAL_OUT_BUF + GYAL_OUT_WAVE_L], .aud3h, 0
.aud3h
	CheckAllSFX rAUD3HIGH, GYAL_OUT_WAVE_H, .aud4len
	CheckChannel [rAUD3HIGH], [GYAL_OUT_FLAGS + GYAL_OUT_WAVE_H], [GYAL_OUT_BUF + GYAL_OUT_WAVE_H], .aud4len, 1
.aud4len
	CheckAllSFX rAUD4LEN, GYAL_OUT_NOISE_LEN, .aud4v
	CheckChannel [rAUD4LEN], [GYAL_OUT_FLAGS + GYAL_OUT_NOISE_LEN], [GYAL_OUT_BUF + GYAL_OUT_NOISE_LEN], .aud4v, 0
.aud4v
	CheckAllSFX rAUD4ENV, GYAL_OUT_NOISE_V, .aud4s
	CheckChannel [rAUD4ENV], [GYAL_OUT_FLAGS + GYAL_OUT_NOISE_V], [GYAL_OUT_BUF + GYAL_OUT_NOISE_V], .aud4s, 0
.aud4s
	CheckAllSFX rAUD4POLY, GYAL_OUT_NOISE_S, .aud4t
	CheckChannel [rAUD4POLY], [GYAL_OUT_FLAGS + GYAL_OUT_NOISE_S], [GYAL_OUT_BUF + GYAL_OUT_NOISE_S], .aud4t, 0
.aud4t
	CheckAllSFX rAUD4GO, GYAL_OUT_NOISE_T, .end
	CheckChannel [rAUD4GO], [GYAL_OUT_FLAGS + GYAL_OUT_NOISE_T], [GYAL_OUT_BUF + GYAL_OUT_NOISE_T], .end, 0
.end
	ret
	
ProcessChannels:
.ch1
	ProcessChannel GYAL_CH1_VARS, GYAL_CH1_ENVS, 1
.ch2
	ProcessChannel GYAL_CH2_VARS, GYAL_CH2_ENVS, 2
.ch3
	ProcessChannel GYAL_CH3_VARS, GYAL_CH3_ENVS, 3
.ch4
	ProcessChannel GYAL_CH4_VARS, 0, 4
.chend
	ret
	
ProcessEnvelopes:
	ProcessChannelEnvelopes 1
	ProcessChannelEnvelopes 2
	ProcessChannelEnvelopes 3
	ret
	
ProcessSFX:
	ProcessSFXChannel 0
	ProcessSFXChannel 1
	ProcessSFXChannel 2
	ProcessSFXChannel 3
	ret

	
; in: b - stream byte
; out: a - stream data type
DecodeStream:
	ld a, b
	or a ;check for note off
	jr z, .noteoff
	cp $FF
	jr z, .jump
	bit 7, b ;test bits 7 and 6 to see what kind of instruction
	jr z, .bit7zero
	bit 6, b
	jr z, .newenv ;10
	jp .setduty ;11
.bit7zero
	bit 6, b
	jr z, .newnote ;00
	jp .emptyrows ;01
.noteoff
	ld a, GYAL_STREAM_NOTE_OFF
	ret
.jump
	ld a, GYAL_STREAM_JUMP
	ret
.newnote
	ld a, GYAL_STREAM_NEW_NOTE
	ret
.emptyrows
	ld a, GYAL_STREAM_EMPTY_ROWS
	ret
.newenv
	ld a, GYAL_STREAM_ENV
	ret
.setduty
	ld a, GYAL_STREAM_SET
	ret
	
; in: c - note number
; out: de - frequency
NoteNumberToFrequency:
	push hl
	ld b, 0
	sla c
	ld hl, FrequencyTable
	add hl, bc
	ld a, [HLI]
	ld e, a
	ld a, [HL]
	ld d, a
	pop hl
	ret
	
; in: c - wavetable number
	
LoadWavetable:
	push af
	push bc
	push de
	push hl
	ld a, 0
	ld [rAUD3ENA], a
	ld a, [GYAL_WAVETABLE_LIST]
	ld l, a
	ld a, [GYAL_WAVETABLE_LIST + 1]
	ld h, a
	sla c
	ld b, 0
	add hl, bc
	ld a, [HLI]
	ld e, a
	ld a, [HL]
	ld d, a
	ld l, e
	ld h, d
	ld de, _AUD3WAVERAM
	ld bc, 16
	call mem_Copy
	ld a, %10000000
	ld [rAUD3ENA], a
	pop hl
	pop de
	pop bc
	pop af
	ret

SECTION "FrequencyTable", DATA

	
FrequencyTable:
	DW 0000, 
	DW 0044, 0156, 0262, 0363, 0457, 0547, 0631, 0710, 0786, 0854, 0923, 0986
	DW 1046, 1102, 1155, 1205, 1253, 1297, 1339, 1379, 1417, 1452, 1486, 1517
	DW 1546, 1575, 1602, 1627, 1650, 1673, 1694, 1714, 1732, 1750, 1767, 1783
	DW 1798, 1812, 1825, 1837, 1849, 1860, 1871, 1881, 1890, 1899, 1907, 1915
	DW 1923, 1930, 1936, 1943, 1949, 1954, 1959, 1964, 1969, 1974, 1978, 1982
	DW 1985, 1988, 1992, 1995, 1998, 2001, 2004, 2006, 2009, 2011, 2013, 2015

POPS
	
ENDC
