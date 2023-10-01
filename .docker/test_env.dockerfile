FROM ubuntu

RUN apt update && apt install -y sudo

RUN adduser --disabled-password --gecos '' paul

RUN adduser paul sudo

RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER paul

VOLUME ["/home/paul/dotfiles/"]

WORKDIR /home/paul/dotfiles/

ENTRYPOINT ./install.sh 

CMD bash
