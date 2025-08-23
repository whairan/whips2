# scripts/obstacles.py
import pygame

def _door_with_border(base_img, border_color):
    surf = base_img.copy()
    pygame.draw.rect(surf, border_color, surf.get_rect(), width=4, border_radius=6)
    return surf

class Tree(pygame.sprite.Sprite):
    def __init__(self, x, y, image):
        super().__init__()
        self.image = image
        self.rect = self.image.get_rect(topleft=(x, y))

class Water(pygame.sprite.Sprite):
    def __init__(self, x, y, width, height):
        super().__init__()
        # transparent collider; lake visual is in the background image
        self.image = pygame.Surface((width, height), pygame.SRCALPHA)
        self.rect = self.image.get_rect(topleft=(x, y))

class Exit(pygame.sprite.Sprite):
    def __init__(self, x, y, width, height, image=None):
        super().__init__()
        if image is None:
            image = pygame.Surface((width, height), pygame.SRCALPHA)
            pygame.draw.rect(image, (222,184,135), (8,4,width-16,height-12))
            pygame.draw.rect(image, (139,69,19), image.get_rect(), width=2, border_radius=6)
        else:
            if image.get_size() != (width, height):
                image = pygame.transform.scale(image, (width, height))

        self.base_image = image
        self.image_locked = _door_with_border(self.base_image, (220, 50, 50))
        self.image_unlocked = _door_with_border(self.base_image, (40, 200, 80))
        self.locked = True
        self.image = self.image_locked
        self.rect = self.image.get_rect(topleft=(x, y))

    def unlock(self):
        self.locked = False
        self.image = self.image_unlocked

    def lock(self):
        self.locked = True
        self.image = self.image_locked