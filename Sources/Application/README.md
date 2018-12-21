## Kitura HyperSecure DBaaS Starter

Basic Swift Kitura web project using a HyperSecure DBaaS.

[![](https://img.shields.io/badge/bluemix-powered-blue.svg)](https://cloud.ibm.com)
![Platform](https://img.shields.io/badge/platform-SWIFT-lightgrey.svg?style=flat)

### Table of Contents
* [Summary](#summary)
* [Requirements](#requirements)
* [Configuration](#configuration)
* [Run](#run)
* [Debug](#debug)

<a name="summary"></a>
### Summary

This stater provides the initial configuration to quickly get you up and running a Kitura Web Server and integration with a HyperSecure DBaaS.

This starter comes equipped with a basic set of web serving UI files.  

- `public/index.html`
- `public/js/bundle.js`
- `public/css/default.css`

#### HyperSecure DBaaS

A hyper-secure DBaaS is the next evolution of data storage in a security-rich database environment. It allows you to retain your data in a fully-encrypted database without the need for specialized skills.

A hyper-secure DBaaS provides significant additional protection against security breaches by delivering pervasive encryption capability plus the additional benefits of secure service container technology.

Pervasive encryption is a consumable approach to enable extensive encryption of data in flight and at rest to substantially simplify and speed encryption while achieving compliance mandates. Pervasive encryption is available with IBM HyperSecure DBaaS.

The IBM Secure Service Container delivers a hyper-secure environment, containing its own embedded security mechanisms for securely hosting the DBaaS as well as pervasive encryption. It prevents the threat of rogue insiders and snooping by privileged users, allowing only the data owner (client) to control the access to the data (no sysadmin access).

The IBM HyperSecure DBaaS is based on LinuxONE hardware architecture known for its quality of service (reliability/resilience), and its capability for handling very large amounts of information with high performance.

<a name="requirements"></a>
### Requirements
#### Local Development Tools Setup (optional)

- On Linux, install the [Swift toolchain](http://www.swift.org) version 4.0
- On macOS, install [Xcode](https://developer.apple.com/download) 9.0+


#### IBM Cloud development tools setup (optional)

1. Install [Docker](http://docker.io) on your machine.
2. Install the [IBM Cloud CLI](https://cloud.ibm.com/docs/cli/index.html)
3. Install the plugin with:

  `bx plugin install dev -r bluemix`


#### IBM Cloud DevOps setup (optional)

[![Create Toolchain](https://cloud.ibm.com/devops/graphics/create_toolchain_button.png)](https://cloud.ibm.com/devops/setup/deploy/)

[IBM Cloud DevOps](https://www.ibm.com/cloud-computing/bluemix/devops) services provides toolchains as a set of tool integrations that support development, deployment, and operations tasks inside Bluemix. The "Create Toolchain" button creates a DevOps toolchain and acts as a single-click deploy to IBM Cloud including provisioning all required services.

***Note** you must publish your project to [Github](https://github.com/) for this to work.



<a name="configuration"></a>
### Configuration

Your application configuration information is stored in `config.json`. If you selected services added to your project, you will see Cloudant, Object Storage, and other services with their connection information such as username, password, and hostname listed here. This is useful for connecting to remote services while running your application locally.

When you push your application to IBM Cloud, however, these values are no longer used, and instead IBM Cloud automatically connects to those bound services through the use of environment variables. The `config.json` file has been added to the `.gitignore` file so you don't accidently check in the secret credentials.


<a name="run"></a>
### Run
#### Using IBM Cloud development CLI
The IBM Cloud development plugin makes it easy to compile and run your application if you do not have all of the tools installed on your computer yet. Your application will be compiled with Docker containers. To compile and run your app, run:

```bash
bx dev build
bx dev run
```


#### Using your local development environment
Once the Swift toolchain has been installed, you can compile a Swift project with:

```bash
sudo apt-get install clang libicu-dev
sudo apt-get install openssl libssl-dev
sudo apt-get install libcurl4-openssl-dev
docker pull jinmingjian/docker-sourcekite
wget https://swift.org/builds/swift-4.0.3-release/ubuntu1604/swift-4.0.3-RELEASE/swift-4.0.3-RELEASE-ubuntu16.04.tar.gz
swift build
swift run
```

Your sources will be compiled to your `.build/debug` directory.




##### Endpoints

Your application is running at: `http://localhost:8080/` in your browser.




<a name="debug"></a>
### Debug

#### Using IBM Cloud development CLI
To build and debug your app, run:
```bash
bx dev build --debug
bx dev debug
```
