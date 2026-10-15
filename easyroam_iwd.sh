#!/bin/bash
bin="$0"
print_usage() {
	cat >&2 <<-EOF
		USAGE
		${bin} >eduroam.8021x
		sudo cp eduroam.8021x /var/lib/iwd
	EOF
}
print_usage

# deps check
if ! type "openssl" &> /dev/null; then
	echo "openssl not found, install openssl" >&2
	exit 1
fi

# user input
printf "%s\n" "Select easyroam PKCS12 (.p12) file:" >&2
read -e infile
if [[ ! "${infile##*.}" == "p12" ]]; then
	echo "not a .p12 file" >&2
	exit 1
fi
file=$(basename "$infile")
read -sp "password for private key: " passphrase

# extract data from pkcs12
legacy="-legacy"
CLIENT_CERT=$(openssl pkcs12 -in "$file" $legacy -nokeys -passin pass: | openssl x509)
if [[ $? -ne 0 ]]; then
	legacy=""
	CLIENT_CERT=$(openssl pkcs12 -in "$file" $legacy -nokeys -passin pass: | openssl x509)
	if [[ $? -ne 0 ]]; then
		echo "Couldn't extract client certificate" >&2
		exit 1
	fi
fi

CLIENT_KEY=$(openssl pkcs12 $legacy -in "$file" -nodes -nocerts -passin pass: | openssl rsa -aes256 -passout pass:"$passphrase" 2>/dev/null)
if [[ $? -ne 0 ]]; then
	echo "Couldn't extract client key" >&2
fi

CA_CERT=$(openssl pkcs12 -in "$file" $legacy -cacerts -nokeys -passin pass: | openssl x509)
if [[ $? -ne 0 ]]; then
	echo "Couldn't extract root CA file" >&2
	exit 1
fi

identity=$(openssl x509 -noout -subject <<<${CLIENT_CERT} | awk -F= '{print $NF}')

# eduroam.8021x
cat <<EOF
[Security]
EAP-Method=TLS
EAP-Identity="$identity"
EAP-TLS-CACert=embed:ca_cert
EAP-TLS-ClientCert=embed:client_cert
EAP-TLS-ClientKey=embed:client_key
EAP-TLS-ClientKeyPassphrase="$passphrase"

[Settings]
AutoConnect=true

[@pem@ca_cert]
${CA_CERT}
[@pem@client_cert]
${CLIENT_CERT}
[@pem@client_key]
${CLIENT_KEY}
EOF
