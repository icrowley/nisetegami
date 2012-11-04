require 'roadie'
require 'liquid'

require 'nisetegami/action_mailer_extensions'
require 'nisetegami/liquid_template_handler'
require 'nisetegami/ar_template_resolver'
require 'nisetegami/asset_provider'
require 'nisetegami/exceptions'
require 'nisetegami/mapping'
require 'nisetegami/utils'
require 'nisetegami/engine'

module Nisetegami

  mattr_reader :layouts_path

  mattr_reader :mapping
  @@mapping = Nisetegami::Mapping.new

  def self.configure
    yield self
  end

  # optional block to cast a thing (String, Symbol)
  # into a class with liquid_methods
  def self.cast(&block)
    @@cast ||= ->(thing){ defined?(thing) == 'constant' ? thing : thing.to_s.constantize }
    block_given? ? @@cast = block : @@cast
  end

  def self.register(*args)
    @@mapping.register(*args)
  end

  def self.populate!
    @@mapping.populate!
  end

  class << self
    %w(text html).each do |format|
      define_method("#{format}_layouts") do
        class_variable_get(:"@@#{format}_layouts") || Nisetegami::Utils.filenames(Nisetegami.layouts_path, format).tap do |layouts|
          class_variable_set(:"@@#{format}_layouts", layouts) if Rails.env.production?
        end
      end
    end
  end

end