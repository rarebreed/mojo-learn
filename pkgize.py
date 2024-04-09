import os
from pathlib import Path
from pprint import pprint
import shutil


def copy(path: Path):
    dest = Path(f"/tmp{path}")
    if dest.exists():
        shutil.rmtree(dest)
    dest.mkdir(parents=True, exist_ok=True)
    print(f"Copying {path} to {dest}")
    shutil.copytree(path, dst=dest, dirs_exist_ok=True)
    print("done copying")


def find_mojo_pkgs(
    path: Path,
    pkg_excludes: list[str],
    exclusions: set[str] | None = None
):
    py_paths = []

    # copy(path)
    if exclusions is None:
        exclusions = set([".git", ".pixi"])
    for root, _, files in os.walk(path):
        p = Path(root)
        union = set(p.parts).intersection(exclusions)
        if len(union):
            continue

        for file in files:
            f = os.path.join(root, file)
            if f.endswith(".coco"):
                Path(f).unlink()
            if f.endswith(".py"):
                coco = f.replace(".py", ".coco")
                coco = "/tmp" + coco
                print(f"copying {f} to {coco}")
                py_paths.append(coco)
                shutil.copyfile(f, coco)
    return py_paths


if __name__ == "__main__":
    from argparse import ArgumentParser
    parser = ArgumentParser()
    parser.add_argument("path", help="path to directory to search")
    args = parser.parse_args()
    p = Path(args.path)

    pprint(find_mojo_pkgs(p))
