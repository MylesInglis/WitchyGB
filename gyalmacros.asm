;1 - SFX channel
;HL - SFX address
PlaySFX: MACRO
	ld a, l
	ld [GYAL_SFX_CHANNELS + (GYAL_SFX_STRUCT_SIZE * \1) + GYAL_SFX_POS_L], a
	ld a, h
	ld [GYAL_SFX_CHANNELS + (GYAL_SFX_STRUCT_SIZE * \1) + GYAL_SFX_POS_H], a
	ld a, 1
	ld [GYAL_SFX_CHANNELS + (GYAL_SFX_STRUCT_SIZE * \1) + GYAL_SFX_ENABLED], a
	xor a
	ld [GYAL_SFX_CHANNELS + (GYAL_SFX_STRUCT_SIZE * \1) + GYAL_SFX_REPEAT], a
	ENDM

;1 - Channel Number
ProcessSFXChannel: MACRO
	ld a, [GYAL_SFX_CHANNELS + (GYAL_SFX_STRUCT_SIZE * \1) + GYAL_SFX_ENABLED]
	or a
	jr z, .end\@
	ld a, [GYAL_SFX_CHANNELS + (GYAL_SFX_STRUCT_SIZE * \1) + GYAL_SFX_REPEAT]
	or a
	jr z, .read\@
	dec a
	ld [GYAL_SFX_CHANNELS + (GYAL_SFX_STRUCT_SIZE * \1) + GYAL_SFX_REPEAT], a
	jr .end\@
.read\@
	ld a, [GYAL_SFX_CHANNELS + (GYAL_SFX_STRUCT_SIZE * \1) + GYAL_SFX_POS_L]
	ld l, a
	ld a, [GYAL_SFX_CHANNELS + (GYAL_SFX_STRUCT_SIZE * \1) + GYAL_SFX_POS_H]
	ld h, a
.readnextbyte\@
	ld a, [HLI]
	cp $FF
	jr z, .streamend\@
	cp %00001111
	jr c, .output\@ ; <16
.repeats\@
	swap a
	dec a
	ld [GYAL_SFX_CHANNELS + (GYAL_SFX_STRUCT_SIZE * \1) + GYAL_SFX_REPEAT], a
	jr .save\@
.output\@
	ld c, a
	ld a, [HLI]
	ld d, a
	push hl
	xor a
	ld b, a
	ld hl, GYAL_SFX_CHANNELS + (GYAL_SFX_STRUCT_SIZE * \1) + GYAL_SFX_BUF
	add hl, bc
	ld [HL], d
	ld hl, GYAL_SFX_CHANNELS + (GYAL_SFX_STRUCT_SIZE * \1) + GYAL_SFX_FLAGS
	add hl, bc
	ld a, 1
	ld [HL], a
	ld a, c
	cp GYAL_OUT_PULSE1_H
	jr z, .outend\@
	cp GYAL_OUT_PULSE2_H
	jr z, .outend\@
	cp GYAL_OUT_WAVE_H
	jr z, .outend\@
	cp GYAL_OUT_NOISE_T
	jr z, .outend\@
	ld hl, GYAL_OUT_FLAGS
	add hl, bc
	ld a, 1
	ld [HL], a
.outend\@
	pop hl
	jr .readnextbyte\@
.streamend\@
	xor a
	ld [GYAL_SFX_CHANNELS + (GYAL_SFX_STRUCT_SIZE * \1) + GYAL_SFX_ENABLED], a
.save\@
	ld a, l
	ld [GYAL_SFX_CHANNELS + (GYAL_SFX_STRUCT_SIZE * \1) + GYAL_SFX_POS_L], a
	ld a, h
	ld [GYAL_SFX_CHANNELS + (GYAL_SFX_STRUCT_SIZE * \1) + GYAL_SFX_POS_H], a
.end\@
	ENDM
	
;1 - Channel variables start
;2 - Channel envelopes start
;3 - Channel number
ProcessChannel: MACRO
	ld a, [\1 + GYAL_CHN_REPEAT] ;first check for empty rows
	or a
	jr z, .nextrow\@
	dec a
	ld [\1 + GYAL_CHN_REPEAT], a
	jp .skip\@ ;skip this channel because there are still empty rows left
.nextrow\@
	ld a, [\1 + GYAL_CHN_POS_L] ;set HL to ch1 current stream pos
	ld l, a
	ld a, [\1 + GYAL_CHN_POS_H]
	ld h, a
.readstream\@
	ld a, [HLI]
	ld b, a
	call DecodeStream
	cp GYAL_STREAM_NOTE_OFF
	jr z, .noteoff\@
	cp GYAL_STREAM_NEW_NOTE
	jr z, .newnote\@
	cp GYAL_STREAM_EMPTY_ROWS
	jr z, .emptyrows\@
	cp GYAL_STREAM_ENV
	jr z, .newenv\@
	cp GYAL_STREAM_SET
	jp z, .setparam\@
	cp GYAL_STREAM_JUMP
	jp z, .jump\@
