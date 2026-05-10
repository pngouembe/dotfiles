# Verifies the dotfiles install end-to-end on a fresh Ubuntu image.
# Mirrors the steps you'd run on a brand new machine:
#   1. install nix
#   2. drop the dotfiles into ~/dotfiles  (COPY here; `git clone` on a real machine)
#   3. activate the home-manager flake
#   4. stow the configs
#
# Build:  docker build -f .docker/Dockerfile -t dotfiles-test .
# Run:    docker run --rm -it dotfiles-test

FROM ubuntu:24.04

ARG USER=png

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        curl xz-utils ca-certificates sudo locales \
    && rm -rf /var/lib/apt/lists/* \
    && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && locale-gen en_US.UTF-8

ENV LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

RUN userdel -r ubuntu \
    && useradd -m -s /bin/bash ${USER} \
    && echo "${USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER ${USER}
WORKDIR /home/${USER}

# 1. Install nix (single-user; no daemon needed in containers).
RUN curl -L https://nixos.org/nix/install | sh -s -- --no-daemon \
    && mkdir -p ~/.config/nix \
    && printf 'experimental-features = nix-command flakes\n' > ~/.config/nix/nix.conf

ENV PATH=/home/${USER}/.nix-profile/bin:${PATH}

# 2. Drop the dotfiles into ~/dotfiles (stand-in for `git clone` on a real machine).
COPY --chown=${USER}:${USER} . /home/${USER}/dotfiles
WORKDIR /home/${USER}/dotfiles

# 3. Apply the home-manager configuration — installs every program.
RUN . ~/.nix-profile/etc/profile.d/nix.sh \
    && nix run home-manager/master -- switch --flake .#${USER}

# 4. Symlink every config dir into ~/.config.
RUN stow .

CMD ["zsh"]
