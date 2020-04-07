# hths.hacks-ctf

## Deployment

> If you want to test locally, you can use the Dockerfile. I assume you already know how to use docker

To deploy, I used two DigitalOcean droplets. Spin them up with at least 1 GB RAM each, and Ubuntu 18.04.
Set your DNS A record to the IP addresses of the servers. For example:
```
A ctf.hthshacks.com 1.2.3.4
A shell.hthshacks.com 4.5.6.7
```
SSH into both of them (as root), and use scp to copy the `setup.sh` file. Run it, with the correct
command line arguments documented in the script. You will be prompted to type in the password you specified
later on.

That should install everything. If there's an error, check to make sure you specified
everything correctly.

Finally, go into your web url. Register your admin account, then go to manage. Go to Shell Server,
and fill in all the details. **Make sure you select HTTPS!**

## Usage

To deploy challenges, ssh into the shell server as `ctf`. Run `sudo su` to transfer to the root
account. You can't run the script with sudo, you must be root. Here's a few example commands to run
at first:

```bash
shell_manager status
shell_manager undeploy all
shell_manager install MyChallenge
shell_manager deploy -n 5 all # The n is the number of instances. 5 is good to prevent cheating.
```