.noteoff\@
	NoteOff \3
	jp .end\@
.newnote\@
	NewNote \3
	jp .end\@
.emptyrows\@
	ld a, %00111111
	and b
	ld [\1 + GYAL_CHN_REPEAT], a
	jp .end\@
.newenv\@
	;skip if noise channel
	IF \3 == 4
		jp .newenvend\@
	ENDC
	ld a, %00000011
	and b
	or a
	jr z, .env1\@
	cp 1
	jr z, .env2\@
	cp 2
	jr z, .env3\@
.env1\@
	ld a, %00001100
	and b
	swap a
	ld [\2 + GYAL_ENV_ENABLED], a
	ld a, [HLI]
	ld [\2 + GYAL_ENV_START_L], a
	ld [\2 + GYAL_ENV_POS_L], a
	ld a, [HLI]
	ld [\2 + GYAL_ENV_START_H], a
	ld [\2 + GYAL_ENV_POS_H], a
	jr .newenvend\@
.env2\@
	ld a, %00001100
	and b
	swap a
	ld [\2 + GYAL_ENV_STRUCT_SIZE + GYAL_ENV_ENABLED], a
	ld a, [HLI]
	ld [\2 + GYAL_ENV_STRUCT_SIZE + GYAL_ENV_START_L], a
	ld [\2 + GYAL_ENV_STRUCT_SIZE + GYAL_ENV_POS_L], a
	ld a, [HLI]
	ld [\2 + GYAL_ENV_STRUCT_SIZE + GYAL_ENV_START_H], a
	ld [\2 + GYAL_ENV_STRUCT_SIZE + GYAL_ENV_POS_H], a
	jr .newenvend\@
.env3\@
	ld a, %00001100
	and b
	swap a
	ld [\2 + (GYAL_ENV_STRUCT_SIZE * 2) + GYAL_ENV_ENABLED], a
	ld a, [HLI]
	ld [\2 + (GYAL_ENV_STRUCT_SIZE * 2) + GYAL_ENV_START_L], a
	ld [\2 + (GYAL_ENV_STRUCT_SIZE * 2) + GYAL_ENV_POS_L], a
	ld a, [HLI]
	ld [\2 + (GYAL_ENV_STRUCT_SIZE * 2) + GYAL_ENV_START_H], a
	ld [\2 + (GYAL_ENV_STRUCT_SIZE * 2) + GYAL_ENV_POS_H], a
	jr .newenvend\@
.newenvend\@
	bit 5, b
	jr z, .end\@
	jp .readstream\@
.setparam\@
	SetParam \3
	bit 4, b
	jr z, .end\@
	jp .readstream\@
.jump\@
	ld a, [HLI]
	ld [\1 + GYAL_CHN_POS_L], a
	ld a, [HL]
	ld [\1 + GYAL_CHN_POS_H], a
	jp .nextrow\@
.end\@
	ld a, l
	ld [\1 + GYAL_CHN_POS_L], a
	ld a, h
	ld [\1 + GYAL_CHN_POS_H], a
.skip\@
	ENDM
	
;1 - Channel Number
NoteOff: MACRO
	IF \1 == 1
		PulseNoteOff GYAL_OUT_PULSE1_D, GYAL_OUT_PULSE1_H
	ELSE
		IF \1 == 2
			PulseNoteOff GYAL_OUT_PULSE2_D, GYAL_OUT_PULSE2_H
		ELSE
			IF \1 == 3
				WaveNoteOff
			ELSE
				NoiseNoteOff
			ENDC
		ENDC
	ENDC
	ENDM
	
;1 - Duty
;2 - Frequency high
PulseNoteOff: MACRO
	ld a, [GYAL_OUT_BUF + \1]
	ld b, a
	ld a, %00111111
	or b
	ld [GYAL_OUT_BUF + \1], a
	ld a, %01000000
	ld [GYAL_OUT_BUF + \2], a
	ld a, 1
	ld [GYAL_OUT_FLAGS + \1], a
	ld [GYAL_OUT_FLAGS + \2], a
	ENDM
	
WaveNoteOff: MACRO
	ld a, $FF
	ld [GYAL_OUT_BUF + GYAL_OUT_WAVE_LEN], a
	ld a, %01000000
	ld [GYAL_OUT_BUF + GYAL_OUT_WAVE_H], a
	ld a, 1
	ld [GYAL_OUT_FLAGS + GYAL_OUT_WAVE_LEN], a
	ld [GYAL_OUT_FLAGS + GYAL_OUT_WAVE_H], a
	ENDM

