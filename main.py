# main.py
import pygame, sys, os
from scripts.player import Player
from scripts.level import load_level
import math  # for pulsing text

# colors for the summary lines
METRIC_BLUE  = ( 80, 180, 255)
METRIC_GREEN = ( 80, 220, 120)
METRIC_RED   = (250,  90,  90)
WHITE        = (255, 255, 255)
BLACK        = (  0,   0,   0)


pygame.init()
WIDTH, HEIGHT = 960, 540
screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("Whips")
clock = pygame.time.Clock()
FPS = 60
font = pygame.font.SysFont(None, 36)

# List your levels in order
LEVEL_FILES = [
    "levels/level1.json",
    "levels/level2.json",
    "levels/level3.json",
]

def load_img(name):
    path = os.path.join("assets", "images", name)
    surf = pygame.image.load(path)
    return surf.convert_alpha() if surf.get_alpha() is not None else surf.convert()

def draw_hud(surface, stats, level_idx):
    pad = 8
    text = (f"Level {level_idx+1}  |  "
            f"Solved: {stats['puzzles_solved']}/{stats['puzzles_attempted']}  |  "
            f"Correct: {stats['correct']}  Wrong: {stats['wrong']}")
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

# ---------- end-of-level summary ----------
def stats_copy(s):  # shallow copy
    return {k: int(v) for k, v in s.items()}

def stats_delta(start, now):
    return {k: int(now.get(k, 0) - start.get(k, 0)) for k in now.keys()}

def pct(n, d):
    return int(round((100.0 * n) / d)) if d > 0 else 0

def show_level_summary(surface, font, level_idx, level_delta, cumulative):
    """
    Draw a colorful, fullscreen summary on top of the current game frame.
    Advance on Enter/Space/mouse click.
    """
    # snapshot current frame so we can redraw it each loop
    bg_snapshot = surface.copy()

    # fonts
    title_font  = pygame.font.SysFont(None, 72)
    metric_font = pygame.font.SysFont(None, 40)
    hint_font   = pygame.font.SysFont(None, 44, bold=True)

    # pull numbers
    L_att = level_delta['puzzles_attempted']
    L_sol = level_delta['puzzles_solved']
    L_cor = level_delta['correct']
    L_wrg = level_delta['wrong']
    L_acc = int(round(100 * (L_cor / L_att), 0)) if L_att > 0 else 0

    # you can also show cumulative totals if you want; we’ll keep this focused on the level
    lines = [
        (f"Attempted: {L_att}", METRIC_BLUE),
        (f"Solved:    {L_sol}", METRIC_GREEN),
        (f"Correct:   {L_cor}", METRIC_GREEN),
        (f"Wrong:     {L_wrg}", METRIC_RED),
        (f"Accuracy:  {L_acc}%", METRIC_BLUE),
    ]

    title = f"Level {level_idx + 1} Complete!"
    hint_text = "Press Enter / Space to continue"

    clock = pygame.time.Clock()

    def blit_center_text(text, fnt, color, y, shadow=True):
        surf = fnt.render(text, True, color)
        rect = surf.get_rect(center=(surface.get_width() // 2, y))
        if shadow:
            # simple drop shadow
            sh = fnt.render(text, True, BLACK)
            surface.blit(sh, rect.move(2, 2))
        surface.blit(surf, rect)

    base_y = surface.get_height() * 0.30
    line_gap = 46

    while True:
        clock.tick(60)
        for ev in pygame.event.get():
            if ev.type == pygame.QUIT:
                pygame.quit(); sys.exit()
            if ev.type == pygame.KEYDOWN and ev.key in (pygame.K_RETURN, pygame.K_SPACE):
                return
            if ev.type == pygame.MOUSEBUTTONDOWN and ev.button == 1:
                return

        # redraw scene
        surface.blit(bg_snapshot, (0, 0))

        # title
        blit_center_text(title, title_font, WHITE, base_y - 60)

        # metrics
        y = base_y
        for txt, col in lines:
            blit_center_text(txt, metric_font, col, y)
            y += line_gap

        # pulsing hint in white
        t = pygame.time.get_ticks() * 0.002  # seconds * speed
        intensity = int(200 + 55 * (0.5 + 0.5 * math.sin(t * 2.2)))
        pulsing_white = (intensity, intensity, intensity)
        blit_center_text(hint_text, hint_font, pulsing_white, y + 30)

        pygame.display.flip()


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

# cumulative stats
stats = {
    'puzzles_attempted': 0,
    'puzzles_solved':    0,
    'correct':           0,
    'wrong':             0,
}
# snapshot at level start (to compute per-level delta)
level_start_stats = stats_copy(stats)

puzzle_active = False
current_barrier = None

def advance_level():
    global current_level, bg, trees, barriers, exit_sprite, exit_group, puzzle_active, current_barrier, level_start_stats
    current_level += 1
    if current_level >= len(LEVEL_FILES):
        # Final summary, then quit
        final_delta = stats_delta(level_start_stats, stats)
        # Draw world one last time so the panel sits above it
        screen.blit(bg, (0, 0)); trees.draw(screen); barriers.draw(screen); exit_group.draw(screen); player.draw(screen)
        show_level_summary(screen, font, current_level-1, final_delta, stats)
        print("🎉 All levels complete!")
        pygame.quit(); sys.exit()

    bg, trees, barriers, exit_sprite, exit_group = load_world(LEVEL_FILES[current_level])
    player.rect.topleft = (100, HEIGHT - 150)
    ensure_safe_spawn(player, trees, barriers)
    puzzle_active = False
    current_barrier = None
    if len(barriers) == 0 and getattr(exit_sprite, "locked", True):
        exit_sprite.unlock()
    # new snapshot for the next level
    level_start_stats = stats_copy(stats)

def reset_input_state():
    # stop the player and clear any pending key events
    player.reset_move()
    pygame.event.clear()


while True:
    clock.tick(FPS)

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
                # draw world once so the summary can overlay it
                screen.blit(bg, (0, 0)); trees.draw(screen); barriers.draw(screen); exit_group.draw(screen); player.draw(screen)
                # show summary for THIS level
                level_delta = stats_delta(level_start_stats, stats)
                show_level_summary(screen, font, current_level, level_delta, stats)
                # then move on
                advance_level()

    else:
        # modal puzzle UI (blocks until solved), returns stats
        result = current_barrier.interact(screen, font)
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

    # HUD (live totals)
    draw_hud(screen, stats, current_level)

    pygame.display.flip()
