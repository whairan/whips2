# generate_assets.py
from PIL import Image, ImageDraw
import random, math, os

W, H = 960, 540
os.makedirs("assets/images", exist_ok=True)

# ---------- helpers ----------
def lerp(a, b, t): return int(a + (b - a) * t)

def noisy_ellipse_points(cx, cy, rx, ry, points=140, amp=0.12, freq=3.5):
    """Return a list of (x,y) forming an irregular ellipse polygon."""
    res = []
    # multi-wave noise for organic edge
    p1, p2 = random.random()*math.pi*2, random.random()*math.pi*2
    p3 = random.random()*math.pi*2
    for i in range(points):
        a = (i / points) * math.tau
        # base radius modulation (clamped positive)
        n = (math.sin(a*freq + p1) + 0.6*math.sin(a*(freq*0.5) + p2) +
             0.3*math.sin(a*(freq*1.7) + p3)) * 0.5
        rxf = max(0.85, 1 + amp * n)
        ryf = max(0.85, 1 + amp * n)
        x = cx + rx * rxf * math.cos(a)
        y = cy + ry * ryf * math.sin(a)
        res.append((int(x), int(y)))
    return res

# ---------- Background: grass ----------
bg = Image.new("RGB", (W, H), color=(78, 112, 66))
draw = ImageDraw.Draw(bg)
for _ in range(4500):
    x = random.randrange(0, W); y = random.randrange(0, H)
    draw.point((x, y), fill=random.choice([(90,126,78),(72,104,62),(84,118,72)]))

# ---------- Lake (irregular + gradient) ----------
lake_x, lake_y, lake_w, lake_h = 490, 220, 300, 180
cx, cy = lake_x + lake_w/2, lake_y + lake_h/2
rx, ry = lake_w/2, lake_h/2

# outer irregular shoreline polygon
shore_poly = noisy_ellipse_points(cx, cy, rx, ry, points=160, amp=0.10, freq=3.2)
# fill shoreline ring
draw.polygon(shore_poly, fill=(140, 185, 200))

# inner water gradient via multiple inset polygons
layers = 16
for i in range(layers):
    t = i / (layers - 1)
    # shrink radii for inner layer
    rxi = rx * (1 - 0.06 - 0.5 * t)
    ryi = ry * (1 - 0.06 - 0.5 * t)
    # add gentler noise inside
    poly = noisy_ellipse_points(cx, cy, rxi, ryi, points=120, amp=0.05*(1-t), freq=2.6)
    # depth color: lighter near shore -> darker center
    col = (
        lerp(120, 50, t),   # R
        lerp(165, 100, t),  # G
        lerp(190, 155, t)   # B
    )
    draw.polygon(poly, fill=col)

# subtle highlights (sparkles)
for _ in range(140):
    x = random.randint(lake_x+12, lake_x+lake_w-12)
    y = random.randint(lake_y+12, lake_y+lake_h-12)
    if ( (x-cx)**2 / (rx*rx) + (y-cy)**2 / (ry*ry) ) <= 1.0:
        draw.point((x, y), fill=(210, 235, 245))

# ---------- Castle walls (baked, high-contrast) ----------
TH = 32  # visual thickness—match your EDGE_THICK colliders
stone  = (95, 95, 95)
mortar = (45, 45, 45)
crenel = (135, 135, 135)
shadow = (0, 0, 0)

# solid bands
draw.rectangle([0, 0, W, TH], fill=stone)                    # top
draw.rectangle([0, H-TH, W, H], fill=stone)                  # bottom
draw.rectangle([0, 0, TH, H], fill=stone)                    # left
draw.rectangle([W-TH, 0, W, H], fill=stone)                  # right