NoiseNoteOff: MACRO
	ld a, %00111111
	ld [GYAL_OUT_BUF + GYAL_OUT_NOISE_LEN], a
	ld a, %01000000
	ld [GYAL_OUT_BUF + GYAL_OUT_NOISE_T], a
	ld a, 1
	ld [GYAL_OUT_FLAGS + GYAL_OUT_NOISE_LEN], a
	ld [GYAL_OUT_FLAGS + GYAL_OUT_NOISE_T], a
	ENDM

;1 - Channel number
NewNote: MACRO
	IF \1 == 1
		PulseWaveNewNote GYAL_CH1_VARS, GYAL_OUT_PULSE1_L, GYAL_OUT_PULSE1_H
	ELSE
		IF \1 == 2
			PulseWaveNewNote GYAL_CH2_VARS, GYAL_OUT_PULSE2_L, GYAL_OUT_PULSE2_H
		ELSE
			IF \1 == 3
				PulseWaveNewNote GYAL_CH3_VARS, GYAL_OUT_WAVE_L, GYAL_OUT_WAVE_H
			ELSE
				NoiseNewNote
			ENDC
		ENDC
	ENDC
	ENDM
	
;1 - Channel vars
;2 - Freq low
;3 - Freq high
PulseWaveNewNote: MACRO
	ld a, %00111111
	and b
	ld [\1 + GYAL_CHN_NOTE], a
	ld c, a
	call NoteNumberToFrequency
	ld a, e
	ld [GYAL_OUT_BUF + \2], a
	ld a, %10000000
	xor d
	ld [GYAL_OUT_BUF + \3], a
	ld a, 1
	ld [GYAL_OUT_FLAGS + \2], a
	ld [GYAL_OUT_FLAGS + \3], a
	ENDM
	
NoiseNewNote: MACRO
	ld a, [HLI]
	ld [GYAL_OUT_BUF + GYAL_OUT_NOISE_S], a
	ld a, %10000000
	ld [GYAL_OUT_BUF + GYAL_OUT_NOISE_T], a
	ld a, 1
	ld [GYAL_OUT_FLAGS + GYAL_OUT_NOISE_S], a
	ld [GYAL_OUT_FLAGS + GYAL_OUT_NOISE_T], a
	ENDM
	
;1 - Channel number
SetParam: MACRO
	IF \1 == 1
		PulseSetParam GYAL_OUT_PULSE1_D, GYAL_OUT_PULSE1_V
	ELSE
		IF \1 == 2
			PulseSetParam GYAL_OUT_PULSE2_D, GYAL_OUT_PULSE2_V
		ELSE
			IF \1 == 3
				WaveSetParam
			ELSE
				NoiseSetParam
			ENDC
		ENDC
	ENDC
	ENDM
	
;1 - Duty
;2 - Volume env
PulseSetParam: MACRO
.setduty\@
	bit 5, b
	jr z, .setvolenv\@
	ld c, b
	swap c
	ld a, %11000000
	and c
	ld [GYAL_OUT_BUF + \1], a
	ld a, 1
	ld [GYAL_OUT_FLAGS + \1], a
	jp .setend\@
.setvolenv\@
	ld a, [HLI]
	ld [GYAL_OUT_BUF + \2], a
	ld a, 1
	ld [GYAL_OUT_FLAGS + \2], a
.setend\@
	ENDM
	
WaveSetParam: MACRO
.setwave\@
	bit 5, b
	jr z, .setvol\@
	ld a, %00001111
	and b
	ld c, a
	call LoadWavetable
	jr .setend\@
.setvol\@
	ld a, %00001100
	and b
	swap a
	srl a
	ld [GYAL_OUT_BUF + GYAL_OUT_WAVE_V], a
	ld a, 1
	ld [GYAL_OUT_FLAGS + GYAL_OUT_WAVE_V], a
.setend\@
	ENDM

NoiseSetParam: MACRO
	ld a, [HLI]
	ld [GYAL_OUT_BUF + GYAL_OUT_NOISE_V], a
	ld a, 1
	ld [GYAL_OUT_FLAGS + GYAL_OUT_NOISE_V], a
	ENDM
	
