# baseline_compliance

#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with baseline_compliance](#setup)
3. [Usage - Configuration options and additional functionality](#usage)

## Description

This module provides a method for using Puppet code to define a compliance
baseline that is intelligently applied to your existing Puppet code. This
enables you to write Puppet modules that enforce configurations that comply
with internal and regulatory compliance policies without suffering through
duplicate resource errors nor resorting to spaghetti code.

## Setup

To configure your Puppet master to apply compliant baselines, you'll need to
configure the Puppet master to use the `baselinecompliance` catalog terminus.
This can be done with the following command as root.

        $ puppet config set catalog_terminus baselinecompliance

Now all catalog compilation will first compile a catalog from the `baseline`
environment, and then intelligently merge it with the catalog compiled for 
the environment assigned to the node.

## Usage
        
Create a new environment called `baseline`. This environment can be managed
with r10k just like any other environment you already manage. 

### Monitoring compliance enforcement & overwites

Below are the scenarios the baselinecompiler catalog terminus will recognize
and how it will handle it. Each time the catalog terminus runs into each of the
scenarios, a log will be present in the agent's run report.

* If a resource exists in the baseline catalog, but not the main catalog, the
resource will be added to the main catalog

* If a resource exists in both catalogs, but the baseline resource has a parameter
not present in the main catalog's instance of the resource, the parameter will
be added to the main catalog's resource instance.

* If a resource exists in both catalogs and they both have a parameter with
different values, the main catalog's resource's parameter  will take precidence
over the baseline's resources' parameter.

Each Puppet agent run will log each scneario if they occur.  For example:

        Info: Using configured environment 'production'
        Info: Retrieving pluginfacts
        Info: Retrieving plugin
        Notice: Compiled catalog for master.vm in environment production in 8.78 seconds
        Notice: Compiled catalog for master.vm in environment baseline in 0.03 seconds
        Info: Adding baseline Notify[message] resource to catalog
        Warning: Resource File[/tmp/example]'s parameter 'group' value of 'pe-puppet' is overwriting baseline value of '0'
        Info: Adding baseline parameter 'mode' with value '0755' to resource File[/tmp/example]
        Info: Caching catalog for master.vm
        Info: Applying configuration version '1468390945'
