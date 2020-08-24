# Web'n'surF Docker Manager setup

## For security Docker daemon should be started with TLS.

### TLS setup (server / Docker host machine):
Note: In the below commands replace `<DOCKER_HOST>` with the IP address / domain name you'll use to connect to the docker API.

If you'll be using an IP address to remotely connect to the docker daemon also replace `<DOCKER_HOST_IP>` with the IP address, otherwise remove that part of the command (`IP:<DOCKER_HOST_IP>,` in step 3)

1. Generate CA private and public keys:

```console
openssl genrsa -aes256 -out ca-key.pem 4096

openssl req -new -x509 -days 365 -key ca-key.pem -sha256 -out ca.pem
```

2. Create a server key and certificate signing request (CSR)

```console
openssl genrsa -out server-key.pem 4096

openssl req -subj "/CN=<DOCKER_HOST>" -sha256 -new -key server-key.pem -out server.csr
```

3. Sign the public key with our CA

```console
echo subjectAltName = DNS:<DOCKER_HOST>,IP:<DOCKER_HOST_IP>,IP:127.0.0.1 >> extfile.cnf

echo extendedKeyUsage = serverAuth >> extfile.cnf

openssl x509 -req -days 365 -sha256 -in server.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out server-cert.pem -extfile extfile.cnf
```

### TLS setup (client) - for siplicity this can also be performed on the server machine:
1. Create a client key and certificate signing request:

```console
openssl genrsa -out key.pem 4096

openssl req -subj '/CN=client' -new -key key.pem -out client.csr

echo extendedKeyUsage = clientAuth > extfile-client.cnf
```

2. Generate the signed certificate

```console
openssl x509 -req -days 365 -sha256 -in client.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out cert.pem -extfile extfile-client.cnf
```

3. After these steps you can safely remove the two certificate signing requests and extensions config files

```console
rm -v client.csr server.csr extfile.cnf extfile-client.cnf
```

4. Update file permissions
```console
chmod -v 0400 ca-key.pem key.pem server-key.pem

chmod -v 0444 ca.pem server-cert.pem cert.pem
```

### Enabling Docker API over TLS

1. Create a systemd override file (if `/etc/systemd/system/docker.service.d` directory does not exist create it first)

```console
sudo touch /etc/systemd/system/docker.service.d/override.conf
```

2. Add the following content to the `override.conf`. Make sure the path to sertificate files point to the server certificate files you just created

```console
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd --tlsverify --tlscacert=/etc/docker/certs/ca.pem --tlscert=/etc/docker/certs/server-cert.pem --tlskey=/etc/docker/certs/server-key.pem -H fd:// -H tcp://0.0.0.0:2376
```

3. Restart docker

```console
sudo systemctl restart docker
```

4. Make sure docker API is running and listening on port 2376 and the port is not blocked by your firewal

```console
netstat -tunlp | grep 2376
```

5. Make sure port 2376 and is not blocked by your firewal

### Connecting to the API from a remote machine
For this you'll need to copy over the client certificate files to the client machine and use them to connect to the docker host machine.

With portainer:
1. Go to `Endpoints` -> `Add endpoint`
2. Select `Docker - Directly connect to the Docker API`
3. Pick a name for the Endpoint and enter the `<DOCKER_HOST>:2376` you used when creating the TLS certificate for `Endpoint URL` & `Public IP`
4. Turn on `TLS` switch
5. Keep the default `TLS with server and client verification` and select the certificate files created and copied over before:
    - TLS CA certificate - `ca.pem`
    - TLS certificate - `cert.pem`
    - TLS key - `key.pem`