;1 - channel number
ProcessChannelEnvelopes: MACRO
	IF \1 == 1
		PitchEnvelope GYAL_CH1_ENVS, GYAL_OUT_PULSE1_H, GYAL_OUT_PULSE1_L, GYAL_CH1_VARS
		DutyEnvelope GYAL_CH1_ENVS, GYAL_OUT_PULSE1_H, GYAL_OUT_PULSE1_D
		ArpEnvelope GYAL_CH1_ENVS, GYAL_OUT_PULSE1_H, GYAL_OUT_PULSE1_L, GYAL_CH1_VARS
	ELSE
		IF \1 == 2
			PitchEnvelope GYAL_CH2_ENVS, GYAL_OUT_PULSE2_H, GYAL_OUT_PULSE2_L, GYAL_CH2_VARS
			DutyEnvelope GYAL_CH2_ENVS, GYAL_OUT_PULSE2_H, GYAL_OUT_PULSE2_D
			ArpEnvelope GYAL_CH2_ENVS, GYAL_OUT_PULSE2_H, GYAL_OUT_PULSE2_L, GYAL_CH2_VARS
		ELSE
			IF \1 == 3
				PitchEnvelope GYAL_CH3_ENVS, GYAL_OUT_WAVE_H, GYAL_OUT_WAVE_L, GYAL_CH3_VARS
				VolEnvelope
				ArpEnvelope GYAL_CH3_ENVS, GYAL_OUT_WAVE_H, GYAL_OUT_WAVE_L, GYAL_CH3_VARS
			ENDC
		ENDC
	ENDC
	ENDM
	
EnvelopeBase: MACRO

	ENDM
	
;1 - channel envelopes
;2 - freq high
;3 - freq low
;4 - channel variables
PitchEnvelope: MACRO
.start\@
	ld a, [\1 + GYAL_ENV_ENABLED]
	bit 7, a ;enabled bit
	jp z, .end\@
	ld a, [\1 + GYAL_ENV_POS_L]
	ld l, a
	ld a, [\1 + GYAL_ENV_POS_H]
	ld h, a
	ld a, [\1 + GYAL_ENV_ENABLED]
	bit 6, a ;check loop mode
	jr z, .noloop\@
	bit 5, a ;this bit is set when end of stream reached
	jr z, .read\@
	ld a, [\1 + GYAL_ENV_REPEAT]
	or a
	jr z, .norepeat\@
	dec a
	ld [\1 + GYAL_ENV_REPEAT], a
	jr .calc\@
.norepeat\@
	ld a, [\1 + GYAL_ENV_ENABLED]
	res 5, a
	ld [\1 + GYAL_ENV_ENABLED], a
	ld a, [\1 + GYAL_ENV_START_L]
	ld [\1 + GYAL_ENV_POS_L], a
	ld a, [\1 + GYAL_ENV_START_H]
	ld [\1 + GYAL_ENV_POS_H], a
	jr .read\@
.noloop\@
	ld a, [GYAL_OUT_FLAGS + \2]
	or a
	jr z, .nonote\@
	ld a, [GYAL_OUT_BUF + \2]
	bit 7, a
	jr z, .nonote\@
	ld a, [\1 + GYAL_ENV_START_L]
	ld l, a
	ld [\1 + GYAL_ENV_POS_L], a
	ld a, [\1 + GYAL_ENV_START_H]
	ld h, a
	ld a, [\1 + GYAL_ENV_ENABLED]
	ld [\1 + GYAL_ENV_POS_H], a
	res 5, a
	ld [\1 + GYAL_ENV_ENABLED], a
	jr .read\@
.nonote\@
	ld a, [\1 + GYAL_ENV_REPEAT]
	or a
	jr z, .noloopnorepeat\@
	dec a
	ld [\1 + GYAL_ENV_REPEAT], a
	jr .calc\@
.noloopnorepeat\@
	ld a, [\1 + GYAL_ENV_ENABLED]
	bit 5, a ;this bit is set when end of stream reached
	jr z, .read\@
	jr .calc\@ ;repeat last value
.read\@
	xor a
	ld [\1 + GYAL_ENV_REPEAT], a
	ld a, [HLI]
	ld b, a
	ld a, %01111111
	cp b
	jr z, .streamend\@
	bit 7, b
	jr z, .repeats\@
	ld a, b
	ld [\1 + GYAL_ENV_VALUE], a
.calc\@
	ld a, [\4 + GYAL_CHN_NOTE]
	ld c, a
	call NoteNumberToFrequency
	xor a
	ld b, a
	ld a, [\1 + GYAL_ENV_VALUE]
	ld c, a
	ld a, %00111111
	and c
	sla a
	sla a
	bit 6, c
	jr z, .add\@
	jr .sub\@
.repeats\@
	ld a, %00111111
	and b
	ld [\1 + GYAL_ENV_REPEAT], a
	jp .calc\@
.streamend\@
	ld a, [\1 + GYAL_ENV_ENABLED]
	set 5, a
	ld [\1 + GYAL_ENV_ENABLED], a
	jp .start\@
.add\@
	add a, e
	ld e, a
	ld a, 0
	adc a, d
	ld d, a
	jr .out\@
.sub\@
	ld c, a
	ld a, e
	sub a, c
	ld e, a
	ld a, d
	sbc a, b
	ld d, a
.out\@
	ld a, e
	ld [GYAL_OUT_BUF + \3], a
	ld a, [GYAL_OUT_FLAGS + \2]
	or a
	jr z, .notrigger\@
	ld a, [GYAL_OUT_BUF + \2]
	ld b, a
	ld a, %11000000
	and b
	or d
	ld [GYAL_OUT_BUF + \2], a
	jr .setflags\@
