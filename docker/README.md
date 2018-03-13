# RabbitMQ with TLS
The purpose of this Docker image is to launch RabbitMQ supporting TLS communication on port 5671 for secure connections.

It comes with management plugin, mapped to port 8080, which means you can access it from your internet browser with the adress `localhost:8080`; the default login/password is guest/guest

See [TLS with RabbitMQ](https://www.rabbitmq.com/ssl.html) for complete procedure. Informations below are directly extracted from there.
## Installation
Copy server certificate and private key (respectively `cert.pem` and `key.pem`) and CA certificate (`cacert.pem`) in `PROJECT_ROOT/docker` with those exact names (otherwise, change them in Dockerfile).

Copy CA certificate (`cacert.pem`) in `PROJECT_ROOT/TLS` and client certificate and key (respectively `cert.pem` and `key.pem`) in `PROJECT_ROOT/TLS/client1` with those exact names (otherwise, change reference to those files in each code using them).

Once this is done, you can compile Dockerfile with `docker-compose build`.

To launch the image: `docker-compose up`

## Generate Certificates
If you want to re-generate certificates.
### Certification Authority certificate
Somewhere on your system:
```
 mkdir testca
 cd testca
 mkdir certs private
 chmod 700 private
 echo 01 > serial
 touch index.txt
 ```
 Then in `openssl.cnf` copy the following:
 ```
 [ ca ]
default_ca = testca

[ testca ]
dir = .
certificate = $dir/cacert.pem
database = $dir/index.txt
new_certs_dir = $dir/certs
private_key = $dir/private/cakey.pem
serial = $dir/serial

default_crl_days = 7
default_days = 365
default_md = sha256

policy = testca_policy
x509_extensions = certificate_extensions

[ testca_policy ]
commonName = supplied
stateOrProvinceName = optional
countryName = optional
emailAddress = optional
organizationName = optional
organizationalUnitName = optional
domainComponent = optional

[ certificate_extensions ]
basicConstraints = CA:false

[ req ]
default_bits = 2048
default_keyfile = ./private/cakey.pem
default_md = sha256
prompt = yes
distinguished_name = root_ca_distinguished_name
x509_extensions = root_ca_extensions

[ root_ca_distinguished_name ]
commonName = hostname

[ root_ca_extensions ]
basicConstraints = CA:true
keyUsage = keyCertSign, cRLSign

[ client_ca_extensions ]
basicConstraints = CA:false
keyUsage = digitalSignature,keyEncipherment
extendedKeyUsage = 1.3.6.1.5.5.7.3.2

[ server_ca_extensions ]
basicConstraints = CA:false
keyUsage = digitalSignature,keyEncipherment
extendedKeyUsage = 1.3.6.1.5.5.7.3.1
 ```
 Then generate the key for our CA certificate:
 ```
 openssl req -x509 -config openssl.cnf -newkey rsa:2048 -days 365 -out cacert.pem -outform PEM -subj /CN=MyTestCA/ -nodes
openssl x509 -in cacert.pem -out cacert.cer -outform DER
 ```
### Server Certificate
 To generate Server key and certificate:
 ```
 cd ..
 ls
 # => testca
 mkdir server
 cd server
 openssl genrsa -out key.pem 2048
 openssl req -new -key key.pem -out req.pem -outform PEM -subj /CN=<SERVER_HOSTNAME_OR_IP>/O=server/ -nodes
 cd ../testca
 openssl ca -config openssl.cnf -in ../server/req.pem -out ../server/cert.pem -notext -batch -extensions server_ca_extensions
 cd ../server
 openssl pkcs12 -export -out keycert.p12 -in cert.pem -inkey key.pem -passout pass:MySecretPassword
 ```
### Client Certificate
 Then the client:
 ```
 cd ..
 ls
 # => server testca
 mkdir client
 cd client
 openssl genrsa -out key.pem 2048
 openssl req -new -key key.pem -out req.pem -outform PEM -subj /CN=$(hostname)/O=client/ -nodes
 cd ../testca
 openssl ca -config openssl.cnf -in ../client/req.pem -out ../client/cert.pem -notext -batch -extensions client_ca_extensions
 cd ../client
 openssl pkcs12 -export -out keycert.p12 -in cert.pem -inkey key.pem -passout pass:MySecretPassword
 ```

