[![](https://img.shields.io/badge/IBM%20Cloud-powered-blue.svg)](https://bluemix.net)
[![Platform](https://img.shields.io/badge/platform-ios_swift-lightgrey.svg?style=flat)](https://developer.apple.com/swift/)

# Create a Hyper Protect secure Swift application using Kitura

In this code pattern, you will create a server-side application using [Kitura](http://www.kitura.io/) in Swift and Hyper Protect Services. Hyper Protect Services bring continuous security to IBM Cloud, so all data is encrypted in flight, at rest, and in use.

When you have completed this code pattern, you will understand how to:

* Provision and integrate Hyper Protect Services
* Generate an application with files for deploying to Kubernetes, Cloud Foundry or a DevOps Pipeline
* Generate an application with files for monitoring and distributed trace using App Metrics
* Connect to additional provisioned services

> As an alternative to the deployment options documented below, you can [create this project as a starter kit](https://console.bluemix.net/developer/appledevelopment/create-app?defaultDeploymentToolchain=&defaultLanguage=SWIFT&env_id=ibm%3Ayp%3Aus-south&navMode=catalog&starterKit=522c52e7-f9ed-3f95-a9bd-885fc881aa6e) on IBM Cloud, which injects service credentials into a custom fork of this pattern after you have provisioned the database with your specifications. Use this method to deploy to IBM Cloud with the click of a button.

> You will need to provision the Hyper Protect DBaaS service yourself, providing paramteres like password. Make sure to select a service plan for MongoDB, as this sample does not yet work with its PostgreSQL offering.

## Project contents

This application has been generated with the following capabilities and services, which are described in full in their respective sections below:

* [CloudEnvironment](#configuration)
* [Static web file serving](#static-web-file-serving)
* [OpenAPI / Swagger endpoint](#openapi--swagger-endpoint)
* [Example endpoints](#example-endpoints)
* [Embedded metrics dashboard](#embedded-metrics-dashboard)
* [Docker files](#docker-files)
* [Iterative Development](#iterative-development)
* [IBM Cloud deployment](#ibm-cloud-deployment)

## Requirements

* [Swift 4](https://swift.org/download/)

## Run

To build and run the application:
1. `swift build`
1. `swift run`

### Docker

A description of the files related to Docker can be found in the [Docker files](#docker-files) setion. To build the two docker images, run the following commands from the root directory of the project:
* `docker build -t myapp-run .`
* `docker build -t myapp-build -f Dockerfile-tools .`
You may customize the names of these images by specifying a different value after the `-t` option.

To compile the application using the tools docker image, run:
* `docker run -v $PWD:/swift-project -w /swift-project myapp-build /swift-utils/tools-utils.sh build release`

To run the application:
* `docker run -it -p 8080:8080 -v $PWD:/swift-project -w /swift-project myapp-run sh -c .build-ubuntu/release/swiftkiturahyperprotectdbaas`

### Kubernetes

To deploy your application to your Kubernetes cluster, run `helm install --name myapp .` in the `/chart/swiftkiturahyperprotectbaas` directory. You need to make sure you change the `repository` variable in your `chart/swiftkiturahyperprotectdbaas/values.yaml` file points to the docker image containing your runnable application.

## Configuration

Your application configuration information for any services is stored in the `localdev-config.json` file in the `config` directory. This file is in the `.gitignore` to prevent sensitive information from being stored in git. The connection information for any configured services that you would like to access when running locally, such as username, password and hostname, is stored in this file.

The application uses the [CloudEnvironment package](https://github.com/IBM-Swift/CloudEnvironment) to read the connection and configuration information from the environment and this file. It uses `mappings.json`, found in the `config` directory, to communicate where the credentials can be found for each service.

If the application is running locally, it can connect to IBM Cloud services using unbound credentials read from this file. If you need to create unbound credentials you can do so from the IBM Cloud web console ([example](https://console.ng.bluemix.net/docs/services/Cloudant/tutorials/create_service.html#creating-a-service-instance)), or using the CloudFoundry CLI [`cf create-service-key` command](http://cli.cloudfoundry.org/en-US/cf/create-service-key.html).

When you push your application to IBM Cloud, these values are no longer used, instead the application automatically connects to bound services using environment variables.

### Iterative Development

The `iterative-dev.sh` script is included in the root of the generated Swift project and allows for fast & easy iterations for the developer. Instead of stopping the running Kitura server to see new code changes, while the script is running, it will automatically detect changes in the project's **.swift** files and recompile the app accordingly.

To use iterative development:
* For native OS, execute the `./iterative-dev.sh` script from the root of the project.
* With docker, shell into the tools container mentioned above, and run the `./swift-project/iterative-dev.sh` script.  File system changes are detected using a low-tech infinitely looping poll mechanism, which works in both local OS/filesystem and across host OS->Docker container volume scenarios.

## Deploy to IBM Cloud

You can deploy your application to IBM Cloud using the [CloudFoundry CLI](#cloudfoundry-cli).

You can deploy the application to IBM Cloud using the CloudFoundry command-line:
1. Install the Cloud Foundry command-line (https://docs.cloudfoundry.org/cf-cli/install-go-cli.html)
1. Ensure all configured services have been provisioned
1. Run `cf push` from the project root directory

The Cloud Foundry CLI will not provision the configured services for you, so you will need to do this manually using the IBM Cloud web console ([example](https://console.ng.bluemix.net/docs/services/Cloudant/tutorials/create_service.html#creating-a-service-instance)) or the CloudFoundry CLI (`cf create-service` command)[http://cli.cloudfoundry.org/en-US/cf/create-service.html]. The service names and types will need to match your [configuration](#configuration).

## Service descriptions

### Static web file serving

This application includes a `public` directory in the root of the project. The contents of this directory will be served as static content using the built-in Kitura [StaticFileServer module](https://github.com/IBM-Swift/Kitura/wiki/Serving-Static-Content).

This content is hosted on `/`. For example, if you want to view `public/myfile.html` and the application is hosted at https://localhost:8080, go to https://localhost:8080/myfile.html.

### OpenAPI / Swagger endpoint

This application hosts an endpoint for serving the OpenAPI Swagger definition for this application. It expects the definition file to be located in `definitions/swiftkiturahyperprotectdbaas.yaml`.

The endpoint is hosted on `/swagger/api`. For example, if the application is hosted at https://localhost:8080, go to https://localhost:8080/swagger/api.

### Example endpoints

This application includes an OpenAPI Swagger definition and routes for a Product example resource. The OpenAPI Swagger definition is located in the `definitions/swiftkiturahyperprotectdbaas.yaml` directory.

The specification of this interface is made available through an embedded Swagger UI hosted on `/explorer`. For example, if the application is hosted at https://localhost:8080, go to https://localhost:8080/explorer.

The Swagger UI will document the paths and http methods that are supported by the application.

### Embedded metrics dashboard

This application uses the [SwiftMetrics package](https://github.com/RuntimeTools/SwiftMetrics) to gather application and system metrics.

These metrics can be viewed in an embedded dashboard on `/swiftmetrics-dash`. The dashboard displays various system and application metrics, including CPU, memory usage, HTTP response metrics and more.

### Docker files

The application includes the following files for Docker support:
* `.dockerignore`
* `Dockerfile`
* `Dockerfile-tools`

The `.dockerignore` file contains the files/directories that should not be included in the built docker image. By default this file contains the `Dockerfile` and `Dockerfile-tools`. It can be modified as required.

The `Dockerfile` defines the specification of the default docker image for running the application. This image can be used to run the application.

The `Dockerfile-tools` is a docker specification file similar to the `Dockerfile`, except it includes the tools required for compiling the application. This image can be used to compile the application.

Details on how to build the docker images, compile and run the application within the docker image can be found in the [Run section](#run).

### IBM Cloud deployment

Your application has a set of cloud deployment configuration files defined to support deploying your application to IBM Cloud:
* `manifest.yml`
* `.bluemix/toolchain.yml`
* `.bluemix/pipeline.yml`

The [`manifest.yml`](https://console.ng.bluemix.net/docs/manageapps/depapps.html#appmanifest) defines options which are passed to the Cloud Foundry `cf push` command during application deployment.

## Next steps

Leverage the [IBM Cloud DevOps](https://console.ng.bluemix.net/docs/services/ContinuousDelivery/index.html) service, which provides toolchains as a set of tool integrations that support development, deployment, and operations tasks inside IBM Cloud, for both Cloud Foundry and Kubernetes applications.

## License

This code pattern is licensed under the Apache License, Version 2. Separate third-party code objects invoked within this code pattern are licensed by their respective providers pursuant to their own separate licenses. Contributions are subject to the [Developer Certificate of Origin, Version 1.1](https://developercertificate.org/) and the [Apache License, Version 2](https://www.apache.org/licenses/LICENSE-2.0.txt).

[Apache License FAQ](https://www.apache.org/foundation/license-faq.html#WhatDoesItMEAN)
