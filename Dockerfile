FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive
RUN echo "APT::Get::Assume-Yes \"true\";" > /etc/apt/apt.conf.d/90assumeyes
RUN apt-get update

RUN apt install software-properties-common
# RUN add-apt-repository ppa:deadsnakes/ppa
RUN add-apt-repository --yes --update ppa:ansible/ansible

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    jq \
    git \
    iputils-ping \
    libcurl4 \
    libunwind8 \
    netcat \
    libssl1.0 \
#    python3.8 \
    python3 \
    python3-pip \
    ansible \
    wget \
    apt-transport-https \
  && rm -rf /var/lib/apt/lists/*

# Azure CLI
RUN curl -LsS https://aka.ms/InstallAzureCLIDeb | bash \
  && rm -rf /var/lib/apt/lists/*

# WinRM for Ansible
# RUN pip install "pywinrm>=0.3.0"
RUN pip install pywinrm

# Ansible and the azure requirements
RUN curl https://raw.githubusercontent.com/ansible-collections/azure/dev/requirements-azure.txt --output requirements-azure.txt
RUN pip install -r requirements-azure.txt
RUN ansible-galaxy collection install azure.azcollection --force

# Hashicorp products (Packer & Terraform)

RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
RUN add-apt-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
RUN apt-get update
RUN apt-get install packer terraform

# Microsoft PowerShell
RUN wget -q https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb
RUN dpkg -i packages-microsoft-prod.deb

RUN apt-get update
RUN apt-get install powershell

# Clean up

RUN apt autoremove --purge
RUN apt clean

RUN df -h

# Azure DevOps Agent
ARG TARGETARCH=amd64
ARG AGENT_VERSION=2.194.0

WORKDIR /azp

RUN if [ "$TARGETARCH" = "amd64" ]; then \
      AZP_AGENTPACKAGE_URL=https://vstsagentpackage.azureedge.net/agent/${AGENT_VERSION}/vsts-agent-linux-x64-${AGENT_VERSION}.tar.gz; \
    else \
      AZP_AGENTPACKAGE_URL=https://vstsagentpackage.azureedge.net/agent/${AGENT_VERSION}/vsts-agent-linux-${TARGETARCH}-${AGENT_VERSION}.tar.gz; \
    fi; \
    curl -LsS "$AZP_AGENTPACKAGE_URL" | tar -xz

COPY ./start.sh .
RUN chmod +x start.sh

ENTRYPOINT [ "./start.sh" ]