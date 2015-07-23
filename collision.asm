;collidable tiles: 0 - 2, 15 - 18

FLOOR_TILE_MIN EQU 0
FLOOR_TILE_MAX EQU 2
LOG_TILE_MIN EQU 15
LOG_TILE_MAX EQU 18

SECTION "Collision Code", HOME

;in:  b - sprite x
;	  c - sprite y
;out: b - converted x
;	  c - converted y

SpritePosToBackgroundPos:
	ld a, [rSCX]
	add b
	ld b, a
	ld a, [rSCY]
	add c
	ld c, a
	ret
	
;in:  b - sprite x
;	  c - sprite y
;out: a - 1 for collision, 0 for no collision
;	  hl - address of tile

CheckWorldCollision:
	call SpritePosToBackgroundPos
	
	;get tile x - divide by 8, put in hl
	xor a
	ld h, a
	srl b
	srl b
	srl b
	ld l, b
	
	;get tile y - divide by 8, multiply by 32, put in de
	xor a
	ld d, a
	ld a, c
	and %11111000
	ld e, a
	xor a
	sla e
	adc a, d
	ld d, a
	xor a
	sla d
	sla e
	adc a, d
	ld d, a
	
	;add both together to get tile index
	add hl, de
	ld e, l
	ld d, h
	ld hl, _SCRN0
	add hl, de
	ld a, [HL]
	cp FLOOR_TILE_MIN
	jr c, .nofloor
	cp FLOOR_TILE_MAX + 1
	jr nc, .nofloor
.collision
	ld a, 1
	jr .end
.nofloor
	cp LOG_TILE_MIN
	jr c, .nocollision
	cp LOG_TILE_MAX + 1
	jr nc, .nocollision
	jr .collision
.nocollision
	xor a
.end
	ret
