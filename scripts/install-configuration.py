#!/usr/bin/env python3

from pathlib import Path

from rich import print


def main():
    dotfile_root = Path().home() / "dotfiles"

    print(f"Searching for link file from {dotfile_root}")

    links_files = dotfile_root.rglob("links.prop")
    for links_file in links_files:
        for link in links_file.read_text().splitlines():
            source, target = link.split("=")
            source = source.replace("$DOTFILES", str(dotfile_root))
            target = target.replace("$HOME", str(Path().home()))

            target = Path(target)
            target.parent.mkdir(parents=True, exist_ok=True)

            target.unlink(missing_ok=True)
            target.symlink_to(source)
            print(f"Link created: {source} -> {target}")

    env_setup_script = Path().home() / ".env.sh"
    env_setup_script.write_text(f"export DOTFILES={dotfile_root}")


if __name__ == "__main__":
    main()
