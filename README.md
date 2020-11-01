# docker-dokuwiki
A Docker container to run DokuWiki with a new or existing wiki and with default or specific configuration parameters.

## Intro

Usage scenarios: 
1. Start the container “as-is” and access it via HTTP or HTTPS. It will download the latest stable DokuWiki and will use the default Apache X.509 certificate. The wiki files will be inside the container, and will be deleted when the container removed. 
2. Allocate a volume for the persistent DokuWiki. Download the [latest version](https://download.dokuwiki.org/) and extract it to the volume or allow the script to install it. Or upgrade the existing Doku. See [how-to doc](https://www.dokuwiki.org/install:upgrade). Both HTTP and HTTPS are with default settings.
3. Same as above but add custom configuration files: **httpd.conf, ssl.conf, doku.conf, ssmtp.conf** as well as a custom key and a X509 certificate for proper TLS v1.3.

Brief description:
- The image uses Alpine Linux with Apache HTTPD
- All HTTPD logs are redirected to STDOUT/STDERR
- Defautl DokuWiki web-config does NOT use the re-write module
- This image may use a volume to store DokiWiki files at `/usr/share/dokuwiki`
- This image uses **ssmtp** as a sendmail (replacement) program. It needs to be configured in the file `/etc/ssmtp/ssmtp.conf`

## Usage

To get the image: `docker pull etaylashev/dokuwiki`

### Run the scenario 2:
```
docker run -d \
--name doku \
-p 80:80 -p 443:443  \
-e VERBOSE=1 \
-v  /var/k8s/doku/dokuwiki:/usr/share/dokuwiki \
etaylashev/dokuwiki
```
- Use port 80 or 443 for HTTP or HTTPS. Both will start DokuWiki
- Flag VERBOSE=1 provides more details into Docker logs from `entrypoint.sh`
- Do not forget to configure DokuWiki ([instructions](https://www.dokuwiki.org/install)) for the first time: `http://your_ip/install.php`

### Run the scanario 3:
- Store the  key, certificarte, CA chain certs and related configuration files into a directory.
- Pack them into a **7zip** archive with a password/symmetric key: `7z a -pYourSecretPassword doku.7z ./*`
- Place the archive to your configuration server, write down the URL
- Run the image: 
```
docker run -d \
--name doku \
-p 80:80 -p 443:443  \
-e VERBOSE=1 \
-e URL_CONF='https://your_configuration_server/doku.7z' \
-e SKEY='YourSecretPassword' \
-v  /var/k8s/doku/dokuwiki:/usr/share/dokuwiki \
etaylashev/dokuwiki
```
