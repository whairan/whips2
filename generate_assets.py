# generate_assets.py

from PIL import Image, ImageDraw
import random
import os

# ensure the assets/images folder exists
os.makedirs("assets/images", exist_ok=True)

# 1. forest_bg.png – Pixel-art forest background
width, height = 960, 540
forest = Image.new("RGB", (width, height), color=(85, 107, 47))  # dark olive green
draw = ImageDraw.Draw(forest)
for _ in range(1500):
    x = random.randrange(0, width, 20)
    y = random.randrange(0, height, 20)
    draw.rectangle([x, y, x + 10, y + 10], fill=(34, 139, 34))  # tree-green
forest.save("assets/images/forest_bg.png")

# 2. player.png – Pixel-art stick-figure player
player = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
draw = ImageDraw.Draw(player)
# head
draw.ellipse([12, 4, 20, 12], outline="black", fill="white")
# body
draw.line([16, 12, 16, 24], fill="black", width=2)
# arms
draw.line([16, 14, 8, 20], fill="black", width=2)
draw.line([16, 14, 24, 20], fill="black", width=2)
# legs
draw.line([16, 24, 8, 30], fill="black", width=2)
draw.line([16, 24, 24, 30], fill="black", width=2)
player.save("assets/images/player.png")

# 3. tree.png – Pixel-art tree
tree = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
draw = ImageDraw.Draw(tree)
# trunk
draw.rectangle([14, 20, 18, 32], fill=(139, 69, 19))
# canopy
draw.ellipse([2, 4, 30, 24], fill=(34, 139, 34), outline=(0, 100, 0))
tree.save("assets/images/tree.png")

# 4. barrier.png – Pixel-art barrier
barrier = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
draw = ImageDraw.Draw(barrier)
# base
draw.rectangle([0, 0, 31, 31], fill=(169, 169, 169), outline=(105, 105, 105))
# cracks
for pos in [(8, 16), (16, 8), (24, 24)]:
    x, y = pos
    draw.line([x, y, x + 4, y + 4], fill=(105, 105, 105), width=1)
    draw.line([x + 4, y, x, y + 4], fill=(105, 105, 105), width=1)
barrier.save("assets/images/barrier.png")

# 5. exit.png – Pixel-art exit door
exit_img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
draw = ImageDraw.Draw(exit_img)
# door
draw.rectangle([8, 4, 24, 28], fill=(222, 184, 135), outline=(139, 69, 19))
# arrow
draw.polygon([(16, 12), (20, 18), (12, 18)], fill=(0, 0, 0))
exit_img.save("assets/images/exit.png")


if __name__ == "__main__":
    import pygame

    # after you’ve saved everything…
    pygame.init()
    # size it to match your forest background, for example
    screen = pygame.display.set_mode((960, 540))
    pygame.display.set_caption("Asset Preview")

    # load all five back in
    names = ["forest_bg","player","tree","barrier","exit"]
    images = [pygame.image.load(f"assets/images/{n}.png") for n in names]

    # simple cycle-through display
    idx = 0
    clock = pygame.time.Clock()
    running = True
    while running:
        clock.tick(10)
        for ev in pygame.event.get():
            if ev.type == pygame.QUIT:
                running = False
            elif ev.type == pygame.KEYDOWN:
                # left/right arrows to cycle
                if ev.key == pygame.K_RIGHT:
                    idx = (idx+1) % len(images)
                elif ev.key == pygame.K_LEFT:
                    idx = (idx-1) % len(images)

        screen.fill((0,0,0))
        img = images[idx]
        # center it
        rect = img.get_rect(center=screen.get_rect().center)
        screen.blit(img, rect)
        pygame.display.flip()

    pygame.quit()
