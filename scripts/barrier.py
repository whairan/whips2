# scripts/barrier.py
import pygame

class Barrier(pygame.sprite.Sprite):
    def __init__(self, x, y, image, puzzle):
        super().__init__()
        self.image = image
        self.rect = self.image.get_rect(topleft=(x, y))
        self.puzzle = puzzle
        self.locked = True

    def interact(self, screen, font):
        """
        Opens a modal puzzle UI. Blocks until the player solves it.
        Returns: dict like {'done': True, 'correct': True, 'wrong_tries': N}
        """
        result = self.puzzle.interact(screen, font)
        if result and result.get("done") and result.get("correct"):
            self.locked = False
        return result
