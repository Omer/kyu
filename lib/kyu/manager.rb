module Kyu
  class Manager
    attr_reader :worker_klass, :queue, :dl_queue, :max_retries, :logger,
      :threadpool_size, :error_callback

    def initialize( worker_klass, queue_name, options={} )
      @max_retries = options.fetch( :max_retries, 3 )
      @threadpool_size = options.fetch( :threadpool_size, 20 )
      @logger = options.fetch( :logger, Logger.new( '/dev/null' ) )
      @error_callback = options.fetch( :error_callback, ->( err ){} )
      queue_options = options.fetch( :queue_options, {} )
      @worker_klass = worker_klass
      @sqs = AWS::SQS.new
      @queue = @sqs.queues.create( queue_name, queue_options )
      @dl_queue = @sqs.queues.create( deadletter_queue_name_for( queue_name ), queue_options )
    end

    def start
      logger.info( "Started listening for messages on: '#{queue.arn}'" )
      logger.info(
        "Messages that could not be processes would be imgrated to: '#{dl_queue.arn}'"
      )

      EM.run do
        EM.threadpool_size = threadpool_size
        stop = false

        Signal.trap( 'INT' ) { EM.stop; stop = true }
        Signal.trap( 'TERM' ) { EM.stop; stop = true }

        poll_message until stop
      end

      logger.info( "Stopped listening for messages on: '#{queue.arn}'" )
    end

    private

    def poll_message
      msg = queue.receive_message( attributes: [:receive_count] )
      return unless msg

      EM.defer do
        begin
          logger.info( "Started processing: '#{msg.body}'" )
          worker_klass.new.process_message( JSON.parse( msg.body ) )
          msg.delete
          logger.info( "Finished processing: '#{msg.body}'" )
        rescue => err
          logger.error( stringify_exception( err ) )
          error_callback.call( err )
          if msg.receive_count > max_retries
            logger.info( "Max number of reties exceeded for: '#{msg.body}'. Migrating the message to the dead-letter queue." )
            dl_queue.send_message( msg.body )
            msg.delete
          end
        end
      end
    end

    def deadletter_queue_name_for( queue_name )
      queue_name + '_deadletter'
    end
  end
end
