import json
import pygame
from scripts.obstacles import Tree, Exit
from scripts.barrier import Barrier
from scripts.puzzles import MathPuzzle

def load_level(path, image_loader, font):
    """
    path: e.g. "levels/level1.json"
    image_loader: lambda name -> loaded pygame.Surface
    font: pygame.font.Font for puzzles
    Returns: bg_image, trees_group, barriers_group, exit_sprite
    """
    with open(path) as f:
        data = json.load(f)

    bg = image_loader(data["background"])

    trees = pygame.sprite.Group()
    for t in data.get("trees", []):
        img = image_loader(t.get("image", "tree.png"))
        trees.add(Tree(t["x"], t["y"], img))

    barriers = pygame.sprite.Group()
    for b in data.get("barriers", []):
        img = image_loader(b.get("image", "barrier.png"))
        pz = None
        pt = b["puzzle"]
        if pt["type"] == "math":
            pz = MathPuzzle(pt["question"], pt["answer"])
        # extend here for other puzzle types
        barriers.add(Barrier(b["x"], b["y"], img, pz))

    ex_cfg = data["exit"]
    exit_img = None
    if ex_cfg.get("image"):
        exit_img = image_loader(ex_cfg["image"])
    exit_sprite = Exit(
        ex_cfg["x"], ex_cfg["y"], ex_cfg["width"], ex_cfg["height"], exit_img
    )

    return bg, trees, barriers, exit_sprite
