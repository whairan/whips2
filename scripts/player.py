# scripts/player.py
import pygame

class Player(pygame.sprite.Sprite):
    def __init__(self, x, y):
        super().__init__()

        # Try to load a sprite; fall back to a simple rectangle
        try:
            img = pygame.image.load("assets/images/player.png").convert_alpha()
        except Exception:
            img = pygame.Surface((30, 50), pygame.SRCALPHA)
            img.fill((255, 255, 255))  # white placeholder

        self.image = img
        self.rect = self.image.get_rect(topleft=(x, y))

        # movement
        self.speed = 5
        self._dx = 0
        self._dy = 0

        # for undo_move()
        self._prev_pos = self.rect.topleft

    def handle_input(self, event):
        if event.type == pygame.KEYDOWN:
            if event.key in (pygame.K_LEFT, pygame.K_a):
                self._dx = -self.speed
            elif event.key in (pygame.K_RIGHT, pygame.K_d):
                self._dx = self.speed
            elif event.key in (pygame.K_UP, pygame.K_w):
                self._dy = -self.speed
            elif event.key in (pygame.K_DOWN, pygame.K_s):
                self._dy = self.speed

        elif event.type == pygame.KEYUP:
            if event.key in (pygame.K_LEFT, pygame.K_a) and self._dx < 0:
                self._dx = 0
            elif event.key in (pygame.K_RIGHT, pygame.K_d) and self._dx > 0:
                self._dx = 0
            elif event.key in (pygame.K_UP, pygame.K_w) and self._dy < 0:
                self._dy = 0
            elif event.key in (pygame.K_DOWN, pygame.K_s) and self._dy > 0:
                self._dy = 0

    def update(self):
        # remember last position so we can undo on collision
        self._prev_pos = self.rect.topleft

        # move
        self.rect.x += self._dx
        self.rect.y += self._dy

        # clamp to screen
        surf = pygame.display.get_surface()
        if surf:
            self.rect.clamp_ip(surf.get_rect())

    def undo_move(self):
        self.rect.topleft = self._prev_pos

    def reset_move(self):
        self._dx = 0
        self._dy = 0

    def draw(self, surface):
        surface.blit(self.image, self.rect)
