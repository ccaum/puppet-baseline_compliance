require 'puppet/node'
require 'puppet/resource/catalog'
require 'puppet/indirector/catalog/compiler'

class Puppet::Resource::Catalog::Baselinecompliance < Puppet::Resource::Catalog::Compiler

  def find(request)
    catalog = super(request)
    baseline_node = node_from_request(request)

    baseline_modulepath = Puppet.settings.value(:modulepath, :baseline)
    baseline_manifestdir = Puppet.settings.value(:manifest, :baseline)
    baseline_environment = Puppet::Node::Environment.create(:baseline, [baseline_modulepath], baseline_manifestdir)
    baseline_node.environment = baseline_environment
    baseline_node.classes = Hash.new

    baseline_request = request
    baseline_request.options[:use_node] = baseline_node
    baseline_request.environment = baseline_environment

    baseline_catalog = super(baseline_request)

    baseline_catalog.resources.each do |baseline_resource|
      if catalog_resource = catalog.resources.find { |r|
          baseline_resource.name == r.name and baseline_resource.type == r.type
        }

        catalog_resource.each do |catalog_parameter|
          if baseline_resource.include?(catalog_parameter) and (baseline_resource[catalog_parameter] != catalog_resource[catalog_parameter])
            Puppet.warning "Resource #{catalog_resource}'s parameter '#{catalog_parameter}' value of '#{catalog_resource[catalog_parameter]}' is overwriting baseline value of '#{baseline_resource[catalog_parameter]}'"
          end
        end

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
