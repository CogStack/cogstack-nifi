#!/bin/bash

################################################################
# 
# This script creates client keys and certificates that can 
#  be used by client's applications
#

set -e

ES_CERTIFICATES_FOLDER="./es_certificates/opensearch"

if [[ -z "${CERTIFICATE_TIME_VAILIDITY_IN_DAYS}" ]]; then
    CERTIFICATE_TIME_VAILIDITY_IN_DAYS=730
    echo "CERTIFICATE_TIME_VAILIDITY_IN_DAYS not set, defaulting to CERTIFICATE_TIME_VAILIDITY_IN_DAYS=730"
else
    CERTIFICATE_TIME_VAILIDITY_IN_DAYS=${CERTIFICATE_TIME_VAILIDITY_IN_DAYS}
fi

if [[ -z "${CLIENT_CERT_NAME}" ]]; then
    CLIENT_CERT_NAME="es_kibana_client"
    echo "CLIENT_CERT_NAME not set, defaulting to CLIENT_CERT_NAME=es_kibana_client"
else
    CLIENT_CERT_NAME=${CLIENT_CERT_NAME}
fi

if [[ -z "${CA_ROOT_CERT}" ]]; then
    CA_ROOT_CERT="root-ca.pem"
    echo "CA_ROOT_CERT not set, defaulting to CA_ROOT_CERT=root-ca.pem"
else
    CA_ROOT_CERT=${CA_ROOT_CERT}
fi

if [[ -z "${CA_ROOT_KEY}" ]]; then
    CA_ROOT_KEY="root-ca.key"
    echo "CA_ROOT_KEY not set, defaulting to CA_ROOT_KEY=root-ca.key"
else
    CA_ROOT_KEY=${CA_ROOT_KEY}
fi

if [ ! -e $CA_ROOT_CERT ]; then
	echo "Root CA certificate and key does not exist: $CA_ROOT_CERT , $CA_ROOT_KEY"
	exit 1
fi

if [[ -z "${ES_CLIENT_SUBJ_LINE}" ]]; then
    ES_CLIENT_SUBJ_LINE="/C=UK/ST=UK/L=UK/O=cogstack/OU=cogstack/CN=CLIENT"
    echo "ES_CLIENT_SUBJ_LINE not set, defaulting to ES_CLIENT_SUBJ_LINE=/C=UK/ST=UK/L=UK/O=cogstack/OU=cogstack/CN=CLIENT"
else
    ES_CLIENT_SUBJ_LINE=${ES_CLIENT_SUBJ_LINE}
fi

if [[ -z "${ES_CLIENT_SUBJ_ALT_NAMES}" ]]; then
    ES_CLIENT_SUBJ_ALT_NAMES="subjectAltName=DNS:kibana,DNS:elasticsearch-3,DNS:elasticsearch-1,DNS:elasticsearch-2,DNS:elasticsearch-node-2,DNS:nifi,DNS:cogstack"
    echo "ES_CLIENT_SUBJ_ALT_NAMES not set, defaulting to ES_CLIENT_SUBJ_ALT_NAMES=subjectAltName=DNS:kibana,DNS:elasticsearch-3,DNS:elasticsearch-1,DNS:elasticsearch-2,DNS:nifi,DNS:cogstack"
else
    ES_CLIENT_SUBJ_ALT_NAMES=${ES_CLIENT_SUBJ_ALT_NAMES}
fi

KEY_SIZE=4096

echo "Generating a key for: $CLIENT_CERT_NAME"
openssl genrsa -out "$CLIENT_CERT_NAME-pkcs12.key" $KEY_SIZE

echo "Converting the key to PKCS 12"
openssl pkcs8 -v1 "PBE-SHA1-3DES" -in "$CLIENT_CERT_NAME-pkcs12.key" -topk8 -out "$CLIENT_CERT_NAME.key" -nocrypt

echo "Generating the certificate ..."
openssl req -new -key "$CLIENT_CERT_NAME.key" -out "$CLIENT_CERT_NAME.csr" -subj $ES_CLIENT_SUBJ_LINE

# -config <(cat /etc/ssl/openssl.cnf <(printf "\nsubjectAltName=DNS:elasticsearch-1,DNS:elasticsearch-2,DNS:elasticsearch-node-1,DNS:elasticsearch-node-2,DNS:elasticsearch-cogstack-node-2,DNS:elasticsearch-cogstack-node-1,DNS:localhost"))

echo "Signing the certificate ..."
openssl x509 -req -days $CERTIFICATE_TIME_VAILIDITY_IN_DAYS -in "$CLIENT_CERT_NAME.csr" -CA $CA_ROOT_CERT -CAkey $CA_ROOT_KEY -CAcreateserial -out "$CLIENT_CERT_NAME.pem" -extensions v3_ca -extfile ./ssl-extensions-x509.cnf

#-extfile <(printf "\nsubjectAltName=DNS:esnode-1,DNS:esnode-2,DNS:elasticsearch-1,DNS:elasticsearch-2,DNS:elasticsearch-node-1,DNS:elasticsearch-node-2,DNS:elasticsearch-cogstack-node-2,DNS:elasticsearch-cogstack-node-1,DNS:localhost") 

mv "$CLIENT_CERT_NAME"* $ES_CERTIFICATES_FOLDER/