.notrigger\@
	ld a, d
	ld [GYAL_OUT_BUF + \2], a
.setflags\@
	ld a, 1
	ld [GYAL_OUT_FLAGS + \3], a
	ld [GYAL_OUT_FLAGS + \2], a
.savepos\@
	ld a, l
	ld [\1 + GYAL_ENV_POS_L], a
	ld a, h
	ld [\1 + GYAL_ENV_POS_H], a
.end\@
	ENDM
	
;1 - Channel envs
;2 - Frequency high
;3 - Duty
DutyEnvelope: MACRO
.start\@
	ld a, [\1 + GYAL_ENV_STRUCT_SIZE + GYAL_ENV_ENABLED]
	bit 7, a ;enabled bit
	jp z, .end\@
	ld a, [\1 + GYAL_ENV_STRUCT_SIZE + GYAL_ENV_POS_L]
	ld l, a
	ld a, [\1 + GYAL_ENV_STRUCT_SIZE + GYAL_ENV_POS_H]
	ld h, a
	ld a, [\1 + GYAL_ENV_STRUCT_SIZE + GYAL_ENV_ENABLED]
	bit 6, a ;check loop mode
	jr z, .noloop\@
	bit 5, a ;this bit is set when end of stream reached
	jr z, .read\@
	ld a, [\1 + GYAL_ENV_STRUCT_SIZE + GYAL_ENV_REPEAT]
	or a
	jr z, .norepeat\@
	dec a
	ld [\1 + GYAL_ENV_STRUCT_SIZE + GYAL_ENV_REPEAT], a
	jr .out\@
.norepeat\@
	ld a, [\1 + GYAL_ENV_STRUCT_SIZE + GYAL_ENV_ENABLED]
	res 5, a
	ld [\1 + GYAL_ENV_STRUCT_SIZE + GYAL_ENV_ENABLED], a
	ld a, [\1 + GYAL_ENV_STRUCT_SIZE + GYAL_ENV_START_L]
	ld [\1 + GYAL_ENV_STRUCT_SIZE + GYAL_ENV_POS_L], a
	ld a, [\1 + GYAL_ENV_STRUCT_SIZE + GYAL_ENV_START_H]
	ld [\1 + GYAL_ENV_STRUCT_SIZE + GYAL_ENV_POS_H], a
	jr .read\@
.noloop\@
	ld a, [GYAL_OUT_FLAGS + \2]
	or a
	jr z, .nonote\@
	ld a, [GYAL_OUT_BUF + \2]
	bit 7, a
	jr z, .nonote\@
	ld a, [\1 + GYAL_ENV_STRUCT_SIZE + GYAL_ENV_START_L]
	ld l, a
	ld [\1 + GYAL_ENV_STRUCT_SIZE + GYAL_ENV_POS_L], a
	ld a, [\1 + GYAL_ENV_STRUCT_SIZE + GYAL_ENV_START_H]
	ld h, a
	ld [\1 + GYAL_ENV_STRUCT_SIZE + GYAL_ENV_POS_H], a
	ld a, [\1 + GYAL_ENV_STRUCT_SIZE + GYAL_ENV_ENABLED]
	res 5, a
	ld [\1 + GYAL_ENV_STRUCT_SIZE + GYAL_ENV_ENABLED], a
	jr .read\@
.nonote\@
	ld a, [\1 + GYAL_ENV_STRUCT_SIZE + GYAL_ENV_REPEAT]
	or a
	jr z, .noloopnorepeat\@
	dec a
	ld [\1 + GYAL_ENV_STRUCT_SIZE + GYAL_ENV_REPEAT], a
	jr .out\@
.noloopnorepeat\@
	ld a, [\1 + GYAL_ENV_STRUCT_SIZE + GYAL_ENV_ENABLED]
	bit 5, a ;this bit is set when end of stream reached
	jr z, .read\@
	jr .out\@ ;repeat last value
.read\@
	xor a
	ld [\1 + GYAL_ENV_STRUCT_SIZE + GYAL_ENV_REPEAT], a
	ld a, [HLI]
	ld b, a
	ld a, %01111111
	cp b
	jr z, .streamend\@
	bit 7, b
	jr z, .repeats\@
	ld a, b
	ld [\1 + GYAL_ENV_STRUCT_SIZE + GYAL_ENV_VALUE], a
	jr .out\@
.repeats\@
	ld a, %00111111
	and b
	ld [\1 + GYAL_ENV_STRUCT_SIZE + GYAL_ENV_REPEAT], a
	jp .out\@
