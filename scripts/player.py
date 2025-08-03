import pygame

class Player:
    def __init__(self, x, y):
        # self.image = pygame.image.load("assets/images/player.png")

        try:
            self.image = pygame.image.load("assets/images/player.png")
        except:
            self.image = pygame.Surface((30, 50))
            self.image.fill((255, 255, 255))  # White box as placeholder

        self.rect = self.image.get_rect(topleft=(x, y))
        self.velocity = pygame.math.Vector2(0, 0)
        self.speed = 5



    def update(self):
        keys = pygame.key.get_pressed()
        if keys[pygame.K_LEFT]:
            self.rect.x -= self.speed
        if keys[pygame.K_RIGHT]:
            self.rect.x += self.speed
        if keys[pygame.K_UP]:
            self.rect.y -= self.speed
        if keys[pygame.K_DOWN]:
            self.rect.y += self.speed

    def draw(self, surface):
        surface.blit(self.image, self.rect)
