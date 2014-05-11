require 'eventmachine'
require 'aws-sdk'
require 'logger'
require 'json'
require 'timeout'

require_relative 'kyu/version'
require_relative 'kyu/worker'
require_relative 'kyu/manager'
require_relative 'kyu/postman'

# Required for Ruby < 2.0. For more information see:
# http://ruby.awsblog.com/post/Tx16QY1CI5GVBFT/Threading-with-the-AWS-SDK-for-Ruby
if RUBY_VERSION < '2'
  AWS.eager_autoload!( AWS::Core )
  AWS.eager_autoload!( AWS::SQS )
end

module Kyu
  def stringify_exception( exception )
    backtrace = exception.backtrace.join( ' | ' )
    "(#{exception.class}) #{exception.message}; <trace>#{backtrace}</trace>"
  end

  def self.infer_class_from_filename( filename )
    class_name = camel_case( File.basename( filename, '.rb' ) )
    Kernel.const_get( class_name )
  rescue NameError => err
    raise err
  end

  def self.camel_case( str )
    return str if str !~ /_/ && self =~ /[A-Z]+.*/
    str.split( '_' ).map { |e| e.capitalize }.join
  end
end
