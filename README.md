# My dotfiles

This repo contains my dotfiles and the scripts needed to install them on a new
machine.

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
