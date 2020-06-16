# https://www.sigbus.info/compilerbook/Dockerfile
FROM ubuntu:18.04
LABEL maintainer "petitviolet <mail@petitviolet.net>"

RUN apt update
RUN DEBIAN_FRONTEND=noninteractive apt install -y gcc make git binutils libc6-dev gdb sudo autoconf bison build-essential libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libncurses5-dev libffi-dev libgdbm5 libgdbm-dev curl wget

RUN adduser --disabled-password --gecos '' user
RUN echo 'user ALL=(root) NOPASSWD:ALL' > /etc/sudoers.d/user

USER user
WORKDIR /src

RUN git clone --depth 1 https://github.com/rbenv/rbenv.git ~/.rbenv && \
      mkdir -p ~/.rbenv/plugins && \
      git clone --depth 1 https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build && \
      echo 'eval "$(rbenv init -)"' >> ~/.bashrc

ENV PATH "~/.rbenv/bin:$PATH"
RUN ~/.rbenv/bin/rbenv install 2.7.1 && ~/.rbenv/bin/rbenv global 2.7.1
RUN ~/.rbenv/bin/rbenv exec gem install rstructural && \
      ~/.rbenv/bin/rbenv exec gem install byebug

CMD /bin/bash
