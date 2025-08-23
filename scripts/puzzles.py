# scripts/puzzles.py
import pygame, random

# ---------- helpers ----------
def _rand_operands(difficulty):
    if difficulty == "easy":
        return random.randint(0, 10), random.randint(0, 10)
    if difficulty == "medium":
        return random.randint(5, 20), random.randint(5, 20)
    # hard
    return random.randint(10, 50), random.randint(10, 50)

def _gen_problem(ops, difficulty):
    """Return (question_text, correct_answer:int). ops is a list like ['add','sub','mul','div']."""
    op = random.choice(ops)
    a, b = _rand_operands(difficulty)

    if op == "add":
        return f"{a} + {b} = ?", a + b
    elif op == "sub":
        return f"{a} - {b} = ?", a - b
    elif op == "mul":
        return f"{a} × {b} = ?", a * b
    elif op == "div":
        # make it divide evenly
        b = max(1, b)
        ans = a
        prod = a * b
        return f"{prod} ÷ {b} = ?", ans
    # default to add
    return f"{a} + {b} = ?", a + b

def _panel(surface, size=(600, 280)):
    rect = surface.get_rect()
    box = pygame.Rect(0, 0, *size)
    box.center = rect.center
    # dim bg
    dim = pygame.Surface(surface.get_size(), pygame.SRCALPHA)
    dim.fill((0, 0, 0, 140))
    surface.blit(dim, (0, 0))
    pygame.draw.rect(surface, (250, 250, 250), box, border_radius=12)
    pygame.draw.rect(surface, (0, 0, 0), box, width=3, border_radius=12)
    return box

# ---------- Puzzles ----------
class MCArithmeticPuzzle:
    """
    Multiple-choice arithmetic. Click a choice or press number keys (1..N).
    interact() renders a modal UI and blocks until solved.
    Returns: {'done': True, 'correct': True, 'wrong_tries': int}
    """
    def __init__(self, ops=("add","sub"), difficulty="easy", choice_count=4):
        self.ops = list(ops)
        self.difficulty = difficulty
        self.choice_count = max(2, min(9, int(choice_count)))
        self.question = None
        self.answer = None
        self.wrong_tries = 0

    def _new_round(self):
        self.question, self.answer = _gen_problem(self.ops, self.difficulty)
        # build choices with unique distractors
        choices = {self.answer}
        span = 10 if self.difficulty == "easy" else (20 if self.difficulty == "medium" else 40)
        while len(choices) < self.choice_count:
            delta = random.randint(-span, span)
            if delta == 0: 
                continue
            choices.add(self.answer + delta)
        lst = list(choices)
        random.shuffle(lst)
        return lst

    def interact(self, screen, font):
        clock = pygame.time.Clock()
        choices = self._new_round()
        selected_idx = None

        # layout
        box = _panel(screen)
        qsurf = font.render(self.question, True, (0, 0, 0))
        qpos = qsurf.get_rect(midtop=(box.centerx, box.top + 24))

        # build choice rects
        btns = []
        top = qpos.bottom + 16
        for i, val in enumerate(choices):
            r = pygame.Rect(0, 0, box.width - 80, 40)
            r.centerx = box.centerx
            r.top = top + i * 48
            btns.append((r, val))

        while True:
            clock.tick(60)
            for ev in pygame.event.get():
                if ev.type == pygame.QUIT:
                    pygame.quit(); raise SystemExit
                if ev.type == pygame.KEYDOWN:
                    if pygame.K_1 <= ev.key <= pygame.K_9:
                        k = ev.key - pygame.K_1  # 0-based
                        if k < len(btns):
                            selected_idx = k
                    elif ev.key == pygame.K_ESCAPE:
                        # don’t exit game; just ignore
                        pass
                if ev.type == pygame.MOUSEBUTTONDOWN and ev.button == 1:
                    for idx, (r, _) in enumerate(btns):
                        if r.collidepoint(ev.pos):
                            selected_idx = idx

            # redraw panel each loop (overlay on top of your world)
            _panel(screen)  # redraw dim + panel
            screen.blit(qsurf, qpos)

            mouse = pygame.mouse.get_pos()
            for i, (r, val) in enumerate(btns):
                hover = r.collidepoint(mouse)
                bg = (230, 230, 230) if hover else (245, 245, 245)
                pygame.draw.rect(screen, bg, r, border_radius=8)
                pygame.draw.rect(screen, (60, 60, 60), r, width=2, border_radius=8)
                lab = font.render(f"{i+1})  {val}", True, (0, 0, 0))
                screen.blit(lab, lab.get_rect(center=r.center))

            pygame.display.flip()

            if selected_idx is not None:
                chosen = btns[selected_idx][1]
                if chosen == self.answer:
                    return {'done': True, 'correct': True, 'wrong_tries': self.wrong_tries}
                else:
                    self.wrong_tries += 1
                    selected_idx = None  # allow retry

