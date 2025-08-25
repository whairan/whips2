# scripts/puzzles.py
import pygame, random, math

# ---------------- Scratch Pad ----------------
class ScratchPad:
    def __init__(self, size):
        self.size = size
        self.paper = pygame.Surface(size, pygame.SRCALPHA)
        self.ink   = pygame.Surface(size, pygame.SRCALPHA)
        self.active = False
        self.drawing = False
        self.erasing = False
        self.last_pos = None
        self.pen_width = 3
        self.eraser_width = 16
        self._make_paper()

    def _make_paper(self):
        """A faint grid to mimic paper."""
        self.paper.fill((0,0,0,0))
        grid = pygame.Surface(self.size, pygame.SRCALPHA)
        w, h = self.size
        # very faint background veil
        bgveil = pygame.Surface(self.size, pygame.SRCALPHA)
        bgveil.fill((255,255,255,18))
        self.paper.blit(bgveil, (0,0))
        # grid lines
        for x in range(0, w, 24):
            pygame.draw.line(grid, (40,40,40,35), (x,0), (x,h), 1)
        for y in range(0, h, 24):
            pygame.draw.line(grid, (40,40,40,35), (0,y), (w,y), 1)
        self.paper.blit(grid, (0,0))

    def toggle(self):
        self.active = not self.active

    def clear(self):
        self.ink.fill((0,0,0,0))

    def handle_event(self, ev):
        if not self.active:
            return
        if ev.type == pygame.MOUSEBUTTONDOWN:
            if ev.button == 1:   # left = draw
                self.drawing = True
                self.erasing = False
                self.last_pos = ev.pos
            elif ev.button == 3: # right = erase
                self.erasing = True
                self.drawing = False
                self.last_pos = ev.pos
        elif ev.type == pygame.MOUSEBUTTONUP:
            if ev.button in (1,3):
                self.drawing = False
                self.erasing = False
                self.last_pos = None
        elif ev.type == pygame.MOUSEMOTION:
            if (self.drawing or self.erasing) and self.last_pos is not None:
                now = ev.pos
                if self.drawing:
                    pygame.draw.line(self.ink, (20,20,20,255), self.last_pos, now, self.pen_width)
                else:
                    # erase by drawing transparent circle
                    pygame.draw.line(self.ink, (0,0,0,0), self.last_pos, now, self.eraser_width)
                self.last_pos = now
        elif ev.type == pygame.KEYDOWN:
            if ev.key == pygame.K_c:
                self.clear()

    def draw(self, surface):
        if not self.active: 
            return
        surface.blit(self.paper, (0,0))
        surface.blit(self.ink, (0,0))
        # hint strip
        hint_font = pygame.font.SysFont(None, 24)
        hint = hint_font.render("Scratch Pad: P toggle · C clear · LMB draw · RMB erase", True, (255,255,255))
        strip = pygame.Surface((hint.get_width()+16, hint.get_height()+10), pygame.SRCALPHA)
        strip.fill((0,0,0,120))
        surface.blit(strip, (10, 10))
        surface.blit(hint, (18, 14))


# ---------------- Arithmetic helpers ----------------
def _rand_operands(min_val=None, max_val=None, difficulty="easy"):
    if min_val is not None and max_val is not None:
        a = random.randint(min_val, max_val)
        b = random.randint(min_val, max_val)
        return a, b
    # fallback difficulty bands
    if difficulty == "easy":
        return random.randint(0, 12), random.randint(0, 12)
    if difficulty == "medium":
        return random.randint(10, 99), random.randint(10, 99)
    # hard
    return random.randint(50, 300), random.randint(50, 300)

def _gen_problem(ops, difficulty, min_val=None, max_val=None, allow_negative=False):
    """Return (question_text, correct_answer:int)."""
    op = random.choice(ops)
    a, b = _rand_operands(min_val, max_val, difficulty)

    if op == "add":
        return f"{a} + {b} = ?", a + b

    elif op == "sub":
        if not allow_negative and b > a:
            a, b = b, a
        return f"{a} - {b} = ?", a - b

    elif op == "mul":
        return f"{a} × {b} = ?", a * b

    elif op == "div":
        # choose answer and divisor, build dividend
        b = max(1, b)
        ans = a
        dividend = ans * b
        return f"{dividend} ÷ {b} = ?", ans

    # default to add
    return f"{a} + {b} = ?", a + b

