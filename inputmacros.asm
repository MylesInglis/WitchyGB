;1 - Check this number of tiles down for world collision
CheckBelowTile: MACRO
	ld a, [SPRITE_PLAYER + METASPRITE_X]
	add a, 4
	ld b, a
	ld a, [SPRITE_PLAYER + METASPRITE_Y]
	add a, 8 + (8 * \1)
	ld c, a
	call CheckWorldCollision
	or a
	jr z, .end\@
	jr .jumpdown
.end\@
	ENDM