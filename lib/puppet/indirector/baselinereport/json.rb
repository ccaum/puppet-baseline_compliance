require 'puppet/indirector/terminus'
require 'puppet/indirector'
require 'puppet/indirector/json'
require 'puppet/transaction/baselinereport'

class Puppet::Transaction::Baselinereport::Json < Puppet::Indirector::JSON
  desc "Save baseline compilation report to json"
end
