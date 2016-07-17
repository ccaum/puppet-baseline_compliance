require 'puppet/transaction'
require 'puppet/indirector/json'

class Puppet::Transaction::Baselinereport
  extend Puppet::Indirector

  indirects :baselinereport, :terminus_class => :json

  def initialize(node, mainline_configversion = nil, baseline_configversion = nil)
    @mainline_configversion = mainline_configversion
    @baseline_configversion = baseline_configversion
    @node = node
    @events = Array.new
    @time = Time.new
  end

  def resource_added(resource)
    @events << {:type => :resource_addition, :resource => resource}
    Puppet.info "Adding baseline #{resource} resource to catalog"
  end

  def parameter_added(resource, parameter, value)
    @events << {:type => :parameter_addition, :resource => resource, :parameter => parameter, :value => value}
    Puppet.info "Adding baseline parameter '#{parameter}' with value '#{value}' to resource #{resource}"
  end

  def parameter_overwritten(resource, parameter, baseline_value, mainline_value)
    @events << {:type => :parameter_overwrite, :resource => resource, :parameter => parameter, 
                :baseline_value => :baseline_value, :overwrite_value => mainline_value}
    Puppet.warning "Resource #{resource}'s parameter '#{parameter}' value of '#{baseline_value}' is overwriting baseline value of '#{mainline_value}'"
  end

  def name
    "#{@node.name}_baseline_report"
  end

  def to_data_hash
    {
      'events' => @events,
      'mainline_configversion' => @mainline_configversion,
      'baseline_configversion' => @baseline_configversion,
      'node' => @node.name,
      'time' => @time,
    }
  end
end
