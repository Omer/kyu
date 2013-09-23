module Kyu
  module Postman
    def self.send_message( queue_name, msg, options={} )
      error_callback = options.fetch( :error_callback, ->( err ){} )
      logger = options.fetch( :logger, Logger.new( '/dev/null' ) )

      queue = AWS::SQS.new.queues.named( queue_name )
      msg_json = msg.to_json
      logger.log( "Sending message '#{msg_json}' to '#{queue.arn}'")
      queue.send_message( msg )
    rescue AWS::SQS::Errors::NonExistentQueue => err
      logger.error( Kyu.stringify_exception( err ) )
      error_callback.call( err )
    end

    def self.included( base )
      base.extend( ClassMethods )
    end

    module ClassMethods
      def send_message( msg, options={} )
        Postman.send_message( queue_name, msg, options )
      end

      def queue_name
        raise NotImplementedError
      end
    end
  end
end
