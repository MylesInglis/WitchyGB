PLAYER EQU 0
ENEMY EQU 1

; Struct of data common to players and enemies

PLAYER_ENEMY_STRUCT_SIZE EQU 5

PLAYER_ENEMY_YVEL EQU 0
PLAYER_ENEMY_XVEL EQU 1
PLAYER_ENEMY_GRAVITY_COUNTER EQU 2
PLAYER_ENEMY_ON_FLOOR EQU 3
PLAYER_ENEMY_DEAD EQU 4

; multiple names defined for convience

ENEMY_YVEL EQU 0
ENEMY_XVEL EQU 1
ENEMY_GRAVITY_COUNTER EQU 2
ENEMY_ON_FLOOR EQU 3
ENEMY_DEAD EQU 4

PLAYER_YVEL EQU 0
PLAYER_XVEL EQU 1
PLAYER_GRAVITY_COUNTER EQU 2
PLAYER_ON_FLOOR EQU 3
PLAYER_DEAD EQU 4

;1 - Player or enemy struct address
;2 - Metasprite address
;3 - 0 for player, 1 for enemy
;4 - Move speed
PlayerEnemyMove: MACRO
	ld a, [\1 + PLAYER_ENEMY_GRAVITY_COUNTER]
	inc a
	cp GRAVITY
	jr z, .gravity\@
	ld [\1 + PLAYER_ENEMY_GRAVITY_COUNTER], a
	jr .move\@
.gravity\@
	xor a
	ld [\1 + PLAYER_ENEMY_GRAVITY_COUNTER], a
	ld a, [\1 + PLAYER_ENEMY_YVEL]
	bit 7, a
	jr z, .positive\@
.negative\@
	dec a
	bit 7, a
	jr z, .zero\@
	jr .applygravity\@
.zero\@
	xor a
	jr .applygravity\@
.positive\@
	inc a
	cp TERMINAL_VEL
	jr c, .applygravity\@
	ld a, TERMINAL_VEL
.applygravity\@
	ld [\1 + PLAYER_ENEMY_YVEL], a
.move\@
	ld a, [\1 + PLAYER_ENEMY_YVEL]
	ld c, a
	ld a, [\1 + PLAYER_ENEMY_XVEL]
	ld b, a
	bit 7, b
	jr z, .right\@
.left\@
	ld a, [SCROLL_CURRENT_MAP_COLUMN]
	sub SCRN_VX_B
	or a
	jr nz, .noboundary\@
	ld a, [rSCX]
	or a
	jr nz, .noboundary\@
	ld a, [\2 + METASPRITE_X]
	cp \4 + 6
	jr nc, .noboundary\@
	xor a
	ld [\1 + PLAYER_ENEMY_XVEL], a
	ld b, a
	jr .noboundary\@
.right\@
	ld a, [SCROLL_MAP_SIZE]
	ld d, a
	ld a, [SCROLL_CURRENT_MAP_COLUMN]
	cp d
	jr nz, .noboundary\@
	ld a, [rSCX]
	cp ($FF - SCRN_X)
	jr c, .noboundary\@
	ld a, [\2 + METASPRITE_X]
	cp ($FF - \4 - 106)
	jr c, .noboundary\@
	xor a
	ld [\1 + PLAYER_ENEMY_XVEL], a
	ld b, a
.noboundary\@
	SpriteMove \2
	ld a, [\1 + PLAYER_ENEMY_YVEL]
	bit 7, a
	jr nz, .checkalive\@
	or a
	jr z, .checkalive\@
	ld a, [\2 + METASPRITE_X]
	add a, 4
	ld b, a
	ld a, [\2 + METASPRITE_Y]
	add a, 8
	ld c, a
	call CheckWorldCollision
	or a
	jr z, .inair\@
.stop\@
	ld a, [rSCY]
	ld b, a
	ld a, [\2 + METASPRITE_Y]
	add b
	ld d, a
	and %11111000 ;set to previous multiple of 8 in world pos
	ld e, a
	ld a, [\1 + PLAYER_ENEMY_ON_FLOOR]
	and a
	jr nz, .skip\@
	ld a, d ;make sure player collided this frame
	sub e
	ld d, a
	ld a, [\1 + PLAYER_ENEMY_YVEL]
	cp d
	jr c, .inair\@
.skip\@
	ld a, e
	sub b ;back to screen pos
	ld [\2 + METASPRITE_Y], a
	xor a
	ld [\1 + PLAYER_ENEMY_YVEL], a
	ld a, 1
	ld [\1 + PLAYER_ENEMY_ON_FLOOR], a
	jr .checkalive\@
.inair\@
	xor a
	ld [\1 + PLAYER_ENEMY_ON_FLOOR], a
.checkalive\@
	ld a, [\2 + METASPRITE_Y]
	cp SCRN_Y + 50
	jr nc, .dead\@
IF	\3 == 1
	ld a, [\2 + METASPRITE_X]
	cp SCRN_X + 30
	jr c, .end\@
	cp SCRN_X + 40
	jr nc, .end\@
ELSE
	jr .end\@
ENDC
.dead\@
	ld a, 1
	ld [\1 + PLAYER_ENEMY_DEAD], a
.end\@
	ENDM