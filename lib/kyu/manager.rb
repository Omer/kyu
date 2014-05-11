module Kyu
  class Manager
    def initialize( worker_klass, queue_name, options={} )
      @max_retries = options.fetch( :max_retries, 3 )
      @threadpool_size = options.fetch( :threadpool_size, 20 )
      @logger = options.fetch( :logger, Logger.new( '/dev/null' ) )
      @error_callback = options.fetch( :error_callback, ->( err ){} )
      queue_options = options.fetch( :queue_options, {} )
      @worker_klass = worker_klass

      sqs = AWS::SQS.new
      @dl_queue = sqs.queues.create( deadletter_queue_name_for( queue_name ), queue_options )
      @queue = sqs.queues.create( queue_name, queue_options )
      @queue.client.set_queue_attributes(
        queue_url: @queue.url,
        attributes: {
          "RedrivePolicy" => {
            "maxReceiveCount" => @max_retries,
            "deadLetterTargetArn" => @dl_queue.arn
          }.to_json
        }
      )
    end

    def start
      @logger.info( "Started listening for messages on: '#{@queue.arn}'" )
      @logger.info(
        "Messages that could not be processes would be imgrated to: '#{@dl_queue.arn}'"
      )

      EM.run do
        EM.threadpool_size = @threadpool_size
        stop = false

        Signal.trap( 'INT' ) { EM.stop; stop = true }
        Signal.trap( 'TERM' ) { EM.stop; stop = true }

        poll_message( @queue.visibility_timeout ) until stop
      end

      @logger.info( "Stopped listening for messages on: '#{@queue.arn}'" )
    end

    private

    def poll_message( visibility_timeout )
      msg = @queue.receive_message( attributes: [:receive_count] )
      return unless msg

      EM.defer do
        begin
          @logger.info( "Started processing: '#{msg.body}'" )
          Timeout::timeout( visibility_timeout ) do
            @worker_klass.new.process_message( JSON.parse( msg.body ) )
          end
          msg.delete
          @logger.info( "Finished processing: '#{msg.body}'" )
        rescue => err
          @logger.error( Kyu.stringify_exception( err ) )
          @error_callback.call( err )
          if msg.receive_count > @max_retries
            @logger.info( "Max number of reties exceeded for: '#{msg.body}'. Migrating the message to the dead-letter queue." )
            @dl_queue.send_message( msg.body )
            msg.delete
          end
        end
      end
    end

    def deadletter_queue_name_for( queue_name )
      queue_name + '_DeadLetter'
    end
  end
end
