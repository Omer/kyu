module Kyu
  module Worker
    class << self
      def included( base )
        base.extend( ClassMethods )
      end
    end

    module ClassMethods
      def start( queue_name )
        options = {}
        options.merge!( max_retries: @max_retries ) unless @max_retries.nil?
        options.merge!( threadpool_size: @threadpool_size ) unless @threadpool_size.nil?
        options.merge!( logger: @logger ) unless @logger.nil?
        options.merge!( error_callback: @error_callback ) unless @error_callback.nil?
        options.merge!( queue_options: @queue_options ) unless @queue_options.nil?

        Manager.new( self, queue_name, options ).start
      end

      def max_retries( max_retries )
        @max_retries = max_retries
      end

      def threadpool_size( threadpool_size )
        @threadpool_size = threadpool_size
      end

      def logger( logger )
        @logger = logger
      end

      def error_callback( error_callback )
        @error_callback = error_callback
      end

      def queue_options( queue_options )
        @queue_options = queue_options
      end
    end
  end
end
