FROM python:3.8.0-buster


ENV DEBIAN_FRONTEND noninteractive
ENV DEBIAN_FRONTEND teletype

RUN curl -sL https://deb.nodesource.com/setup_10.x | bash - && \
    apt-get update && apt-get remove ipython && ACCEPT_EULA=Y apt-get install -y --no-install-recommends \
        apt-utils \
        ca-certificates \
        curl \
        debconf-utils \
        dirmngr \
        gcc \
        git \
        g++ \
	    libgdal-dev \
        nodejs \
        npm \
        pandoc \
        texlive-xetex \
        libxss-dev \
        libatk-bridge2.0-dev \
        libgtk-3-0 \
        libasound2 \
        libbz2-dev \
    && cd /usr/local/bin \
    && ln -s /usr/bin/python3 python \
    && pip3 install --upgrade pip \
    && apt-get clean

# Special treatment for corefonts since we need to autoaccept eula
# https://unix.stackexchange.com/a/106553
RUN echo 'ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula boolean true' | debconf-set-selections \
    && apt-get install -y --no-install-recommends \
        ttf-mscorefonts-installer \
    && apt-get remove -y --purge debconf-utils \
    && apt-get clean

# install pandoc
#RUN wget -o /tmp/pandoc-2.7.1.deb https://github.com/jgm/pandoc/releases/download/2.7.1/pandoc-2.7.1-1-amd64.deb && \
#    dpkg -i /tmp/pandoc-2.7.1.deb && \
#    rm /tmp/pandoc-2.7.1.deb


# RUN curl -o /usr/local/bin/gosu -SL "https://github.com/tianon/gosu/releases/download/1.4/gosu-$(dpkg --print-architecture)" \
#    && curl -o /usr/local/bin/gosu.asc -SL "https://github.com/tianon/gosu/releases/download/1.4/gosu-$(dpkg --print-architecture).asc" \
#    && rm /usr/local/bin/gosu.asc \
#    && chmod +x /usr/local/bin/gosu

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]


# Install required python dependencies
# ------------------------------------

# Note: the GDAL package version must exactly match the one
# 	    of installed libgdal-dev library version, hence the special treatment
#		https://gis.stackexchange.com/a/119565
RUN pip install setuptools \
    && pip install --global-option=build_ext --global-option="-I/usr/include/gdal" GDAL==$(gdal-config --version | awk -F'[.]' '{print $1"."$2}')

# Install what's in requirements.txt
# and some other extensions:
# - geojson-extension:
# - celltags: tag cells (e.g. with 'hidden' to exclude from export)
COPY requirements.txt /tmp/
RUN pip install -r /tmp/requirements.txt && \
    pip install --force-reinstall --no-cache-dir jupyter && \
    pip freeze
RUN npm list --depth=1 -g && \
    jupyter labextension install @jupyterlab/geojson-extension && \
    jupyter labextension install jupyterlab-drawio && \
    jupyter labextension install @jupyterlab/celltags && \
    jupyter contrib nbextension install --system


COPY ./notebooks /home/user/notebooks
WORKDIR /home/user/notebooks


EXPOSE 8888
#CMD ["jupyter", "notebook", "--port=8888", "--no-browser", "--ip=0.0.0.0"]
CMD ["jupyter", "lab", "--port=8888", "--no-browser", "--ip=0.0.0.0"]