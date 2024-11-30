#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Lab 09:
# Instrastructure Security - Network: Create a Self-Signed Certificate and Perform
# SSL Termination on OCI Load Balancer
# 
# Create a Self-Signed Certificate
# ------------------------------------------------------------------------------

[[ -f ocilb.csr ]] || \
    openssl req             \
        -batch              \
        -out ocilb.csr      \
        -new                \
        -newkey rsa:2048    \
        -nodes              \
        -keyout ocilb.key

[[ -f ocilb.crt ]] || \
    openssl x509            \
        -signkey ocilb.key  \
        -in ocilb.csr       \
        -req                \
        -days 365           \
        -out ocilb.crt