# inner drop shadow fade to make walls pop on grass
draw.rectangle([TH, TH-6, W-TH, TH+6], fill=(0,0,0,))        # under top
draw.rectangle([TH, H-TH-6, W-TH, H-TH+6], fill=(0,0,0,))    # above bottom
draw.rectangle([TH-6, TH, TH+6, H-TH], fill=(0,0,0,))        # right of left
draw.rectangle([W-TH-6, TH, W-TH+6, H-TH], fill=(0,0,0,))    # left of right

# block pattern lines
for x in range(0, W, 28):
    draw.line([(x, 0), (x, TH)], fill=mortar, width=2)
    draw.line([(x, H-TH), (x, H)], fill=mortar, width=2)
for y in range(0, H, 20):
    draw.line([(0, y), (TH, y)], fill=mortar, width=2)
    draw.line([(W-TH, y), (W, y)], fill=mortar, width=2)

# crenellations top & bottom
MER_W, MER_H, GAP = 26, 14, 14
x = TH
while x < W-TH:
    draw.rectangle([x, 0, min(x+MER_W, W-TH), MER_H], fill=crenel)
    draw.rectangle([x, H-MER_H, min(x+MER_W, W-TH), H], fill=crenel)
    x += MER_W + GAP

bg.save("assets/images/forest_bg.png")

# ---------- Sprites ----------
# player
player = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
d2 = ImageDraw.Draw(player)
d2.ellipse([12, 4, 20, 12], outline="black", fill="white")
d2.line([16, 12, 16, 24], fill="black", width=2)
d2.line([16, 14, 8, 20], fill="black", width=2); d2.line([16, 14, 24, 20], fill="black", width=2)
d2.line([16, 24, 8, 30], fill="black", width=2); d2.line([16, 24, 24, 30], fill="black", width=2)
player.save("assets/images/player.png")

# tree
tree = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
d3 = ImageDraw.Draw(tree)
d3.rectangle([14, 20, 18, 32], fill=(139, 69, 19))
d3.ellipse([2, 4, 30, 24], fill=(34, 139, 34), outline=(0, 100, 0))
tree.save("assets/images/tree.png")

# barrier
barrier = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
d4 = ImageDraw.Draw(barrier)
d4.rectangle([0, 0, 31, 31], fill=(169, 169, 169), outline=(105, 105, 105))
for pos in [(8, 16), (16, 8), (24, 24)]:
    x, y = pos
    d4.line([x, y, x + 4, y + 4], fill=(105, 105, 105), width=1)
    d4.line([x + 4, y, x, y + 4], fill=(105, 105, 105), width=1)
barrier.save("assets/images/barrier.png")

# exit door (panel + knob)
door = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
d5 = ImageDraw.Draw(door)
d5.rectangle([6, 6, 26, 28], fill=(205, 170, 120), outline=(120, 70, 30), width=2)
d5.rectangle([10, 10, 22, 26], outline=(120, 70, 30), width=1)
d5.ellipse([20, 17, 22, 19], fill=(90, 60, 30))
door.save("assets/images/exit.png")

print("Assets regenerated: forest_bg (walls baked), player, tree, barrier, exit")


if __name__ == "__main__":
    import pygame
    pygame.init()
    screen = pygame.display.set_mode((W, H))
    pygame.display.set_caption("Asset Preview")
    names = ["forest_bg", "player", "tree", "barrier", "exit"]  # ← removed castle_overlay
    images = [pygame.image.load(f"assets/images/{n}.png") for n in names]

    idx = 0; clock = pygame.time.Clock(); running = True
    while running:
        clock.tick(10)
        for ev in pygame.event.get():
            if ev.type == pygame.QUIT: running = False
            elif ev.type == pygame.KEYDOWN:
                if ev.key == pygame.K_RIGHT: idx = (idx+1) % len(images)
                elif ev.key == pygame.K_LEFT: idx = (idx-1) % len(images)
        screen.fill((0,0,0))
        screen.blit(images[idx], images[idx].get_rect(center=screen.get_rect().center))
        pygame.display.flip()
    pygame.quit()
