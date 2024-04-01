FROM python:3.10

# Configure user for Jupyter Lab
ARG USERNAME=jupyter
ARG UID=1000
ARG GID=1000
ARG JUPYTER_HOME=/opt/jupyter
ENV JUPYTER_HOME=$JUPYTER_HOME

# Create a non-root user with specified UID and GID
RUN groupadd --gid $GID $USERNAME && \
    useradd --uid $UID --gid $GID --shell /bin/bash --create-home $USERNAME

# Install venv and other dependencies, set up directory for Jupyter
RUN apt-get update && \
    apt-get install -y openjdk-17-jdk-headless python3-venv nodejs npm && \
    mkdir $JUPYTER_HOME && \
    chown $USERNAME:$USERNAME $JUPYTER_HOME && \
    npm install -g sql-language-server

# Create entrypoint
COPY ./entrypoint.sh /opt/entrypoint.sh
RUN chmod +x /opt/entrypoint.sh

# Switch to the non-root user
USER $USERNAME

# Create a Python virtual environment called "jupyter"
RUN python3 -m venv $JUPYTER_HOME

# Activate the virtual environment, install Jupyter and dependencies
SHELL ["/bin/bash", "-c"]
RUN source $JUPYTER_HOME/bin/activate && \
    pip install --no-cache-dir \
    delta-spark pyspark 'jupyterlab>=4.1.0,<5.0.0a0' jupyterlab-lsp \
    jupyterlab-git jupyterlab-sql-editor jedi 'python-lsp-server[all]' bokeh

# Set the working directory
WORKDIR /home/$USERNAME

# Add required IPython profiles
RUN mkdir -p ~/.ipython/profile_default
COPY ./ipython_config.py /home/$USERNAME/.ipython/profile_default/ipython_config.py 

# Expose port for JupyterLab and set entrypoint
EXPOSE 8888
ENTRYPOINT /opt/entrypoint.sh
