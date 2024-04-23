FROM ubuntu as scratch_env

RUN apt update && apt install -y sudo

RUN adduser --disabled-password --gecos '' paul

RUN adduser paul sudo

RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER paul

VOLUME ["/home/paul/dotfiles/"]

WORKDIR /home/paul/dotfiles/

# ENTRYPOINT ./install.sh

CMD bash

FROM scratch_env as bootstraped_env
COPY --chown=paul bootstrap.sh /home/paul/

RUN bash -c 'source /home/paul/bootstrap.sh'

RUN rm /home/paul/bootstrap.sh

CMD bash