# generate_assets.py
from PIL import Image, ImageDraw
import random, math, os

W, H = 960, 540
os.makedirs("assets/images", exist_ok=True)

# ---------- helpers ----------
def lerp(a, b, t): return int(a + (b - a) * t)

def noisy_ellipse_points(cx, cy, rx, ry, points=140, amp=0.12, freq=3.5):
    """Return a list of (x,y) forming an irregular ellipse polygon."""
    res = []
    # multi-wave noise for organic edge
    p1, p2 = random.random()*math.pi*2, random.random()*math.pi*2
    p3 = random.random()*math.pi*2
    for i in range(points):
        a = (i / points) * math.tau
        # base radius modulation (clamped positive)
        n = (math.sin(a*freq + p1) + 0.6*math.sin(a*(freq*0.5) + p2) +
             0.3*math.sin(a*(freq*1.7) + p3)) * 0.5
        rxf = max(0.85, 1 + amp * n)
        ryf = max(0.85, 1 + amp * n)
        x = cx + rx * rxf * math.cos(a)
        y = cy + ry * ryf * math.sin(a)
        res.append((int(x), int(y)))
    return res

# ---------- Background: grass ----------
bg = Image.new("RGB", (W, H), color=(78, 112, 66))
draw = ImageDraw.Draw(bg)
for _ in range(4500):
    x = random.randrange(0, W); y = random.randrange(0, H)
    draw.point((x, y), fill=random.choice([(90,126,78),(72,104,62),(84,118,72)]))

# ---------- Lake (irregular + gradient) ----------
lake_x, lake_y, lake_w, lake_h = 490, 220, 300, 180
cx, cy = lake_x + lake_w/2, lake_y + lake_h/2
rx, ry = lake_w/2, lake_h/2

# outer irregular shoreline polygon
shore_poly = noisy_ellipse_points(cx, cy, rx, ry, points=160, amp=0.10, freq=3.2)
# fill shoreline ring
draw.polygon(shore_poly, fill=(140, 185, 200))

# inner water gradient via multiple inset polygons
layers = 16
for i in range(layers):
    t = i / (layers - 1)
    # shrink radii for inner layer
    rxi = rx * (1 - 0.06 - 0.5 * t)
    ryi = ry * (1 - 0.06 - 0.5 * t)
    # add gentler noise inside
    poly = noisy_ellipse_points(cx, cy, rxi, ryi, points=120, amp=0.05*(1-t), freq=2.6)
    # depth color: lighter near shore -> darker center
    col = (
        lerp(120, 50, t),   # R
        lerp(165, 100, t),  # G
        lerp(190, 155, t)   # B
    )
    draw.polygon(poly, fill=col)

# subtle highlights (sparkles)
for _ in range(140):
    x = random.randint(lake_x+12, lake_x+lake_w-12)
    y = random.randint(lake_y+12, lake_y+lake_h-12)
    if ( (x-cx)**2 / (rx*rx) + (y-cy)**2 / (ry*ry) ) <= 1.0:
        draw.point((x, y), fill=(210, 235, 245))

# ---------- Castle walls (baked, high-contrast) ----------
TH = 32  # visual thickness—match your EDGE_THICK colliders
stone  = (95, 95, 95)
mortar = (45, 45, 45)
crenel = (135, 135, 135)
shadow = (0, 0, 0)

# solid bands
draw.rectangle([0, 0, W, TH], fill=stone)                    # top
draw.rectangle([0, H-TH, W, H], fill=stone)                  # bottom
draw.rectangle([0, 0, TH, H], fill=stone)                    # left
draw.rectangle([W-TH, 0, W, H], fill=stone)                  # right

