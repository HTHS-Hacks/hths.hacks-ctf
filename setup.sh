#!/bin/bash

set -e

help () {
    echo "How to use this script:"
    echo "Get two empty servers with at least 1GB memory. I used DigitalOcean"
    echo "They must be Ubuntu 18.04 servers"
    echo "Then, copy this script to each."
    echo "Run both of them, with the following parameters:"
    echo
    echo "web_url:          Your URL for the web server. For example: ctf.hthshacks.com"
    echo "shell_url:        Your URL for the shell server. For example: shell.hthshacks.com"
    echo "passwd:           The password for the ctf account. MAKE IT VERY SECURE!!! This is how you SSH in."
    echo "shell_ip:         The IP address of the shell server: For example: 206.189.200.174"
    echo "server:           What server this is being run on. Can either be web or shell"
}

if [ "$#" -lt 5 ]; then
    echo "Illegal number of parameters"
    help
    exit 1
fi

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

WEB_URL=$1
SHELL_URL=$2
PASSWD=$3
SHELL_IP=$4
SERVER=$5

apt update
apt install git

useradd -ms /bin/bash ctf
echo 'ctf ALL=(ALL:ALL) NOPASSWD: ALL' | sudo EDITOR='tee -a' visudo
echo -e "ctf:$PASSWD" | chpasswd
echo -e "root:$PASSWD" | chpasswd

sudo -i -u ctf bash << EOT
cd /home/ctf

git clone --branch v19.0.1 -c core.autocrlf=false https://github.com/picoCTF/picoCTF.git
chmod og-rx picoCTF

cd picoCTF
sudo ln -s /home/ctf/picoCTF /picoCTF

cd ..
bash picoCTF/vagrant/provision_scripts/install_ansible.sh

cd picoCTF/ansible

cat <<EOF >> /home/ctf/web.patch
diff --git a/ansible/group_vars/local_development/vars.yml b/ansible/group_vars/local_development/vars.yml
index 31ee2c94..bd096641 100644
--- a/ansible/group_vars/local_development/vars.yml
+++ b/ansible/group_vars/local_development/vars.yml
@@ -2,35 +2,36 @@
 # Variables shared across all development hosts

 # vagrant/vagrant is the default configuration for Vagrant boxes
-ansible_user:     vagrant
-ansible_ssh_pass: vagrant
+ansible_user:     ctf
+ansible_ssh_pass: $PASSWD


 ##
 # Web settings (env specific)
 ##
-web_fqdn: "localhost"
-web_address: "http://{{ lookup('env','WIP') or '192.168.2.2' }}"
-nginx_server_name: "_"
+web_fqdn: "$WEB_URL"
+web_address: "https://$WEB_URL"
+nginx_server_name: "{{ web_fqdn }}"
 flask_app_server_name: "{{ web_fqdn }}"
 web_address_internal: "{{ web_address }}"

 # optional web automation
-enable_basic_auth:      False
-auto_add_shell:         True
-auto_load_problems:     True
-auto_start_competition: True
+enable_basic_auth:      True
+auto_add_shell:         False
+auto_load_problems:     False
+auto_start_competition: False

+net_outbound_limit: "40mbit"

 ###
 # Shell Settings (env specific)
 ###
-shell_hostname: "{{ lookup('env','SIP') or '192.168.2.3' }}"
+shell_hostname: "$SHELL_URL"
 shell_name: Local-Development-Shell   # no spaces
 shell_ip: "{{ shell_hostname }}"
 shell_user: "{{ ansible_user }}"
 shell_pass: "{{ ansible_ssh_pass }}"
-shell_manager_deploy_secret: "**insecure-secret**"
+shell_manager_deploy_secret: "$PASSWD"

 # default insecure "vagrant" password (mkpasswd --method=SHA-512 vagrant)
 shell_admin_password_crypt: "\\\$6\\\$0GcSqMClzx\\\$qEKEiL78VE/Xe0gzuGGuWyUqAlZMObkGnRYwHo4.vSUlvWt6aA7PBH1oGDsOQlykFNScEdEhrirD5oFLOHH011"
