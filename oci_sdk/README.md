# OCI SDK

## Summary

The Oracle Cloud Infrastructure (OCI) Software Development Kit (SDK) is needed for running Python scripts that access OCI.

## Installation

First, create a BASH function, called `activate`, with the following definition (best to save the definition in `~/.bashrc`):

```bash
activate () 
{ 
    [[ $# -eq 0 ]] && return 1;
    [[ ! -d ~/.venv/$1/bin ]] && return 1;
    source ~/.venv/$1/bin/activate;
    return 0
}
```

Second, create and populate the virtual environment as follows:

```bash
mkdir -p ~/.venv
cd ~/.venv
python3 -m venv oci-sdk
cd
activate oci-sdk
pip install oci
```

## Establishing the OCI SDK Environment

Before running the scripts in this directory:

1. Create a public/private key pair
1. Log into the OCI console
1. Navigate to:
   - _Identity_
     - _My profile_
1. Add the public key as the API key
1. Copy the generated OCI configuration to `~/.oci/config`
1. Run `activate oci-sdk`
