require 'puppet/parser/compiler'

class Puppet::Parser::BaselineCompiler < Puppet::Parser::Compiler
  def searchable_class_name(klass)
    klass.name.split('/')[-1].downcase
  end

  def find_baseline_classes(mainline_classes)
    @node_scope = topscope
    baseline_classes = Hash.new

    evaluate_main

    mainline_classes.select do |mainline_class|
      # Calling find_hostclass evaluates the entire class. A lazy load would be better
      @node_scope.find_hostclass(searchable_class_name(mainline_class))
    end.each do |c|
      baseline_classes[searchable_class_name(c)] = Hash.new
    end

    baseline_classes
  end
end
