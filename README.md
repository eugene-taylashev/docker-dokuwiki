# docker-dokuwiki
A Docker container to run DokuWiki with a new or existing wiki and with default or specific configuration parameters.

## Intro

Usage scenarios: 
1. Start the container “as-is” and access it via HTTP or HTTPS. It will download the latest stable DokuWiki and will use the default Apache X.509 certificate. The wiki files will be inside the container, and will be deleted when the container removed. 
2. Allocate configuration and data volumes for the persistent DokuWiki. Download the [latest version](https://download.dokuwiki.org/) and extract it to the volume or allow the script to install it. Or upgrade the existing Doku. See [how-to doc](https://www.dokuwiki.org/install:upgrade). Both HTTP and HTTPS are with default settings.

Brief description:
- The image uses Alpine Linux with Apache HTTPD
- All HTTPD logs are redirected to STDOUT/STDERR
- Defautl DokuWiki web-config does NOT use the re-write module
- This image may use a volume to store DokiWiki files at `/var/dokuwiki`
- This image may use a volume for configuration files and key/certificate at `/etc/dokuwiki`. These files will be copied to proper locations
- This image uses **ssmtp** as a sendmail (replacement) program. It needs to be configured in the file `/etc/ssmtp/ssmtp.conf`

## Usage

To get the image: `docker pull etaylashev/dokuwiki`

### Run the scenario 2:
```
docker run -d \
--name doku \
-p 80:80 -p 443:443  \
-e VERBOSE=1 \
-v  /var/doku/conf:/etc/dokuwiki \
-v  /var/doku/data:/var/dokuwiki \
etaylashev/dokuwiki
```
- Use port 80 or 443 for HTTP or HTTPS. Both will start DokuWiki
- Flag VERBOSE=1 provides more details into Docker logs from `entrypoint.sh`
- Do not forget to configure DokuWiki ([instructions](https://www.dokuwiki.org/install)) for the first time: `http://your_ip/install.php`
