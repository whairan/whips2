# scripts/player.py

import pygame

class Player(pygame.sprite.Sprite):
    def __init__(self, x, y):
        super().__init__()
        # Load player sprite or fall back to a white box
        try:
            self.image = pygame.image.load("assets/images/player.png").convert_alpha()
        except Exception:
            self.image = pygame.Surface((30, 50))
            self.image.fill((255, 255, 255))

        self.rect = self.image.get_rect(topleft=(x, y))
        self.speed = 5

        # track last position so we can undo on collisions
        self.prev_pos = self.rect.topleft

    def handle_input(self, event):
        # stub so main.py can call it without error
        pass

    def update(self):
        # record previous position
        self.prev_pos = self.rect.topleft

        keys = pygame.key.get_pressed()
        if keys[pygame.K_LEFT]:
            self.rect.x -= self.speed
        if keys[pygame.K_RIGHT]:
            self.rect.x += self.speed
        if keys[pygame.K_UP]:
            self.rect.y -= self.speed
        if keys[pygame.K_DOWN]:
            self.rect.y += self.speed

        # ── new clamp code ──
        screen_rect = pygame.display.get_surface().get_rect()
        self.rect.clamp_ip(screen_rect)


        

    def undo_move(self):
        """Revert to previous position (e.g. after hitting a wall)."""
        self.rect.topleft = self.prev_pos

    def reset_move(self):
        """Called when a puzzle pops up—to clear any residual movement."""
        # nothing needed here unless you add velocity logic
        pass

    def draw(self, surface):
        surface.blit(self.image, self.rect)
