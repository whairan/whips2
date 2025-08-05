import pygame
import sys

class Puzzle:
    def ask(self, screen, font):
        """Override in subclasses; return True if solved."""
        raise NotImplementedError

class MathPuzzle(Puzzle):
    def __init__(self, question, answer):
        self.question = question
        self.answer = str(answer)

    def ask(self, screen, font):
        user_text = ""
        active = True
        clock = pygame.time.Clock()
        while active:
            clock.tick(30)
            screen.fill((20, 20, 20))
            # render question + entry
            q_surf = font.render(self.question, True, (255, 255, 255))
            e_surf = font.render(user_text, True, (255, 200, 0))
            screen.blit(q_surf, (50, 200))
            screen.blit(e_surf, (50, 240))
            pygame.display.flip()

            for ev in pygame.event.get():
                if ev.type == pygame.QUIT:
                    pygame.quit(); sys.exit()
                if ev.type == pygame.KEYDOWN:
                    if ev.key == pygame.K_RETURN:
                        return user_text == self.answer
                    elif ev.key == pygame.K_BACKSPACE:
                        user_text = user_text[:-1]
                    elif ev.unicode.isprintable():
                        user_text += ev.unicode
