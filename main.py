# main.py
import pygame, sys, os
from scripts.player import Player
from scripts.level import load_level

pygame.init()
WIDTH, HEIGHT = 960, 540
screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("Whips")
clock = pygame.time.Clock()
FPS = 60
font = pygame.font.SysFont(None, 36)

# List your levels in order (create level2.json / level3.json as shown below)
LEVEL_FILES = [
    "levels/level1.json",
    "levels/level2.json",
    "levels/level3.json",
]

def load_img(name):
    path = os.path.join("assets", "images", name)
    surf = pygame.image.load(path)
    return surf.convert_alpha() if surf.get_alpha() is not None else surf.convert()

def draw_hud(surface, stats, level_idx, total_puzzles, remaining):
    # simple HUD top-left
    pad = 8
    text = f"Level {level_idx+1}  |  Solved: {stats['puzzles_solved']}/{stats['puzzles_attempted']}  |  Correct: {stats['correct']}  Wrong: {stats['wrong']}"
    hud = pygame.font.SysFont(None, 28).render(text, True, (255, 255, 255))
    bg_rect = pygame.Rect(0, 0, hud.get_width()+pad*2, hud.get_height()+pad*2)
    s = pygame.Surface(bg_rect.size, pygame.SRCALPHA)
    s.fill((0, 0, 0, 140))
    surface.blit(s, (0, 0))
    surface.blit(hud, (pad, pad))

def ensure_safe_spawn(plr, trees, barriers):
    blocked = pygame.sprite.spritecollideany(plr, trees) or pygame.sprite.spritecollideany(plr, barriers)
    if not blocked:
        return
    for y in range(40, HEIGHT - 72, 8):
        for x in range(40, WIDTH - 40, 8):
            plr.rect.topleft = (x, y)
            if not pygame.sprite.spritecollideany(plr, trees) and not pygame.sprite.spritecollideany(plr, barriers):
                return
    print("Warning: could not find a safe spawn area")

# --------- level management ---------
def load_world(level_path):
    bg, trees, barriers, exit_sprite = load_level(level_path, image_loader=load_img, font=font)
    exit_group = pygame.sprite.GroupSingle(exit_sprite)
    return bg, trees, barriers, exit_sprite, exit_group

current_level = 0
bg, trees, barriers, exit_sprite, exit_group = load_world(LEVEL_FILES[current_level])

player = Player(x=100, y=HEIGHT - 150)
ensure_safe_spawn(player, trees, barriers)

# lock/unlock exit per level
if len(barriers) == 0 and getattr(exit_sprite, "locked", True):
    exit_sprite.unlock()

# stats across the run
stats = {
    'puzzles_attempted': 0,
    'puzzles_solved': 0,
    'correct': 0,
    'wrong': 0,
}

puzzle_active = False
current_barrier = None
level_total_puzzles = len(barriers)

def advance_level():
    global current_level, bg, trees, barriers, exit_sprite, exit_group, level_total_puzzles, puzzle_active, current_barrier
    current_level += 1
    if current_level >= len(LEVEL_FILES):
        print("🎉 All levels complete!")
        pygame.quit(); sys.exit()
    bg, trees, barriers, exit_sprite, exit_group = load_world(LEVEL_FILES[current_level])
    level_total_puzzles = len(barriers)
    player.rect.topleft = (100, HEIGHT - 150)
    ensure_safe_spawn(player, trees, barriers)
    puzzle_active = False
    current_barrier = None
    if len(barriers) == 0 and getattr(exit_sprite, "locked", True):
        exit_sprite.unlock()

while True:
    clock.tick(FPS)

    # events (only feed to player when NOT in puzzle)
    for ev in pygame.event.get():
        if ev.type == pygame.QUIT:
            pygame.quit(); sys.exit()
        if not puzzle_active:
            player.handle_input(ev)

    if not puzzle_active:
        player.update()

        # collide with trees/water/walls
        if pygame.sprite.spritecollideany(player, trees):
            player.undo_move()

        # barrier trigger
        hit = pygame.sprite.spritecollideany(player, barriers)
        if hit and hit.locked:
            puzzle_active = True
            current_barrier = hit

        else:
            # reached exit?
            at_exit = pygame.sprite.spritecollideany(player, exit_group)
            if at_exit and not getattr(exit_sprite, "locked", True):
                advance_level()

    else:
        # modal puzzle UI (blocks until solved), returns stats
        result = current_barrier.interact(screen, font)
        # update score
        if result and result.get('done'):
            stats['puzzles_attempted'] += 1
            stats['wrong'] += result.get('wrong_tries', 0)
            if result.get('correct'):
                stats['correct'] += 1
                stats['puzzles_solved'] += 1
                barriers.remove(current_barrier)
                if len(barriers) == 0 and getattr(exit_sprite, "locked", True):
                    exit_sprite.unlock()
        puzzle_active = False
        player.reset_move()

    # draw world
    screen.blit(bg, (0, 0))
    trees.draw(screen)
    barriers.draw(screen)
    exit_group.draw(screen)
    player.draw(screen)

    # HUD
    draw_hud(screen, stats, current_level, level_total_puzzles, len(barriers))

    pygame.display.flip()
