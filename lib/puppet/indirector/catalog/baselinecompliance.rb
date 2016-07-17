require 'puppet/node'
require 'puppet/transaction/baselinereport'
require 'puppet/resource/catalog'
require 'puppet/parser/baseline_compiler'
require 'puppet/indirector/catalog/compiler'

class Puppet::Resource::Catalog::Baselinecompliance < Puppet::Resource::Catalog::Compiler
  def baseline_datadir
    baseline_datadir = File.join(Puppet.settings[:client_datadir], 'baseline')
    unless File.exists?(baseline_datadir)
      Dir.mkdir baseline_datadir
    end

    baseline_datadir
  end

  def find(request)
    # Compile the mainline catalog
    catalog = super(request)
    baseline_node = node_from_request(request)

    # Set up a node resource with the baseline environment rather than whatever the classification
    # process came up with.
    baseline_modulepath = Puppet.settings.value(:modulepath, :baseline).split(':')
    baseline_modulepath.delete('/opt/puppetlabs/puppet/modules')
    baseline_manifestdir = Puppet.settings.value(:manifest, :baseline)
    baseline_environment = Puppet::Node::Environment.create(:baseline, baseline_modulepath, baseline_manifestdir)
    baseline_node.environment = baseline_environment

    # Figure out which classes in the mainline catalog have baseline equivilants.
    # Add those classes to the node for baseline compilation.
    catalog_classes = catalog.resources.find_all { |r| r.type == 'Class' }
    baseline_parser = Puppet::Parser::BaselineCompiler.new(baseline_node)
    baseline_node.classes = baseline_parser.find_baseline_classes(catalog_classes)

    # Modify the request to contain our modified node and environment
    baseline_request = request
    baseline_request.options[:use_node] = baseline_node
    baseline_request.environment = baseline_environment
    baseline_request.key = 'baseline' # This is important when saving the report

    # Compile the baseline catalog
    baseline_catalog = super(baseline_request)

    baseline_report = Puppet::Transaction::Baselinereport.new(baseline_node)

    baseline_catalog.resources.each do |baseline_resource|
      # If a resource exists in the baseline catalog, but not the mainline catalog, add it.
      # If it exists in both, figure out how to merge the parameters.
      if catalog_resource = catalog.resources.find { |r|
          baseline_resource.name == r.name and baseline_resource.type == r.type
        }

        # If a resource exists in both catalogs and both manage a subset of parameters, overwrite 
        # the baseline value with the mainline.
        catalog_resource.each do |catalog_parameter|
          if baseline_resource.include?(catalog_parameter) and (baseline_resource[catalog_parameter] != catalog_resource[catalog_parameter])
            baseline_report.parameter_overwritten(baseline_resource, catalog_parameter, baseline_resource[catalog_parameter], catalog_resource[catalog_parameter])
          end
        end

        # If a resource exists in both catalogs and the baseline resource manages parameters 
        # that the maineline resource doesn't, add the baseline parameters to the mainline resource.
        baseline_resource.each do |baseline_parameter|
          unless catalog_resource.include?(baseline_parameter)
            baseline_report.parameter_added(baseline_resource, baseline_parameter, baseline_resource[baseline_parameter])
            catalog_resource[baseline_parameter] = baseline_resource[baseline_parameter]
          end
        end
        
      else
        baseline_report.resource_added(baseline_resource)
        catalog.add_resource baseline_resource
      end
    end

    # Save the baseline compilation report
    Puppet::Transaction::Baselinereport.indirection.save(baseline_report)

    catalog
  end
end
