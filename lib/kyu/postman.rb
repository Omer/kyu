require 'aws-sdk'
require 'logger'
require 'json'

module Kyu
  module Postman
    class << self
      def send_message( queue_name, msg, options={} )
        error_callback = options.fetch( :error_callback, ->( err ){} )
        logger = options.fetch( :logger, Logger.new( '/dev/null' ) )

        queue = fetch_queue( queue_name, logger, error_callback )
        return unless queue
        msg_json = msg.to_json
        logger.info( "Sending message '#{msg_json}' to '#{queue.arn}'")
        queue.send_message( msg.to_json )
      end

      def fetch_queue( queue_name, logger, error_callback )
        AWS::SQS.new.queues.named( queue_name )
      rescue AWS::SQS::Errors::NonExistentQueue => err
        logger.error( Kyu.stringify_exception( err ) )
        error_callback.call( err )
        nil
      end

      def included( base )
        base.extend( ClassMethods )
      end
    end

    module ClassMethods
      def queue_name( queue_name )
        @queue_name = queue_name
      end

      def logger( logger )
        @logger = logger
      end

      def error_callback( error_callback )
        @error_callback = error_callback
      end

      def send_message( msg )
        raise 'Queue cannot be nil or empty' if @queue_name.nil? || @queue_name.empty?
        options = {}
        options.merge!( logger: @logger ) unless @logger.nil?
        options.merge!( error_callback: @error_callback ) unless @error_callback.nil?
        Postman.send_message( @queue_name, msg, options )
      end
    end
  end
end
