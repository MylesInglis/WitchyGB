INCLUDE "sprite.asm"
INCLUDE "scroll.asm"
INCLUDE "collision.asm"
INCLUDE "playerenemy.asm"
INCLUDE "input.asm"
INCLUDE "player.asm"
INCLUDE "enemy.asm"
INCLUDE "gyal.asm"
INCLUDE "lvl1data.asm"

SPRITE_DMA_RAM EQU $FF80

SECTION "Variables", BSS

VBLANK_FLAG: ds 1

SECTION "VBlank", HOME[$40]
	jp VBlankHandler

SECTION "Org $100", HOME[$100]

	nop
	jp	Begin

	ROM_HEADER	ROM_NOMBC, ROM_SIZE_32KBYTE, RAM_SIZE_0KBYTE
	
SECTION "Program Start", HOME
	
Begin:
	di
	ld	sp, $dfff	;init stack pointer
	call GyalInit
	ld hl, MusicStream
	call GyalMusicStart
	
	ld a, %11100100	;background palette
	ld [rBGP], a
	ld a, %00100111	;sprite palette
	ld [rOBP0], a
	ld [rOBP1], a
	
	xor a	;init scroll registers
	ld [rSCX], a
	ld [rSCY], a
	
	ld hl, SpriteDMAROM
	ld de, SPRITE_DMA_RAM
	ld bc, SpriteDMAROMEnd - SpriteDMAROM
	call mem_Copy
	
	ld hl, Tiles
	ld de, _VRAM
	ld bc, 16 * 142
	call mem_CopyVRAM
	
	ld a, 6
	ld hl, _SCRN0
	ld bc, 1024
	call mem_SetVRAM
	
	ld hl, TileMap
	ld a, 192
	call ScrollInit
	
	xor a
	ld hl, OAM_PLAYER
	ld bc, 40 * 4
	call mem_Set
	
	xor a
	ld [VBLANK_FLAG], a
	ei
	
	ld a, IEF_VBLANK
	ld [rIE], a
	
	ld a, LCDCF_ON | LCDCF_BG8000 | LCDCF_BGON | LCDCF_OBJ8 | LCDCF_OBJON
    ld [rLCDC], a

	call InputInit
	call PlayerInit
	call EnemyInitAll
	call SpriteInitAll
	
	PlayerIdleAnim
	ld a, 1
	ld [ENEMY1_VARS + ENEMY_ACTIVE], a
	ld a, ENEMY_ACTION_WALK_LEFT
	ld [ENEMY1_VARS + ENEMY_ACTION], a
	SpriteEnemyClear SPRITE_ENEMY1, OAM_ENEMY1
;	MonkIdleAnim SPRITE_ENEMY1, ENEMY1_ANIM
	
Main:
	halt
	nop
	
	ld a, [VBLANK_FLAG]
	or a 
	jr z, Main 
	xor a
	ld [VBLANK_FLAG], a
	
	call GetInput
	call HandleInput
	PlayerEnemyMove PLAYER_VARS, SPRITE_PLAYER, PLAYER, PLAYER_WALK_VEL
	call PlayerAnim
	call EnemyActAll
	call UpdateProjectiles
	call CameraFollow
	call SpriteAnimAll
	call SpriteUpdateAll
	call GyalUpdate
	
	ld a, [PLAYER_VARS + PLAYER_DEAD]
	or a
	jr nz, .restart
	
	jp Main
	
.restart
	jp Begin
	
SECTION "Subroutines", HOME

VBlankHandler:
	push af
	
	call SPRITE_DMA_RAM
	
	ld a, 1
	ld [VBLANK_FLAG], a
	
	pop af
	reti
	
SpriteDMAROM:
	ld a, OAM_PLAYER >> 8
	ld [rDMA], a
	ld a, $28
.wait
	dec a
	jr nz, .wait
	ret
SpriteDMAROMEnd:

