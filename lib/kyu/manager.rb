module Kyu
  class Manager
    attr_reader :worker, :queue, :dl_queue

    def initialize( worker_klass, queue_name )
      @worker = worker_klass.new
      sqs = AWS::SQS.new
      @queue = sqs.queues.create( queue_name, worker.queue_options )
      @dl_queue = sqs.queues.create( deadletter_queue_name_for( queue_name ), worker.queue_options )
    end

    def start
      worker.logger.info( "Started listening for messages on: '#{queue.arn}'" )
      worker.logger.info(
        "Messages that could not be processes would be imgrated to: '#{dl_queue.arn}'"
      )

      EM.run do
        EM.threadpool_size = worker.threadpool_size
        stop = false

        Signal.trap( 'INT' ) { EM.stop; stop = true }
        Signal.trap( 'TERM' ) { EM.stop; stop = true }

        poll_message until stop
      end

      worker.logger.info( "Stopped listening for messages on: '#{queue.arn}'" )
    end

    private

    def poll_message
      msg = queue.receive_message( attributes: [:receive_count] )
      return unless msg

      EM.defer do
        begin
          worker.logger.info( "Started processing: '#{msg.body}'" )
          worker.process_message( JSON.parse( msg.body ) )
          msg.delete
          worker.logger.info( "Finished processing: '#{msg.body}'" )
        rescue => err
          worker.logger.error( stringify_exception( err ) )
          worker.error_callback.call( err )
          if msg.receive_count > max_retries
            worker.logger.info( "Max number of reties exceeded for: '#{msg.body}'. Migrating the message to the dead-letter queue." )
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
