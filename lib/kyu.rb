require 'eventmachine'
require 'aws-sdk'
require 'logger'
require 'json'

require 'kyu/version'
require 'kyu/worker'
require 'kyu/manager'
require 'kyu/postman'

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
end