class FreeResponseArithmeticPuzzle:
    """
    Type the numeric answer and press Enter. Supports minus and backspace.
    Returns: {'done': True, 'correct': True, 'wrong_tries': int}
    """
    def __init__(self, ops=("add","sub"), difficulty="medium"):
        self.ops = list(ops)
        self.difficulty = difficulty
        self.question = None
        self.answer = None
        self.input_str = ""
        self.wrong_tries = 0

    def _new_round(self):
        self.question, self.answer = _gen_problem(self.ops, self.difficulty)
        self.input_str = ""

    def interact(self, screen, font):
        clock = pygame.time.Clock()
        self._new_round()

        box = _panel(screen)
        qsurf = font.render(self.question, True, (0, 0, 0))
        qpos = qsurf.get_rect(midtop=(box.centerx, box.top + 24))

        # input box
        ibox = pygame.Rect(0, 0, box.width - 140, 50)
        ibox.centerx = box.centerx
        ibox.top = qpos.bottom + 32

        hint = "Type your answer and press Enter"
        hint_surf = pygame.font.SysFont(None, 24).render(hint, True, (40, 40, 40))
        hint_pos = hint_surf.get_rect(midtop=(box.centerx, ibox.bottom + 18))

        while True:
            clock.tick(60)
            for ev in pygame.event.get():
                if ev.type == pygame.QUIT:
                    pygame.quit(); raise SystemExit
                if ev.type == pygame.KEYDOWN:
                    if ev.key == pygame.K_RETURN:
                        if self.input_str.strip() in ("", "-", "+"):
                            # ignore empty
                            pass
                        else:
                            try:
                                guess = int(self.input_str.strip())
                                if guess == self.answer:
                                    return {'done': True, 'correct': True, 'wrong_tries': self.wrong_tries}
                                else:
                                    self.wrong_tries += 1
                                    self.input_str = ""  # clear for retry
                            except ValueError:
                                self.wrong_tries += 1
                                self.input_str = ""
                    elif ev.key == pygame.K_BACKSPACE:
                        self.input_str = self.input_str[:-1]
                    elif ev.key == pygame.K_MINUS:
                        if len(self.input_str) == 0:
                            self.input_str = "-"
                    elif ev.unicode.isdigit():
                        self.input_str += ev.unicode
                    elif ev.key == pygame.K_ESCAPE:
                        pass

            # draw UI
            _panel(screen)
            screen.blit(qsurf, qpos)

            pygame.draw.rect(screen, (255, 255, 255), ibox, border_radius=8)
            pygame.draw.rect(screen, (60, 60, 60), ibox, width=2, border_radius=8)
            txt = font.render(self.input_str or " ", True, (0, 0, 0))
            screen.blit(txt, txt.get_rect(center=ibox.center))

            screen.blit(hint_surf, hint_pos)

            pygame.display.flip()
