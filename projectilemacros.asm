;1 - Projectile life
;2 - Firing character metasprite
;3 - Projectile metasprite
;4 - Projectile left anim macro
;5 - Projectile right anim macro
SpawnProjectile: MACRO
	ld a, PROJECTILE_LIFE
	ld [\1], a
	ld a, [\2 + METASPRITE_Y]
	add a, 11
	ld [\3 + METASPRITE_Y], a
	ld a, [\2 + METASPRITE_ATR]
	or a
	jr z, .right\@
	\4
	ld a, [\2 + METASPRITE_X]
	sub a, 4
	ld [\3 + METASPRITE_X], a
	jp .end\@
.right\@
	\5
	ld a, [\2 + METASPRITE_X]
	add a, 20
	ld [\3 + METASPRITE_X], a
.end\@
	ENDM

;1 - Projectile 1 life
;2 - Projectile 2 life
;3 - Firing character metasprite
;4 - Projectile 1 metasprite
;5 - Projectile 2 metasprite
;6 - Proj 1 left anim macro
;7 - Proj 1 right anim macro
;8 - Proj 2 left anim macro
;9 - Proj 2 right anim macro
;out: a - 0 if projectile was fired 
FireProjectile: MACRO
	ld a, [\1]
	or a
	jr z, .spawnproj1\@
	ld a, [\2]
	or a
	jp z, .spawnproj2\@
	jp .nofire\@
.spawnproj1\@
	SpawnProjectile \1, \3, \4, \6, \7
	jp .end\@
.spawnproj2\@
	SpawnProjectile \2, \3, \5, \8, \9
.end\@
	xor a
.nofire\@
	ENDM