.streamend\@
	ld a, [\1 + GYAL_ENV_STRUCT_SIZE + GYAL_ENV_ENABLED]
	set 5, a
	ld [\1 + GYAL_ENV_STRUCT_SIZE + GYAL_ENV_ENABLED], a
	jp .start\@
.out\@
	ld a, [\1 + GYAL_ENV_STRUCT_SIZE + GYAL_ENV_VALUE]
	swap a
	ld b, a
	ld a, %00111111
	or b
	ld [GYAL_OUT_BUF + \3], a
	ld a, 1
	ld [GYAL_OUT_FLAGS + \3], a
.savepos\@
	ld a, l
	ld [\1 + GYAL_ENV_STRUCT_SIZE + GYAL_ENV_POS_L], a
	ld a, h
	ld [\1 + GYAL_ENV_STRUCT_SIZE + GYAL_ENV_POS_H], a
.end\@
	ENDM
	
;1 - Channel envs
;2 - Frequency high
;3 - Frequency low
;4 - Channel vars
ArpEnvelope: MACRO
.start\@
	ld a, [\1 + (GYAL_ENV_STRUCT_SIZE * 2) + GYAL_ENV_ENABLED]
	bit 7, a ;enabled bit
	jp z, .end\@
	ld a, [\1 + (GYAL_ENV_STRUCT_SIZE * 2) + GYAL_ENV_POS_L]
	ld l, a
	ld a, [\1 + (GYAL_ENV_STRUCT_SIZE * 2) + GYAL_ENV_POS_H]
	ld h, a
	ld a, [\1 + (GYAL_ENV_STRUCT_SIZE * 2) + GYAL_ENV_ENABLED]
	bit 6, a ;check loop mode
	jr z, .noloop\@
	bit 5, a ;this bit is set when end of stream reached
	jr z, .read\@
	ld a, [\1 + (GYAL_ENV_STRUCT_SIZE * 2) + GYAL_ENV_REPEAT]
	or a
	jr z, .norepeat\@
	dec a
	ld [\1 + (GYAL_ENV_STRUCT_SIZE * 2) + GYAL_ENV_REPEAT], a
	jr .out\@
.norepeat\@
	ld a, [\1 + (GYAL_ENV_STRUCT_SIZE * 2) + GYAL_ENV_ENABLED]
	res 5, a
	ld [\1 + (GYAL_ENV_STRUCT_SIZE * 2) + GYAL_ENV_ENABLED], a
	ld a, [\1 + (GYAL_ENV_STRUCT_SIZE * 2) + GYAL_ENV_START_L]
	ld [\1 + (GYAL_ENV_STRUCT_SIZE * 2) + GYAL_ENV_POS_L], a
	ld a, [\1 + (GYAL_ENV_STRUCT_SIZE * 2) + GYAL_ENV_START_H]
	ld [\1 + (GYAL_ENV_STRUCT_SIZE * 2) + GYAL_ENV_POS_H], a
	jr .read\@
.noloop\@
	ld a, [GYAL_OUT_FLAGS + \2]
	or a
	jr z, .nonote\@
	ld a, [GYAL_OUT_BUF + \2]
	bit 7, a
	jr z, .nonote\@
	ld a, [\1 + (GYAL_ENV_STRUCT_SIZE * 2) + GYAL_ENV_START_L]
	ld l, a
	ld [\1 + (GYAL_ENV_STRUCT_SIZE * 2) + GYAL_ENV_POS_L], a
	ld a, [\1 + (GYAL_ENV_STRUCT_SIZE * 2) + GYAL_ENV_START_H]
	ld h, a
	ld [\1 + (GYAL_ENV_STRUCT_SIZE * 2) + GYAL_ENV_POS_H], a
	ld a, [\1 + (GYAL_ENV_STRUCT_SIZE * 2) + GYAL_ENV_ENABLED]
	res 5, a
	ld [\1 + (GYAL_ENV_STRUCT_SIZE * 2) + GYAL_ENV_ENABLED], a
	jr .read\@
.nonote\@
	ld a, [\1 + (GYAL_ENV_STRUCT_SIZE * 2) + GYAL_ENV_REPEAT]
	or a
	jr z, .noloopnorepeat\@
	dec a
	ld [\1 + (GYAL_ENV_STRUCT_SIZE * 2) + GYAL_ENV_REPEAT], a
	jr .out\@
.noloopnorepeat\@
	ld a, [\1 + (GYAL_ENV_STRUCT_SIZE * 2) + GYAL_ENV_ENABLED]
	bit 5, a ;this bit is set when end of stream reached
	jr z, .read\@
	jr .out\@ ;repeat last value
.read\@
	xor a
	ld [\1 + (GYAL_ENV_STRUCT_SIZE * 2) + GYAL_ENV_REPEAT], a
	ld a, [HLI]
	ld b, a
	ld a, %01111111
	cp b
	jr z, .streamend\@
	bit 7, b
	jr z, .repeats\@
	ld a, b
	ld [\1 + (GYAL_ENV_STRUCT_SIZE * 2) + GYAL_ENV_VALUE], a
	jr .out\@
