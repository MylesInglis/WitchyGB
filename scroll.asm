INCLUDE "MEMORY.ASM"

SCROLL_COUNT_MAX EQU 16

SECTION "Scroll Variables", BSS

SCROLL_MAP_SIZE : DS 1 ;in columns
SCROLL_MAP_POS : DS 2
SCROLL_MAP_POS_L : DS 2
SCROLL_SCREEN_POS : DS 2
SCROLL_SCREEN_POS_L : DS 2
SCROLL_CURRENT_COLUMN : DS 1
SCROLL_CURRENT_COLUMN_L : DS 1
SCROLL_CURRENT_MAP_COLUMN : DS 1
SCROLL_CURRENT_MAP_COLUMN_L : DS 1
SCROLL_COUNTER : DS 1
LOOP_COUNT: DS 2

SECTION "Scroll Code", HOME

LoadNextColumn:
	ld a, [SCROLL_MAP_POS]
	ld c, a
	ld a, [SCROLL_MAP_POS + 1]
	ld b, a
	xor a
	ld d, a
	ld a, SCRN_VY_B
	ld e, a
	ld [LOOP_COUNT], a
	ld a, [SCROLL_CURRENT_COLUMN]
	cp SCRN_VY_B - 1
	jr z, .lastcolumn
	inc a
	jr .loadscreenpos
.lastcolumn
	xor a
.loadscreenpos
	ld [SCROLL_CURRENT_COLUMN], a
	ld e, a
	xor a
	ld d, a
	ld hl, _SCRN0
	add hl, de
	xor a
	ld d, a
	ld a, SCRN_VY_B
	ld e, a
.loop
    di
    lcd_WaitVRAM
	ld a, [bc]
    ld [hl], a
    ei
	add hl, de
	inc bc
	ld a, [LOOP_COUNT]
	dec a
	jr z, .end
	ld [LOOP_COUNT], a
	jr .loop
.end
	ld a, c
	ld [SCROLL_MAP_POS], a
	ld a, b
	ld [SCROLL_MAP_POS + 1], a
	ld a, [SCROLL_CURRENT_MAP_COLUMN]
	inc a
	ld [SCROLL_CURRENT_MAP_COLUMN], a
	ret
	
LoadPreviousColumn:
	ld a, [SCROLL_MAP_POS]
	ld c, a
	ld a, [SCROLL_MAP_POS + 1]
	ld b, a
	ld de, (SCRN_VY_B * SCRN_VY_B) + SCRN_VY_B
	ld a, c
	sub e
	ld c, a
	ld a, b
	sbc a, d
	ld b, a
	xor a
	ld d, a
	ld a, SCRN_VY_B
	ld e, a
	ld [LOOP_COUNT], a
	ld a, [SCROLL_CURRENT_COLUMN]
	ld e, a
	xor a
	ld d, a
	ld hl, _SCRN0
	add hl, de
	xor a
	ld d, a
	ld a, SCRN_VY_B
	ld e, a
.loop
	di
    lcd_WaitVRAM
	ld a, [bc]
    ld [hl], a
    ei
	add hl, de
	inc bc
	ld a, [LOOP_COUNT]
	dec a
	jr z, .end
	ld [LOOP_COUNT], a
	jr .loop
.end
	ld a, [SCROLL_CURRENT_COLUMN]
	cp 0
	jr z, .columnzero
	dec a
	jr .loadscreenpos
.columnzero
	ld a, SCRN_VY_B - 1
.loadscreenpos
	ld [SCROLL_CURRENT_COLUMN], a
	ld a, [SCROLL_MAP_POS]
	ld c, a
	ld a, [SCROLL_MAP_POS + 1]
	ld b, a
	ld de, SCRN_VY_B
	ld a, c
	sub e
	ld [SCROLL_MAP_POS], a
	ld a, b
	sbc a, d
	ld [SCROLL_MAP_POS + 1], a
	ld a, [SCROLL_CURRENT_MAP_COLUMN]
	dec a
	ld [SCROLL_CURRENT_MAP_COLUMN], a
	ret

