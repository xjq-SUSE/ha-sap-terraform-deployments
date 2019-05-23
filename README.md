# Automated SAP/HA Deployments in Public/Private Clouds with Terraform

[![Build Status](https://travis-ci.org/SUSE/ha-sap-terraform-deployments.svg?branch=master)](https://travis-ci.org/SUSE/ha-sap-terraform-deployments)

## Getting started

This project is organized in folders containing the Terraform configuration files per Public or Private Cloud providers, each also containing documentation relevant to the use of the configuration files and to the cloud provider itself.

The documentation of terraform and the cloud providers included in this repository is not intended to be complete, so be sure to also check the [documentation provided by terraform](https://www.terraform.io/docs) and the cloud providers.

Also check the [Terraform Workspaces workflow](workspaces-workflow.md) document for a guide on how to use Terraform Workspaces when using shared remote Terraform state files in major public cloud providers.

## Deploying with Salt

In order to execute the deployment with salt follow the instructions in [README](pillar_examples/README.md)

## Contributing

If you are interested in contributing to this project, fork this repository, clone your fork, write your code and send a pull request.

## Terraform version

All Terraform configurations were tested with the 0.11.14 version
