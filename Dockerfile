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
        libssl1.1 \
        nodejs \
        pandoc \
        texlive-xetex \
        libxss-dev \
        libatk-bridge2.0-dev \
        libgtk-3-0 \
        libasound2 \
        libbz2-dev \
    && cd /usr/local/bin \
    && pip3 install --upgrade pip \
    && apt-get clean

RUN npm --version

# install pandoc
#RUN wget -o /tmp/pandoc-2.7.1.deb https://github.com/jgm/pandoc/releases/download/2.7.1/pandoc-2.7.1-1-amd64.deb && \
#    dpkg -i /tmp/pandoc-2.7.1.deb && \
#    rm /tmp/pandoc-2.7.1.deb
COPY requirements.txt /tmp/
RUN pip3 install -r /tmp/requirements.txt
RUN pip3 install --force-reinstall --no-cache-dir jupyter
RUN pip3 freeze
RUN npm list --depth=1 -g && \
    jupyter labextension install @jupyterlab/geojson-extension && \
    jupyter labextension install jupyterlab-drawio && \
    jupyter labextension install @jupyterlab/celltags && \
    jupyter contrib nbextension install --system


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
RUN pip3 install setuptools \
    && pip3 install --global-option=build_ext --global-option="-I/usr/include/gdal" GDAL==$(gdal-config --version | awk -F'[.]' '{print $1"."$2}')

# Install what's in requirements.txt
# and some other extensions:
# - geojson-extension:
# - celltags: tag cells (e.g. with 'hidden' to exclude from export)

COPY ./notebooks /home/user/notebooks
WORKDIR /home/user/notebooks


EXPOSE 8888
#CMD ["jupyter", "notebook", "--port=8888", "--no-browser", "--ip=0.0.0.0"]
CMD ["jupyter", "lab", "--port=8888", "--no-browser", "--ip=0.0.0.0", "--allow-root"]
