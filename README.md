# baseline_compliance

#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with baseline_compliance](#setup)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Gotchas - Things to watch out for](#usage)

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

### Creating baseline modules

For each class that is part of a node's main catalog, the baseline catalog
compiler will look for an equivilant in the `baseline` environment. If one is
found, it will be added for compilation as part of the baseline catalog.

Therefor, if you want to have a baseline Apache configuration, just create an
**apache** module with an **apache** class, add it to the `baseline`
environment, and include any base resources you want to enforce in the apache
class. If the node has Class['apache'] in its catalog, your baseline
Class['apache'] will automatically be added to the baseline catalog.

Note, baseline classes **do not** support class parameters.  One important
point of using the baseline catalog compiler is any module should be able to be
used as part of the mainline catalog. Since we cannot gaurantee class
parameters will match between the main module used and the baseline module,
it's far better to just not use parameters at all.  Hiera, however, is still
available for parameter data bindings.

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

## Example Baseline Environment

This control repository has a baseline enviornment that deploys the [os_hardening](https://forge.puppet.com/hardening) set of modules: [http://github.com/ccaum/puppet-control/tree/baseline](http://github.com/ccaum/puppet-control/tree/baseline)


## Gotchas

Currently, custom facts in the `baseline` enviornment will not work. When the
Puppet agent performs its pluginsync at the beginning of the run, it only syncs
the facts from its assigned environment. Any module you use in the `baseline`
environment that uses custom facts should have those facts added to the node's
assigned environment.