.repeats\@
	ld a, %00111111
	and b
	ld [\1 + (GYAL_ENV_STRUCT_SIZE * 2) + GYAL_ENV_REPEAT], a
	jp .out\@
.streamend\@
	ld a, [\1 + (GYAL_ENV_STRUCT_SIZE * 2) + GYAL_ENV_ENABLED]
	set 5, a
	ld [\1 + (GYAL_ENV_STRUCT_SIZE * 2) + GYAL_ENV_ENABLED], a
	jp .start\@
.out\@
	ld a, [\1 + (GYAL_ENV_STRUCT_SIZE * 2) + GYAL_ENV_VALUE]
	ld b, a
	ld a, %00111111
	and b
	ld b, a
	ld a, [\4 + GYAL_CHN_NOTE]
	add a, b
	ld c, a
	call NoteNumberToFrequency
	ld a, e
	ld [GYAL_OUT_BUF + \3], a
	ld a, [GYAL_OUT_FLAGS + \2]
	or a
	jr z, .notrigger\@
	ld a, [GYAL_OUT_BUF + \2]
	ld b, a
	ld a, %11000000
	and b
	or d
	ld [GYAL_OUT_BUF + \2], a
	jr .setflags\@
.notrigger\@
	ld a, d
	ld [GYAL_OUT_BUF + \2], a
.setflags\@
	ld a, 1
	ld [GYAL_OUT_FLAGS + \3], a
	ld [GYAL_OUT_FLAGS + \2], a
.savepos\@
	ld a, l
	ld [\1 + (GYAL_ENV_STRUCT_SIZE * 2) + GYAL_ENV_POS_L], a
	ld a, h
	ld [\1 + (GYAL_ENV_STRUCT_SIZE * 2) + GYAL_ENV_POS_H], a
.end\@
	ENDM

;Wave channel specific
VolEnvelope: MACRO
.start\@
	ld a, [GYAL_CH3_ENVS + GYAL_ENV_STRUCT_SIZE + GYAL_ENV_ENABLED]
	bit 7, a ;enabled bit
	jp z, .end\@
	ld a, [GYAL_CH3_ENVS + GYAL_ENV_STRUCT_SIZE + GYAL_ENV_POS_L]
	ld l, a
	ld a, [GYAL_CH3_ENVS + GYAL_ENV_STRUCT_SIZE + GYAL_ENV_POS_H]
	ld h, a
	ld a, [GYAL_CH3_ENVS + GYAL_ENV_STRUCT_SIZE + GYAL_ENV_ENABLED]
	bit 6, a ;check loop mode
	jr z, .noloop\@
	bit 5, a ;this bit is set when end of stream reached
	jr z, .read\@
	ld a, [GYAL_CH3_ENVS + GYAL_ENV_STRUCT_SIZE + GYAL_ENV_REPEAT]
	or a
	jr z, .norepeat\@
	dec a
	ld [GYAL_CH3_ENVS + GYAL_ENV_STRUCT_SIZE + GYAL_ENV_REPEAT], a
	jr .out\@
.norepeat\@
	ld a, [GYAL_CH3_ENVS + GYAL_ENV_STRUCT_SIZE + GYAL_ENV_ENABLED]
	res 5, a
	ld [GYAL_CH3_ENVS + GYAL_ENV_STRUCT_SIZE + GYAL_ENV_ENABLED], a
	ld a, [GYAL_CH3_ENVS + GYAL_ENV_STRUCT_SIZE + GYAL_ENV_START_L]
	ld [GYAL_CH3_ENVS + GYAL_ENV_STRUCT_SIZE + GYAL_ENV_POS_L], a
	ld a, [GYAL_CH3_ENVS + GYAL_ENV_STRUCT_SIZE + GYAL_ENV_START_H]
	ld [GYAL_CH3_ENVS + GYAL_ENV_STRUCT_SIZE + GYAL_ENV_POS_H], a
	jr .read\@
.noloop\@
	ld a, [GYAL_OUT_FLAGS + GYAL_OUT_WAVE_H]
	or a
	jr z, .nonote\@
	ld a, [GYAL_OUT_BUF + GYAL_OUT_WAVE_H]
	bit 7, a
	jr z, .nonote\@
	ld a, [GYAL_CH3_ENVS + GYAL_ENV_STRUCT_SIZE + GYAL_ENV_START_L]
	ld l, a
	ld [GYAL_CH3_ENVS + GYAL_ENV_STRUCT_SIZE + GYAL_ENV_POS_L], a
	ld a, [GYAL_CH3_ENVS + GYAL_ENV_STRUCT_SIZE + GYAL_ENV_START_H]
	ld h, a
	ld [GYAL_CH3_ENVS + GYAL_ENV_STRUCT_SIZE + GYAL_ENV_POS_H], a
	ld a, [GYAL_CH3_ENVS + GYAL_ENV_STRUCT_SIZE + GYAL_ENV_ENABLED]
	res 5, a
	ld [GYAL_CH3_ENVS + GYAL_ENV_STRUCT_SIZE + GYAL_ENV_ENABLED], a
	jr .read\@
