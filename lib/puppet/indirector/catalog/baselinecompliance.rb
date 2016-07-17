require 'puppet/node'
require 'puppet/resource/catalog'
require 'puppet/parser/baseline_compiler'
require 'puppet/indirector/catalog/compiler'

class Puppet::Resource::Catalog::Baselinecompliance < Puppet::Resource::Catalog::Compiler

  def find(request)
    catalog = super(request)
    baseline_node = node_from_request(request)

    catalog_classes = catalog.resources.find_all { |r| r.type == 'Class' }

    # Set up a node resource with the baseline environment rather than whatever the classification
    # process came up with.
    baseline_modulepath = Puppet.settings.value(:modulepath, :baseline).split(':')
    baseline_modulepath.delete('/opt/puppetlabs/puppet/modules')
    baseline_manifestdir = Puppet.settings.value(:manifest, :baseline)
    baseline_environment = Puppet::Node::Environment.create(:baseline, baseline_modulepath, baseline_manifestdir)
    baseline_node.environment = baseline_environment

    # Figure out which classes in the mainline catalog have baseline equivilants.
    # Add those classes to the node for baseline compilation.
    baseline_parser = Puppet::Parser::BaselineCompiler.new(baseline_node)
    baseline_node.classes = baseline_parser.find_baseline_classes(catalog_classes)

    # Modify the request to contain our modified node and environment
    baseline_request = request
    baseline_request.options[:use_node] = baseline_node
    baseline_request.environment = baseline_environment

    # Compile the baseline catalog
    baseline_catalog = super(baseline_request)

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
            Puppet.warning "Resource #{catalog_resource}'s parameter '#{catalog_parameter}' value of '#{catalog_resource[catalog_parameter]}' is overwriting baseline value of '#{baseline_resource[catalog_parameter]}'"
          end
        end

        # If a resource exists in both catalogs and the baseline resource manages parameters 
        # that the maineline resource doesn't, add the baseline parameters to the mainline resource.
        baseline_resource.each do |baseline_parameter|
          unless catalog_resource.include?(baseline_parameter)
            Puppet.info "Adding baseline parameter '#{baseline_parameter}' with value '#{baseline_resource[baseline_parameter]}' to resource #{baseline_resource}"
            catalog_resource[baseline_parameter] = baseline_resource[baseline_parameter]
          end
        end
        
      else
        Puppet.info "Adding baseline #{baseline_resource} resource to catalog"
        catalog.add_resource baseline_resource
      end
    end

    catalog
  end
end
