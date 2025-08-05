# main.py

import pygame
import sys
from scripts.player import Player
from scripts.level import load_level

# Initialize
pygame.init()
WIDTH, HEIGHT = 960, 540
screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("Whips")
clock = pygame.time.Clock()
FPS = 60
font = pygame.font.SysFont(None, 36)

# helper to load images
def load_img(name):
    return pygame.image.load(f"assets/images/{name}").convert_alpha()

# load level (now with exit.image in your JSON)
bg, trees, barriers, exit_sprite = load_level(
    "levels/level1.json",
    image_loader=load_img,
    font=font
)
exit_group = pygame.sprite.GroupSingle(exit_sprite)

# player
player = Player(x=100, y=HEIGHT - 150)

puzzle_active = False
current_barrier = None

# game loop
while True:
    clock.tick(FPS)

    # input
    for ev in pygame.event.get():
        if ev.type == pygame.QUIT:
            pygame.quit()
            sys.exit()
        if not puzzle_active:
            player.handle_input(ev)

    # update
    if not puzzle_active:
        player.update()

        # undo on tree collision
        if pygame.sprite.spritecollideany(player, trees):
            player.undo_move()

        # barrier puzzle trigger
        hit = pygame.sprite.spritecollideany(player, barriers)
        if hit and hit.locked:
            puzzle_active = True
            current_barrier = hit

        # exit check
        elif pygame.sprite.spritecollideany(player, exit_group):
            print("Level Complete!")
            pygame.quit()
            sys.exit()

    else:
        # puzzle UI
        solved = current_barrier.interact(screen, font)
        if solved:
            barriers.remove(current_barrier)
        puzzle_active = False
        player.reset_move()

    # draw
    screen.blit(bg, (0, 0))
    trees.draw(screen)
    barriers.draw(screen)
    exit_group.draw(screen)
    player.draw(screen)
    pygame.display.flip()
