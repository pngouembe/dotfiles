FROM ubuntu as scratch_env

RUN apt update && apt install -y sudo locales

RUN adduser --disabled-password --gecos '' paul

RUN adduser paul sudo

# Setup passwordless sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
RUN echo 'paul:paul' | chpasswd

# Setup the locale
RUN echo "LC_ALL=en_US.UTF-8" >> /etc/environment
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
RUN echo "LANG=en_US.UTF-8" > /etc/locale.conf
RUN locale-gen en_US.UTF-8

USER paul

VOLUME ["/home/paul/dotfiles/"]

WORKDIR /home/paul/dotfiles/

CMD bash

FROM scratch_env as bootstraped_env
COPY --chown=paul bootstrap.sh /home/paul/

RUN bash -c 'source /home/paul/bootstrap.sh'

RUN rm /home/paul/bootstrap.sh

CMD bash
