import pygame

class Barrier(pygame.sprite.Sprite):
    def __init__(self, x, y, image, puzzle):
        super().__init__()
        self.image = image
        self.rect = self.image.get_rect(topleft=(x, y))
        self.puzzle = puzzle
        self.locked = True

    def interact(self, screen, font):
        """Show puzzle; unlock if solved."""
        solved = self.puzzle.ask(screen, font)
        if solved:
            self.locked = False
        return solved
