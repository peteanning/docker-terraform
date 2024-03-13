from ubuntu:22.04

ARG HOME=/root

ENV TZ=Europe/London
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

ENV SBT_VERSION 1.9.7
ENV TF_VERSION_12 0.12.31
ENV TF_VERSION_11 0.11.14
ENV PYTHON_VERSION 3.9.4

ENV PYENV_RELEASE v1.2.26
ENV PYENV_ROOT="$HOME/.pyenv"
ENV PATH="$PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH"

ENV DEFAULT_PIPS="virtualenv requests"

WORKDIR $HOME

RUN mkdir -p $HOME/workdir

#prepare to mount ~/.ssh to /.ssh
COPY entry-point.sh /bin/entry-point.sh
RUN chmod +x /bin/entry-point.sh

#setup profile
COPY bash_profile $HOME/.bash_profile
COPY bash_aliases $HOME/.bash_aliases

ARG pyenv_required_packages="make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev"

RUN apt-get update -qq \
    && apt-get install -qqy \
    tzdata \
    curl \
    zip \
    git \
    apt-transport-https \
    ca-certificates \
    lxc \
    iptables \
    jq \
    $pyenv_required_packages

# Install pyenv & set python version
RUN git clone https://github.com/pyenv/pyenv.git $HOME/.pyenv && \
    cd $HOME/.pyenv && \
    git checkout ${PYENV_RELEASE} && \
    pyenv install $PYTHON_VERSION && \
    eval "$(pyenv init -)" && \
    pyenv shell $PYTHON_VERSION && \
    pip install ${DEFAULT_PIPS} && \
    pip install aws-profile && \
    pyenv global $PYTHON_VERSION && \
    echo 'eval "$(pyenv init -)"' >> $HOME/.bashrc


# Terraform
RUN git clone https://github.com/tfutils/tfenv.git tfenv && \
    ln -s $HOME/tfenv/bin/* /usr/local/bin && \
    tfenv install "$TF_VERSION_12" && \
    tfenv install "$TF_VERSION_11"

#AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install


ENTRYPOINT ["/bin/entry-point.sh"]
