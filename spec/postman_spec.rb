require_relative '../lib/kyu/postman'

describe Kyu::Postman do
  let( :msg ) { { body: 'EMPTY' } }
  let( :queue_name ) { 'TEST_QUEUE' }

  describe 'when included' do
    describe '#send_message' do
      describe 'allows to optionally set the logger' do
        before do
          class IncludedWithLogger
            include Kyu::Postman
            queue_name 'TEST_QUEUE'
            logger Logger.new( '/dev/null' )
          end
        end

        it 'delegates to ::send_message' do
          Kyu::Postman.should_receive( :send_message ).
            with( queue_name, msg, { logger: kind_of( Logger ) } )
          IncludedWithLogger.send_message( msg )
        end
      end

      describe 'allow to optionally set an error callback' do
        before do
          class IncludedWithErrorCallback
            include Kyu::Postman
            queue_name 'TEST_QUEUE'
            error_callback ->( err ){}
          end
        end

        it 'delegates to ::send_message' do
          Kyu::Postman.should_receive( :send_message ).
            with( queue_name, msg, { error_callback: kind_of( Proc ) } )
          IncludedWithErrorCallback.send_message( msg )
        end
      end

      describe 'when queue_name is properly set' do
        before do
          class IncludedWithQueueName
            include Kyu::Postman
            queue_name 'TEST_QUEUE'
          end
        end

        it 'delegates to ::send_message' do
          Kyu::Postman.should_receive( :send_message ).
            with( queue_name, msg, {} )
          IncludedWithQueueName.send_message( msg )
        end
      end

      describe 'when queue_name is not properly set' do
        before do
          class IncludedWithoutQueueName
            include Kyu::Postman
          end
        end

        it 'raises exception' do
          expect(
            -> { IncludedWithoutQueueName.send_message( msg ) }
          ).to raise_error
        end
      end
    end
  end

  describe '::send_message' do
    it 'sends the SQS message' do
      options = {
        logger: Logger.new( STDOUT ),
        error_callback: ->( err ){}
      }
      Kyu::Postman.should_receive( :fetch_queue ).
        with( queue_name, options[:logger], options[:error_callback] )
      Kyu::Postman.send_message( queue_name, msg, options )
    end
  end

  describe '::fetch_queue' do
    let( :logger ) { double( Logger ) }
    let( :error_callback ) { double( Proc ) }
    let( :queue_double ) { double( AWS::SQS::Queue ) }
    let( :queue_collection_double ) { double( AWS::SQS::QueueCollection ) }
    let( :sqs_double ) { double( AWS::SQS ) }

    describe 'when the SQS queue exists' do
      before do
        AWS::SQS.should_receive( :new ).and_return( sqs_double )
        sqs_double.should_receive( :queues ).and_return( queue_collection_double )
        queue_collection_double.should_receive( :named ).with( queue_name ).
          and_return( queue_double )
      end

      it 'returns the SQS queue' do
        queue = Kyu::Postman.fetch_queue( queue_name, logger, error_callback )
        expect( queue ).to be( queue_double )
      end
    end

    describe 'when the SQS does not exist' do
      before do
        AWS::SQS.should_receive( :new ).and_return( sqs_double )
        sqs_double.should_receive( :queues ).and_return( queue_collection_double )
        queue_collection_double.should_receive( :named ).with( queue_name ) {
          raise AWS::SQS::Errors::NonExistentQueue
        }
      end

      it 'logs the error' do
        Kyu.should_receive( :stringify_exception )
        logger.should_receive( :error )
        error_callback.should_receive( :call )

        queue = Kyu::Postman.fetch_queue( queue_name, logger, error_callback )
        expect( queue ).to be( nil )
      end
    end
  end
end