def _panel(surface, size=(640, 300)):
    rect = surface.get_rect()
    box = pygame.Rect(0, 0, *size)
    box.center = rect.center
    # dim bg
    dim = pygame.Surface(surface.get_size(), pygame.SRCALPHA)
    dim.fill((0, 0, 0, 120))
    surface.blit(dim, (0, 0))
    pygame.draw.rect(surface, (250, 250, 250), box, border_radius=14)
    pygame.draw.rect(surface, (0, 0, 0), box, width=3, border_radius=14)
    return box


# ---------------- Puzzles ----------------
class MCArithmeticPuzzle:
    """
    Multiple-choice arithmetic.
    Click a choice or press number keys (1..N).
    Supports P to toggle scratch pad if enabled.
    Returns: {'done': True, 'correct': True, 'wrong_tries': int}
    """
    def __init__(self, ops=("add","sub"), difficulty="easy", choice_count=4,
                 min_val=None, max_val=None, allow_negative=False, enable_scratch=False):
        self.ops = list(ops)
        self.difficulty = difficulty
        self.choice_count = max(2, min(9, int(choice_count)))
        self.min_val = min_val
        self.max_val = max_val
        self.allow_negative = allow_negative
        self.enable_scratch = enable_scratch

        self.question = None
        self.answer = None
        self.wrong_tries = 0

    def _new_round(self):
        self.question, self.answer = _gen_problem(
            self.ops, self.difficulty, self.min_val, self.max_val, self.allow_negative
        )
        # build choices with unique distractors
        choices = {self.answer}
        span = max(5, (self.max_val or 30) // 4)
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

        # scratch pad
        pad = ScratchPad(screen.get_size())
        if self.enable_scratch:
            pad.toggle()  # start visible on levels that want it

        # layout
        box = _panel(screen)
        qsurf = font.render(self.question, True, (0, 0, 0))
        qpos = qsurf.get_rect(midtop=(box.centerx, box.top + 24))

        btns = []
        top = qpos.bottom + 16
        for i, val in enumerate(choices):
            r = pygame.Rect(0, 0, box.width - 80, 44)
            r.centerx = box.centerx
            r.top = top + i * 52
            btns.append((r, val))

        hint_font = pygame.font.SysFont(None, 22)
        hint = hint_font.render("Press number 1..9 to answer · P toggle scratch pad · C clear", True, (50, 50, 50))
        hint_pos = hint.get_rect(midtop=(box.centerx, box.bottom - 28))

        while True:
            clock.tick(60)
            for ev in pygame.event.get():
                if ev.type == pygame.QUIT:
                    pygame.quit(); raise SystemExit
                if ev.type == pygame.KEYDOWN:
                    if pygame.K_1 <= ev.key <= pygame.K_9:
                        k = ev.key - pygame.K_1
                        if k < len(btns):
                            selected_idx = k
                    elif ev.key == pygame.K_p and self.enable_scratch:
                        pad.toggle()
                    elif ev.key == pygame.K_ESCAPE:
                        pass
                if self.enable_scratch:
                    pad.handle_event(ev)
                if ev.type == pygame.MOUSEBUTTONDOWN and ev.button == 1:
                    for idx, (r, _) in enumerate(btns):
                        if r.collidepoint(ev.pos):
                            selected_idx = idx

            # redraw: world is underneath; draw scratch pad first if active
            if self.enable_scratch and pad.active:
                pad.draw(screen)
            _panel(screen)
            screen.blit(qsurf, qpos)
            mouse = pygame.mouse.get_pos()
            for i, (r, val) in enumerate(btns):
                hover = r.collidepoint(mouse)
                bg = (230, 230, 230) if hover else (245, 245, 245)
                pygame.draw.rect(screen, bg, r, border_radius=8)
                pygame.draw.rect(screen, (60, 60, 60), r, width=2, border_radius=8)
                lab = font.render(f"{i+1})  {val}", True, (0, 0, 0))
                screen.blit(lab, lab.get_rect(center=r.center))
            screen.blit(hint, hint_pos)
            pygame.display.flip()

            if selected_idx is not None:
                chosen = btns[selected_idx][1]
                if chosen == self.answer:
                    return {'done': True, 'correct': True, 'wrong_tries': self.wrong_tries}
                else:
                    self.wrong_tries += 1
                    selected_idx = None  # retry


class FreeResponseArithmeticPuzzle:
    """
    Type the numeric answer and press Enter.
    Supports P to toggle scratch pad if enabled.
    Returns: {'done': True, 'correct': True, 'wrong_tries': int}
    """
    def __init__(self, ops=("add","sub"), difficulty="medium",
                 min_val=None, max_val=None, allow_negative=False, enable_scratch=False):
        self.ops = list(ops)
        self.difficulty = difficulty
        self.min_val = min_val
        self.max_val = max_val
        self.allow_negative = allow_negative
        self.enable_scratch = enable_scratch

        self.question = None
        self.answer = None
        self.input_str = ""
        self.wrong_tries = 0

    def _new_round(self):
        self.question, self.answer = _gen_problem(
            self.ops, self.difficulty, self.min_val, self.max_val, self.allow_negative
        )
        self.input_str = ""

    def interact(self, screen, font):
        clock = pygame.time.Clock()
        self._new_round()

        pad = ScratchPad(screen.get_size())
        if self.enable_scratch:
            pad.toggle()

        box = _panel(screen)
        qsurf = font.render(self.question, True, (0, 0, 0))
        qpos = qsurf.get_rect(midtop=(box.centerx, box.top + 24))

        ibox = pygame.Rect(0, 0, box.width - 140, 54)
        ibox.centerx = box.centerx
        ibox.top = qpos.bottom + 32

        hint = "Type answer & Enter · Backspace edit · '-' for negative · P toggle scratch · C clear"
        hint_surf = pygame.font.SysFont(None, 22).render(hint, True, (50, 50, 50))
        hint_pos = hint_surf.get_rect(midtop=(box.centerx, ibox.bottom + 18))

        while True:
            clock.tick(60)
            for ev in pygame.event.get():
                if ev.type == pygame.QUIT:
                    pygame.quit(); raise SystemExit
                if ev.type == pygame.KEYDOWN:
                    if ev.key == pygame.K_RETURN:
                        if self.input_str.strip() in ("", "-", "+"):
                            pass
                        else:
                            try:
                                guess = int(self.input_str.strip())
                                if guess == self.answer:
                                    return {'done': True, 'correct': True, 'wrong_tries': self.wrong_tries}
                                else:
                                    self.wrong_tries += 1
                                    self.input_str = ""
                            except ValueError:
                                self.wrong_tries += 1
                                self.input_str = ""
                    elif ev.key == pygame.K_BACKSPACE:
                        self.input_str = self.input_str[:-1]
                    elif ev.key == pygame.K_MINUS:
                        if len(self.input_str) == 0:
                            self.input_str = "-" if self.allow_negative else self.input_str
                    elif ev.key == pygame.K_p and self.enable_scratch:
                        pad.toggle()
                    elif ev.unicode.isdigit():
                        self.input_str += ev.unicode
                    elif ev.key == pygame.K_ESCAPE:
                        pass
                if self.enable_scratch:
                    pad.handle_event(ev)

            if self.enable_scratch and pad.active:
                pad.draw(screen)
            _panel(screen)
            screen.blit(qsurf, qpos)

            pygame.draw.rect(screen, (255, 255, 255), ibox, border_radius=8)
            pygame.draw.rect(screen, (60, 60, 60), ibox, width=2, border_radius=8)
            txt = font.render(self.input_str or " ", True, (0, 0, 0))
            screen.blit(txt, txt.get_rect(center=ibox.center))

            screen.blit(hint_surf, hint_pos)
            pygame.display.flip()