diff --git a/ansible/inventories/local_development b/ansible/inventories/local_development
index 304bd8c5..775726d5 100644
--- a/ansible/inventories/local_development
+++ b/ansible/inventories/local_development
@@ -10,10 +10,10 @@ web
 # In a development environment, or simple deployment collocate the database
 # with the web server
 [db]
-dev_web     ansible_connection=local    hostname=pico-local-dev-web-db
+dev_web     ansible_connection=local    hostname=ctf-web ansible_host=$WEB_URL shell_ip=$SHELL_IP

 [shell]
-dev_shell   ansible_connection=local    hostname=pico-local-dev-shell
+dev_shell   ansible_connection=local    hostname=ctf-shell ansible_host=$SHELL_URL shell_ip=$SHELL_IP

 [web]
-dev_web     ansible_connection=local    hostname=pico-local-dev-web-db
+dev_web     ansible_connection=local    hostname=ctf-web ansible_host=$WEB_URL shell_ip=$SHELL_IP web_fqdn=$WEB_URL
diff --git a/picoCTF-web/api/config.py b/picoCTF-web/api/config.py
index 65c9e5fd..9a0424e2 100644
--- a/picoCTF-web/api/config.py
+++ b/picoCTF-web/api/config.py
@@ -19,13 +19,13 @@ default_settings = {
     "start_time": datetime.datetime.utcnow(),
     "end_time": datetime.datetime.utcnow(),
     # COMPETITION INFORMATION
-    "competition_name": "CTF Placeholder",
-    "competition_url": "http://192.168.2.2",
-    "admin_email": "email@example.com",  # Contact given to parents
+    "competition_name": "hths.hacks() CTF",
+    "competition_url": "https://$WEB_URL",
+    "admin_email": "contact@hthshacks.com",  # Contact given to parents
     # EMAIL WHITELIST
     "email_filter": [],
     # TEAMS
-    "max_team_size": 5,
+    "max_team_size": 3,
     # BATCH REGISTRATION
     "max_batch_registrations": 250,  # Maximum batch registrations / teacher
     # ACHIEVEMENTS
diff --git a/picoCTF-web/web/_config.yml b/picoCTF-web/web/_config.yml
index 81d13e28..b5b12e34 100644
--- a/picoCTF-web/web/_config.yml
+++ b/picoCTF-web/web/_config.yml
@@ -1,5 +1,5 @@
 # Site settings
-title: CTF
+title: hths.hacks() CTF

 destination: /srv/http/ctf
 exclude: ['jsx', 'node_modules', 'package.json', 'package-lock.json']
diff --git a/picoCTF-web/web/_includes/header.html b/picoCTF-web/web/_includes/header.html
index ca8e7fb9..36f3d9fe 100644
--- a/picoCTF-web/web/_includes/header.html
+++ b/picoCTF-web/web/_includes/header.html
@@ -9,7 +9,7 @@
                 <span class="icon-bar"></span>
             </button>
                 <a class="navbar-brand dropdown-toggle" href="/">
-                    CTF Placeholder
+			<img src="https://hthshacks.com/Asset%201.f0aae812.png" width="60" height="60" />
                 </a>
         </div>

diff --git a/picoCTF-web/web/_posts/2015-01-01-example-post.markdown b/picoCTF-web/web/_posts/2015-01-01-example-post.markdown
deleted file mode 100644
index c26e5782..00000000
--- a/picoCTF-web/web/_posts/2015-01-01-example-post.markdown
+++ /dev/null
@@ -1,27 +0,0 @@
----
-title:  "This is my first post!"
-date:   2015-01-01 17:29:23
-categories: ctfs awesome
----
-
-The following post was automatically produced by Jekyll:
-
-You’ll find this post in your \\\`_posts\\\` directory. Go ahead and edit it and re-build the site (devploy) to see your changes. You can rebuild the site in many different ways, but the most common way is to run \\\`jekyll serve --watch\\\`, which launches a web server and auto-regenerates your site when a file is updated.
-
-To add new posts, simply add a file in the \\\`_posts\\\` directory that follows the convention \\\`YYYY-MM-DD-name-of-post.ext\\\` and includes the necessary front matter. Take a look at the source for this post to get an idea about how it works.
-
-Jekyll also offers powerful support for code snippets:
-
-{% highlight ruby %}
-def print_hi(name)
-  puts "Hi, #{name}"
-end
-print_hi('Tom')
-#=> prints 'Hi, Tom' to STDOUT.
-{% endhighlight %}
-
-Check out the [Jekyll docs][jekyll] for more info on how to get the most out of Jekyll. File all bugs/feature requests at [Jekyll’s GitHub repo][jekyll-gh]. If you have questions, you can ask them on [Jekyll’s dedicated Help repository][jekyll-help].
-
-[jekyll]:      http://jekyllrb.com
-[jekyll-gh]:   https://github.com/jekyll/jekyll
-[jekyll-help]: https://github.com/jekyll/jekyll-help
diff --git a/picoCTF-web/web/_posts/202-04-06-welcome.markdown b/picoCTF-web/web/_posts/202-04-06-welcome.markdown
new file mode 100644
index 00000000..295bfb7f
--- /dev/null
+++ b/picoCTF-web/web/_posts/202-04-06-welcome.markdown
@@ -0,0 +1,8 @@
+---
+layout: default
+title: "Welcome!"
+---
+
+This is the CTF challenge that will take place during [hths.hacks()](https://hthshacks.com)!
+Registration and problems will open when the hackathon opens. We're looking forward to seeing
+how many points you earn.
diff --git a/picoCTF-web/web/about.html b/picoCTF-web/web/about.html
index f4496ecc..abd9d7c3 100644
--- a/picoCTF-web/web/about.html
+++ b/picoCTF-web/web/about.html
@@ -4,6 +4,6 @@ title: About
 ---
 <div class="container">
   <div class="row">
-    This is a pretty cool CTF.
+	  A CTF for hths.hacks()!
   </div>
 </div>
diff --git a/picoCTF-web/web/css/main.css b/picoCTF-web/web/css/main.css
index 6b7627c5..97b0a80c 100644
--- a/picoCTF-web/web/css/main.css
+++ b/picoCTF-web/web/css/main.css
@@ -470,8 +470,8 @@ canvas.chartjs-render-monitor {
 /* Generated https://work.smarchal.com/twbscolor/css/e74c3cc0392becf0f1ffbbbc0 */

 .navbar-default {
-  background-color: #337ab7;
-  border-color: #337ab7;
+  background-color: #000a75;
+  border-color: #000a75;
 }
 .navbar-default .navbar-brand {
   color: #eeeeee;
@@ -494,20 +494,20 @@ canvas.chartjs-render-monitor {
 .navbar-default .navbar-nav > .active > a:hover,
 .navbar-default .navbar-nav > .active > a:focus {
   color: #ffffff;
-  background-color: #337ab7;
+  background-color: #000a75;
 }
 .navbar-default .navbar-nav > .open > a,
 .navbar-default .navbar-nav > .open > a:hover,
 .navbar-default .navbar-nav > .open > a:focus {
   color: #ffffff;
-  background-color: #337ab7;
+  background-color: #000a75;
 }
 .navbar-default .navbar-toggle {
-  border-color: #337ab7;
+  border-color: #000a75;
 }
 .navbar-default .navbar-toggle:hover,
 .navbar-default .navbar-toggle:focus {
-  background-color: #337ab7;
+  background-color: #000a75;
 }
 .navbar-default .navbar-toggle .icon-bar {
   background-color: #eeeeee;
@@ -535,6 +535,6 @@ canvas.chartjs-render-monitor {
   .navbar-default .navbar-nav .open .dropdown-menu > .active > a:hover,
   .navbar-default .navbar-nav .open .dropdown-menu > .active > a:focus {
     color: #ffffff;
-    background-color: #337ab7;
+    background-color: #000a75;
   }
 }
diff --git a/picoCTF-web/web/jsx/front-page.jsx b/picoCTF-web/web/jsx/front-page.jsx
index fe723596..b8e5fe73 100644
--- a/picoCTF-web/web/jsx/front-page.jsx
+++ b/picoCTF-web/web/jsx/front-page.jsx
@@ -575,7 +575,7 @@ const LoginForm = React.createClass({
                   name="referrer"
                   defaultValue=""
                   id="referrer"
-                  label="How did you hear about picoCTF?"
+                  label="How did you hear about hths.hacks()?"
                   valueLink={this.props.referrer}
                 >
                   <option value="" disabled={true}>
diff --git a/picoCTF-web/web/jsx/problems.jsx b/picoCTF-web/web/jsx/problems.jsx
index 02104f2b..e4d0f8a8 100644
--- a/picoCTF-web/web/jsx/problems.jsx
+++ b/picoCTF-web/web/jsx/problems.jsx
@@ -437,7 +437,7 @@ const ProblemSubmit = React.createClass({
               buttonBefore={submitButton}
               type="text"
               value={this.state.value}
-              placeholder="picoCTF{FLAG}"
+              placeholder="hthshacks{FLAG}"
               onChange={this.handleChange}
             >
               <span className="input-group-btn">
diff --git a/ansible/roles/pico-web/templates/ctf.nginx.j2 b/ansible/roles/pico-web/templates/ctf.nginx.j2
index 5dd22fcd..271fe859 100644
--- a/ansible/roles/pico-web/templates/ctf.nginx.j2
+++ b/ansible/roles/pico-web/templates/ctf.nginx.j2
@@ -41,7 +41,7 @@ server {

         # allows direct requests from the shell_server
         allow {{ pico_internal_allow }};
-        deny all;
+        allow all;

         # http basic auth
         auth_basic "Restricted";

EOF

cat<<EOF >> /home/ctf/shell.patch
diff --git a/ansible/group_vars/local_development/vars.yml b/ansible/group_vars/local_development/vars.yml
index 31ee2c94..91d94289 100644
--- a/ansible/group_vars/local_development/vars.yml
+++ b/ansible/group_vars/local_development/vars.yml
@@ -1,36 +1,36 @@
----
 # Variables shared across all development hosts

 # vagrant/vagrant is the default configuration for Vagrant boxes
-ansible_user:     vagrant
-ansible_ssh_pass: vagrant
+ansible_user:     ctf
+ansible_ssh_pass: $PASSWD


 ##
 # Web settings (env specific)
 ##
-web_fqdn: "localhost"
-web_address: "http://{{ lookup('env','WIP') or '192.168.2.2' }}"
-nginx_server_name: "_"
+web_fqdn: "$WEB_URL"
+web_address: "https://$WEB_URL"
+nginx_server_name: "{{ web_fqdn }}"
 flask_app_server_name: "{{ web_fqdn }}"
 web_address_internal: "{{ web_address }}"

 # optional web automation
-enable_basic_auth:      False
+enable_basic_auth:      True
 auto_add_shell:         False
 auto_load_problems:     False
 auto_start_competition: False

+net_outbound_limit: "40mbit"

 ###
 # Shell Settings (env specific)
 ###
-shell_hostname: "{{ lookup('env','SIP') or '192.168.2.3' }}"
+shell_hostname: "$SHELL_URL"
 shell_name: Local-Development-Shell   # no spaces
 shell_ip: "{{ shell_hostname }}"
 shell_user: "{{ ansible_user }}"
 shell_pass: "{{ ansible_ssh_pass }}"
-shell_manager_deploy_secret: "**insecure-secret**"
+shell_manager_deploy_secret: "$PASSWD"

 # default insecure "vagrant" password (mkpasswd --method=SHA-512 vagrant)
 shell_admin_password_crypt: "\\\$6\\\$0GcSqMClzx\\\$qEKEiL78VE/Xe0gzuGGuWyUqAlZMObkGnRYwHo4.vSUlvWt6aA7PBH1oGDsOQlykFNScEdEhrirD5oFLOHH011"
diff --git a/ansible/inventories/local_development b/ansible/inventories/local_development
index 304bd8c5..35533d73 100644
--- a/ansible/inventories/local_development
+++ b/ansible/inventories/local_development
@@ -1,4 +1,3 @@
-# Inventory to provision/administer the local development environment
 # Used by the toplevel Vagrantfile
 # Also for manual provisioning when ansible is used within a vm

@@ -10,10 +9,10 @@ web
 # In a development environment, or simple deployment collocate the database
 # with the web server
 [db]
-dev_web     ansible_connection=local    hostname=pico-local-dev-web-db
+dev_web     ansible_connection=local    hostname=ctf-web ansible_host=$WEB_URL shell_ip=$SHELL_IP

 [shell]
-dev_shell   ansible_connection=local    hostname=pico-local-dev-shell
+dev_shell   ansible_connection=local    hostname=ctf-shell ansible_host=$SHELL_URL shell_ip=$SHELL_IP

 [web]
-dev_web     ansible_connection=local    hostname=pico-local-dev-web-db
+dev_web     ansible_connection=local    hostname=ctf-web ansible_host=$WEB_URL shell_ip=$SHELL_IP
diff --git a/picoCTF-shell/hacksport/problem.py b/picoCTF-shell/hacksport/problem.py
index e1c09d10..6df6ae9d 100644
--- a/picoCTF-shell/hacksport/problem.py
+++ b/picoCTF-shell/hacksport/problem.py
@@ -14,11 +14,11 @@ from shell_manager.util import EXTRA_ROOT

 XINETD_SCRIPT = """#!/bin/bash
 cd \\\$(dirname \\\$0)
-exec timeout -sKILL 3m %s
+exec timeout -sKILL 3m "%s"
 """
 XINETD_WEB_SCRIPT = """#!/bin/bash
 cd \\\$(dirname \\\$0)
-%s
+"%s"
 """

EOF

if [[ "$SERVER" == "web" ]]
then
    cd /home/ctf/picoCTF
    git apply ../web.patch

    cd /home/ctf/picoCTF/ansible
    echo "$PASSWD" | ansible-playbook --ask-sudo-pass -e "web_address=https://$WEB_URL web_address_internal=https://$WEB_URL shell_hostname=$SHELL_URL shell_host=$SHELL_URL shell_port=22" -i inventories/local_development -v -l web,db site.yml
elif [[ "$SERVER" == "shell" ]]
then
    cd /home/ctf/picoCTF
    git apply ../shell.patch

    cd /home/ctf/picoCTF/ansible
    echo "$PASSWD" | ansible-playbook --ask-sudo-pass -e "web_address=https://$WEB_URL web_address_internal=https://$WEB_URL shell_hostname=$SHELL_URL shell_host=$SHELL_URL shell_port=22" -i inventories/local_development -v -l shell site.yml
    sudo pip3 install -e /home/ctf/picoCTF/picoCTF-shell
    sudo shell_manager config local set -f hostname -v "$SHELL_URL"
    sudo shell_manager config local set -f web_server -v "https://$WEB_URL"
    sudo shell_manager config local set -f rate_limit_bypass_key -v "$PASSWD"
    sudo shell_manager config shared set -f deploy_secret -v "$PASSWD"
    mkdir /home/ctf/problems
    chown ctf /home/ctf/problems
else
    echo "Invalid server command"
    exit 1
fi
EOT
echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
echo "PasswordAuthentication yes" >> /etc/ssh/ssh_config
systemctl restart ssh

add-apt-repository universe
add-apt-repository ppa:certbot/certbot -y
apt-get install certbot python-certbot-nginx -y

if [[ $SERVER == "web" ]]
then
    DOMAINS="$WEB_URL"
elif [[ $SERVER == "shell" ]]
then
    DOMAINS="$SHELL_URL"
fi

certbot --nginx --non-interactive --agree-tos --domains $DOMAINS --redirect --no-eff-email --email contact@hthshacks.com

echo
echo
echo
echo
echo
echo "Congrats! The $SERVER component is installed. Your password is $PASSWD, and you should ssh login as ctf. Check above to ensure there are no errors."
echo "Make sure you log into $WEB_URL, go the management->Shell Server, and add the shell server with all the correct info, using the ctf username and password."
echo "MAKE SURE IT USES HTTPS!"
echo
echo "Also, to use shell_manager, use sudo su. If you try using sudo on the ctf account, it will error about file size limit exceeding."
