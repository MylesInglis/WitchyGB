;1 - Projectile current life
;2 - Firing character metasprite
;3 - Projectile metasprite
;4 - Projectile left anim macro
;5 - Projectile right anim macro
;in: b - Projectile total life
SpawnProjectile: MACRO
	ld a, b
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

;1 - Projectile 1 current life
;2 - Projectile 2 current life
;3 - Firing character metasprite
;4 - Projectile 1 metasprite
;5 - Projectile 2 metasprite
;6 - Proj 1 left anim macro
;7 - Proj 1 right anim macro
;8 - Proj 2 left anim macro
;9 - Proj 2 right anim macro
;in: b - Projectile total life
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
	
;1 - Projectile 1 life
;2 - Projectile 1 anim
;3 - Projectile 2 anim
;4 - Projectile 1 metasprite
;5 - Projectile 2 metasprite
;6 - Projectile speed
;7 - Projectile 2 life
UpdateProjectiles: MACRO
	ld a, [\1]
	or a
	jr z, .killproj1\@
	xor a
	ld c, a
	ld a, [\2 + ANIM_ID]
	cp PLAYER_PROJECTILE_ANIM_LEFT
	jr z, .proj1left\@
	ld a, \6
	ld b, a
	jr .move1\@
.proj1left\@
	ld a, \6
	set 7, a
	ld b, a
.move1\@
	SpriteMove \4
	ld a, [\1]
	dec a
	ld [\1], a
	jr .proj2\@
.killproj1\@
	xor a
	ld [\4 + METASPRITE_Y], a
.proj2\@
	ld a, [\7]
	or a
	jr z, .killproj2\@
	xor a
	ld c, a
	ld a, [\3 + ANIM_ID]
	cp PLAYER_PROJECTILE_ANIM_LEFT
	jr z, .proj2left\@
	ld a, \6
	ld b, a
	jr .move2\@
.proj2left\@
	ld a, \6
	set 7, a
	ld b, a
.move2\@
	SpriteMove \5
	ld a, [\7]
	dec a
	ld [\7], a
	jr .end\@
.killproj2\@
	xor a
	ld [\5 + METASPRITE_Y], a
.end\@
	ENDM