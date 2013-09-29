module Kyu
  module Worker
    def self.included( base )
      base.extend( ClassMethods )
    end

    def max_retries; 3; end

    def threadpool_size; 5; end

    def logger; Logger.new( '/dev/null' ); end

    def error_callback; ->(err){}; end

    def queue_options; {}; end

    module ClassMethods
      def start( queue_name )
        Manager.new( self, queue_name ).start
      end
    end
  end
end