# inner drop shadow fade to make walls pop on grass
draw.rectangle([TH, TH-6, W-TH, TH+6], fill=(0,0,0,))        # under top
draw.rectangle([TH, H-TH-6, W-TH, H-TH+6], fill=(0,0,0,))    # above bottom
draw.rectangle([TH-6, TH, TH+6, H-TH], fill=(0,0,0,))        # right of left
draw.rectangle([W-TH-6, TH, W-TH+6, H-TH], fill=(0,0,0,))    # left of right

# block pattern lines
for x in range(0, W, 28):
    draw.line([(x, 0), (x, TH)], fill=mortar, width=2)
    draw.line([(x, H-TH), (x, H)], fill=mortar, width=2)
for y in range(0, H, 20):
    draw.line([(0, y), (TH, y)], fill=mortar, width=2)
    draw.line([(W-TH, y), (W, y)], fill=mortar, width=2)

# crenellations top & bottom
MER_W, MER_H, GAP = 26, 14, 14
x = TH
while x < W-TH:
    draw.rectangle([x, 0, min(x+MER_W, W-TH), MER_H], fill=crenel)
    draw.rectangle([x, H-MER_H, min(x+MER_W, W-TH), H], fill=crenel)
    x += MER_W + GAP

bg.save("assets/images/forest_bg.png")

# ---------- Sprites ----------
# player
player = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
d2 = ImageDraw.Draw(player)
d2.ellipse([12, 4, 20, 12], outline="black", fill="white")
d2.line([16, 12, 16, 24], fill="black", width=2)
d2.line([16, 14, 8, 20], fill="black", width=2); d2.line([16, 14, 24, 20], fill="black", width=2)
d2.line([16, 24, 8, 30], fill="black", width=2); d2.line([16, 24, 24, 30], fill="black", width=2)
player.save("assets/images/player.png")

# tree
tree = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
d3 = ImageDraw.Draw(tree)
d3.rectangle([14, 20, 18, 32], fill=(139, 69, 19))
d3.ellipse([2, 4, 30, 24], fill=(34, 139, 34), outline=(0, 100, 0))
tree.save("assets/images/tree.png")

# barrier
barrier = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
d4 = ImageDraw.Draw(barrier)
d4.rectangle([0, 0, 31, 31], fill=(169, 169, 169), outline=(105, 105, 105))
for pos in [(8, 16), (16, 8), (24, 24)]:
    x, y = pos
    d4.line([x, y, x + 4, y + 4], fill=(105, 105, 105), width=1)
    d4.line([x + 4, y, x, y + 4], fill=(105, 105, 105), width=1)
barrier.save("assets/images/barrier.png")

# exit door (panel + knob)
door = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
d5 = ImageDraw.Draw(door)
d5.rectangle([6, 6, 26, 28], fill=(205, 170, 120), outline=(120, 70, 30), width=2)
d5.rectangle([10, 10, 22, 26], outline=(120, 70, 30), width=1)
d5.ellipse([20, 17, 22, 19], fill=(90, 60, 30))
door.save("assets/images/exit.png")

print("Assets regenerated: forest_bg (walls baked), player, tree, barrier, exit")


if __name__ == "__main__":
    import pygame
    pygame.init()
    screen = pygame.display.set_mode((W, H))
    pygame.display.set_caption("Asset Preview")
    names = ["forest_bg", "player", "tree", "barrier", "exit"]  # ← removed castle_overlay
    images = [pygame.image.load(f"assets/images/{n}.png") for n in names]

    idx = 0; clock = pygame.time.Clock(); running = True
    while running:
        clock.tick(10)
        for ev in pygame.event.get():
            if ev.type == pygame.QUIT: running = False
            elif ev.type == pygame.KEYDOWN:
                if ev.key == pygame.K_RIGHT: idx = (idx+1) % len(images)
                elif ev.key == pygame.K_LEFT: idx = (idx-1) % len(images)
        screen.fill((0,0,0))
        screen.blit(images[idx], images[idx].get_rect(center=screen.get_rect().center))
        pygame.display.flip()
    pygame.quit()