;initialise map
;in: HL - address of map
;    a - map size

ScrollInit:
    ld [SCROLL_MAP_SIZE], a
	xor a
	ld [SCROLL_COUNTER], a
	ld [SCROLL_CURRENT_MAP_COLUMN], a
	ld a, SCRN_VY_B - 1
	ld [SCROLL_CURRENT_COLUMN], a
	ld a, l
	ld [SCROLL_MAP_POS], a
	ld a, h
	ld [SCROLL_MAP_POS + 1], a
	ld hl, _SCRN0
	ld a, l
	ld [SCROLL_SCREEN_POS], a
	ld a, h
	ld [SCROLL_SCREEN_POS + 1], a
	ld a, 32
	ld [LOOP_COUNT + 1], a
.loop
	call LoadNextColumn
	ld a, [LOOP_COUNT + 1]
	dec a
	jr z, .end
	ld [LOOP_COUNT + 1], a
	jr .loop
.end
	ret
	
;in: d - x scroll
	
ScrollRight:
	ld a, [SCROLL_MAP_SIZE]
	ld b, a
	ld a, [SCROLL_CURRENT_MAP_COLUMN]
	cp b
	jr z, .lastColumn
	ld a, [rSCX]
	add d
	ld [rSCX], a
	ld a, d
	set 7, a
	ld b, a
	xor a
	ld c, a
	call SpriteMove
	ld a, [SCROLL_COUNTER]
	add d
	cp SCROLL_COUNT_MAX
	jr c, .cont
	jr .nextColumn
.cont
	ld [SCROLL_COUNTER], a
	jr .end
.nextColumn
	sub SCROLL_COUNT_MAX / 2
	ld [SCROLL_COUNTER], a
	call LoadNextColumn
	jr .end
.lastColumn
	ld a, [rSCX]
	cp ($FF - SCRN_X)
	jr c, .scroll
	jr .end
.scroll
	add d
	ld [rSCX], a
	ld a, d
	set 7, a
	ld b, a
	xor a
	ld c, a
	call SpriteMove
	ld a, [SCROLL_COUNTER]
	add d
	ld [SCROLL_COUNTER], a
.end
	ret

;in: d - x scroll
	
ScrollLeft:
	ld a, [SCROLL_CURRENT_MAP_COLUMN]
	sub SCRN_VX_B
	cp 0
	jr z, .firstColumn
	ld a, [rSCX]
	sub d
	ld [rSCX], a
	ld a, d
	ld b, a
	xor a
	ld c, a
	call SpriteMove
	ld a, [SCROLL_COUNTER]
	sub d
	cp 0
	jr z, .previousColumn
	bit 7, a ;check for wrap-around
	jr nz, .previousColumn
	ld [SCROLL_COUNTER], a
	jr .end
.previousColumn
	add SCROLL_COUNT_MAX / 2
	ld [SCROLL_COUNTER], a
	call LoadPreviousColumn
	jr .end
.firstColumn
	ld a, [rSCX]
	cp 0
	jr z, .end
.scroll
	sub d
	bit 7, a
	jr nz, .wraparound
	ld [rSCX], a
	ld a, d
	ld b, a
	xor a
	ld c, a
	call SpriteMove
	ld a, [SCROLL_COUNTER]
	sub d
	ld [SCROLL_COUNTER], a
.wraparound
	xor a
	ld [rSCX], a
	ld [SCROLL_COUNTER], a
.end
	ret
	
ScrollUp:
	ld a, [rSCY]
	cp 0
	jr z, .end
	dec a
	ld [rSCY], a
	ld a, 1
	ld c, a
	xor a
	ld b, a
	call SpriteMove
.end
	ret

ScrollDown:
	ld a, [rSCY]
	cp ($FF - SCRN_Y)
	jr c, .scroll
	jr .end
.scroll
	inc a
	ld [rSCY], a
	ld a, %10000001
	ld c, a
	xor a
	ld b, a
	call SpriteMove
.end
	ret
	
	
