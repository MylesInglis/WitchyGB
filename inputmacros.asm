;1 - Check this number of tiles down for world collision
;2 - The sprite to check
;3 - Label to jump to if tile found
CheckBelowTile: MACRO
	ld a, [\2 + METASPRITE_X]
	add a, 4
	ld b, a
	ld a, [\2 + METASPRITE_Y]
	add a, 8 + (8 * \1)
	ld c, a
	call CheckWorldCollision
	or a
	jr z, .end\@
	jr \3
.end\@
	ENDM