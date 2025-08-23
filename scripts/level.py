# scripts/level.py
import json, pygame
from scripts.obstacles import Tree, Water, Exit
from scripts.barrier import Barrier
from scripts.puzzles import MCArithmeticPuzzle, FreeResponseArithmeticPuzzle

def load_level(path, image_loader, font):
    with open(path, "r") as f:
        data = json.load(f)

    bg = image_loader(data["background"])
    trees = pygame.sprite.Group()

    # optional lake collider
    water_rect = None
    if "water" in data:
        w = data["water"]
        water_rect = pygame.Rect(w["x"], w["y"], w["width"], w["height"])
        trees.add(Water(w["x"], w["y"], w["width"], w["height"]))

    # trees
    for t in data.get("trees", []):
        img = image_loader(t.get("image", "tree.png"))
        trees.add(Tree(t["x"], t["y"], img))

    # barriers (puzzles)
    barriers = pygame.sprite.Group()
    for b in data.get("barriers", []):
        img = image_loader(b.get("image", "barrier.png"))
        pz_cfg = b.get("puzzle", {})
        pz_type = pz_cfg.get("type", "arithmetic_mc")
        ops = pz_cfg.get("ops", ["add", "sub"])
        difficulty = pz_cfg.get("difficulty", "easy")
        if pz_type == "arithmetic_free":
            pz = FreeResponseArithmeticPuzzle(ops=ops, difficulty=difficulty)
        else:
            choice_count = pz_cfg.get("choices", 4)
            pz = MCArithmeticPuzzle(ops=ops, difficulty=difficulty, choice_count=choice_count)
        barriers.add(Barrier(b["x"], b["y"], img, pz))

    # exit
    ex = data["exit"]
    exit_img = image_loader(ex.get("image", "exit.png")) if ex.get("image") else None
    exit_sprite = Exit(ex["x"], ex["y"], ex["width"], ex["height"], exit_img)

    # convenience: stash water rect for debug drawing if you want
    exit_sprite.water_rect = water_rect

    return bg, trees, barriers, exit_sprite
