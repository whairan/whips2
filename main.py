import pygame
import sys
from scripts.player import Player

# Initialize game
pygame.init()

# Screen settings
WIDTH, HEIGHT = 960, 540
screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("Whips")

clock = pygame.time.Clock()
FPS = 60

# Load assets
# background = pygame.image.load("assets/images/forest_bg.png")
# background = pygame.transform.scale(background, (WIDTH, HEIGHT))

try:
    background = pygame.image.load("assets/images/forest_bg.png")
    background = pygame.transform.scale(background, (WIDTH, HEIGHT))
except:
    background = pygame.Surface((WIDTH, HEIGHT))
    background.fill((50, 70, 50))  # Forest green




# Player setup
player = Player(x=100, y=HEIGHT - 150)

# Game loop
running = True
while running:
    clock.tick(FPS)
    screen.blit(background, (0, 0))

    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False

    player.update()
    player.draw(screen)

    pygame.display.flip()

pygame.quit()
sys.exit()
