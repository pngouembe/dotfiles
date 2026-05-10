# My dotfiles

This repo contains my dotfiles and the scripts needed to install them on a new
machine.

## Layout

The repo is a single GNU stow package: every config file sits at the path it
should occupy under `$HOME` (e.g. `.zshrc`, `.config/alacritty/alacritty.yml`).
`.stowrc` sets `--target=$HOME` and `.stow-local-ignore` keeps repo metadata
(README, justfile, scripts, etc.) out of the link set.

## Installing

Clone the repo, then from its root:

```bash
stow .
```

That symlinks every tracked config into `$HOME`. If a real file already exists
at a target path, stow will refuse — back it up or pass `--adopt` to absorb it.

The justfile also provides `just install-dotfiles`, which installs stow first if
needed and then runs the same command. Program installation recipes
(`install-zsh`, `install-cli-tools`, …) are kept around but will be replaced by
nix.

## Testing

I created a docker environment that allows me to test my modifications.

There is an empty docker image that can be built using the following command:
```bash
docker build --target scratch_env --tag dotfiles_testenv_scratch --file .docker/test_env.dockerfile .
```
This image is interesting to work on the bootstrap script.

There is also a docker image where the bootstrap script has already been called to save some time.
It is buildable using the following command:
```bash
docker build --target bootstraped_env --tag dotfiles_testenv_bootstrap --file .docker/test_env.dockerfile .
```

To use those images, you can run the following commands:
```bash
# Run the scratch environment
docker run --rm -it -v /home/paul/dotfiles/:$HOME/dotfiles dotfiles_test_env_scratch bash

# Run the bootstraped environment
docker run --rm -it -v /home/paul/dotfiles/:$HOME/dotfiles dotfiles_test_env_bootstrap bash
```

> ![Note]
> The sudo password should be paul