.nonote\@
	ld a, [GYAL_CH3_ENVS + GYAL_ENV_STRUCT_SIZE + GYAL_ENV_REPEAT]
	or a
	jr z, .noloopnorepeat\@
	dec a
	ld [GYAL_CH3_ENVS + GYAL_ENV_STRUCT_SIZE + GYAL_ENV_REPEAT], a
	jr .out\@
.noloopnorepeat\@
	ld a, [GYAL_CH3_ENVS + GYAL_ENV_STRUCT_SIZE + GYAL_ENV_ENABLED]
	bit 5, a ;this bit is set when end of stream reached
	jr z, .read\@
	jr .out\@ ;repeat last value
.read\@
	xor a
	ld [GYAL_CH3_ENVS + GYAL_ENV_STRUCT_SIZE + GYAL_ENV_REPEAT], a
	ld a, [HLI]
	ld b, a
	ld a, %01111111
	cp b
	jr z, .streamend\@
	bit 7, b
	jr z, .repeats\@
	ld a, b
	ld [GYAL_CH3_ENVS + GYAL_ENV_STRUCT_SIZE + GYAL_ENV_VALUE], a
	jr .out\@
.repeats\@
	ld a, %00111111
	and b
	ld [GYAL_CH3_ENVS + GYAL_ENV_STRUCT_SIZE + GYAL_ENV_REPEAT], a
	jp .out\@
.streamend\@
	ld a, [GYAL_CH3_ENVS + GYAL_ENV_STRUCT_SIZE + GYAL_ENV_ENABLED]
	set 5, a
	ld [GYAL_CH3_ENVS + GYAL_ENV_STRUCT_SIZE + GYAL_ENV_ENABLED], a
	jp .start\@
.out\@
	ld a, [GYAL_CH3_ENVS + GYAL_ENV_STRUCT_SIZE + GYAL_ENV_VALUE]
	swap a
	ld b, a
	ld a, %01100000
	and b
	ld [GYAL_OUT_BUF + GYAL_OUT_WAVE_V], a
	ld a, 1
	ld [GYAL_OUT_FLAGS + GYAL_OUT_WAVE_V], a
.savepos\@
	ld a, l
	ld [GYAL_CH3_ENVS + GYAL_ENV_STRUCT_SIZE + GYAL_ENV_POS_L], a
	ld a, h
	ld [GYAL_CH3_ENVS + GYAL_ENV_STRUCT_SIZE + GYAL_ENV_POS_H], a
.end\@
	ENDM
	
;1 - Register to be replaced
;2 - Flag to check
;3 - Replacement data
;4 - Jump point
;5 - 1 if wave high, 0 otherwise
;out - b = 1 if replaced, 0 if not
CheckChannel: MACRO
	ld a, \2
	or a
	jr z, .end\@
IF \5 == 1
	ld a, \3
	and %10000000
	jr z, .notrig\@
	xor a
	ld [rAUD3ENA], a
	ld a, \3
	ld \1, a
	ld a, %10000000
	ld [rAUD3ENA], a
.notrig\@
	ld a, \3
	ld \1, a
ELSE
	ld a, \3
	ld \1, a
ENDC	
	xor a
	ld \2, a
	ld b, 1
	jp \4
.end\@
	ld b, 0 
	ENDM
	
;1 - number of channel
;2 - original register
;3 - replacement register name
;4 - jump point
CheckSFXChannel: MACRO
	ld a, [GYAL_SFX_CHANNELS + (GYAL_SFX_STRUCT_SIZE * \1) + GYAL_SFX_ENABLED]
	or a
	jr z, .end\@
	CheckChannel [\2], [GYAL_SFX_CHANNELS + (GYAL_SFX_STRUCT_SIZE * \1) + GYAL_SFX_FLAGS + \3], [GYAL_SFX_CHANNELS + (GYAL_SFX_STRUCT_SIZE * \1) + GYAL_SFX_BUF + \3], \4, \2 == rAUD3HIGH
.end\@
	ENDM
	
;1 - original register
;2 - replacement register name
;3 - jump point
CheckAllSFX: MACRO
	CheckSFXChannel 0, \1, \2, \3
	CheckSFXChannel 1, \1, \2, \3
	CheckSFXChannel 2, \1, \2, \3
	CheckSFXChannel 3, \1, \2, \3
	ENDM