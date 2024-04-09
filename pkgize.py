import os
from pathlib import Path
from pprint import pprint
import tomllib as toml

def get_project_src_path(path: Path):
    with open(path / "pixi.toml", "rb") as tf:
        pixi_cfg = toml.load(tf)
    src_path = pixi_cfg["project"]["name"].replace("-", "_")
    return path / src_path

def project_src_pkg(path: Path):
    proj_src_path = get_project_src_path(path)
    return [f"{proj_src_path}/__init__{suffix}" for suffix in (".mojo", ".🔥")]


def find_mojo_pkgs(
    path: Path,
    exclusions: set[str] | None = None
) -> list[str]:
    pkg_paths = []

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
            if f.endswith("__init__.mojo") or f.endswith("__init__.🔥"):
                if f not in project_src_pkg(path):
                    print(f"Adding {f}")
                    pkg_paths.append(f)                    
    return pkg_paths


if __name__ == "__main__":
    from subprocess import run, PIPE
    from argparse import ArgumentParser
    parser = ArgumentParser()
    parser.add_argument("path", help="path to directory to search")
    args = parser.parse_args()

    if args.path == ".":
        p = Path.cwd()
    elif args.path == "..":
        p = Path.cwd().parent
    else:
        p = Path(args.path)

    builds = p / "packages"
    builds.mkdir(parents=True, exist_ok=True)
    for pkg in find_mojo_pkgs(p):
        pkg_path = Path(pkg)
        pkg_path_parent = pkg_path.parent
        pkg_name = pkg_path.parent.name
        print(f"Building {builds / pkg_name}")
        cmd = ["mojo", "package", f"{pkg_path_parent}", "-o", f"{builds / pkg_name}.📦"]
        print(cmd)
        run(cmd, stdout=PIPE, stderr=PIPE)
