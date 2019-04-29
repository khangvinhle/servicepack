You can see a more detailed guide here: [https://www.openproject.org/download-and-installation/#installation](https://www.openproject.org/download-and-installation/#installation)

We will guide you how to install Open Project on Ubuntu 18.04.

*You must execute all steps as the root user.*

---

1. **Import the packager.io repository signing key**

   ```shell
   $ sudo wget -qO- https://dl.packager.io/srv/opf/openproject-ce/key | sudo apt-key add -
   ```

2. **Ensure that apt-transport-https is installed**

   ```shell
   $ sudo apt-get install apt-transport-https
   ```

3. **Ensure that universe package source is added**

   ```shell
   $ sudo add-apt-repository universe
   ```

4. **Add the OpenProject package source**

   ```shell
   $ sudo wget -O /etc/apt/sources.list.d/openproject-ce.list \
     https://dl.packager.io/srv/opf/openproject-ce/stable/8/installer/ubuntu/18.04.repo
   ```

5. **Install the OpenProject Community Edition package**

   ```shell
   $ apt-get update
   $ apt-get install openproject
   ```
