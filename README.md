
Generate iwd config from easyroam .p12 files.

### Typical usage:

    chmod +x easyroam_iwd.sh
    ./easyroam_iwd.sh >eduroam.8021x
    sudo cp eduroam.8021x /var/lib/iwd

#### Notes

Setting a password for the client key is fairly useless,
because the password is included in plain text in the
output file. 

TODO: find a way to not store EAP-TLS-ClientKeyPassphrase in plaintext
