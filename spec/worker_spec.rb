require_relative '../lib/kyu/manager'
require_relative '../lib/kyu/worker'

describe Kyu::Worker do
  describe 'when included' do
    before do
      class TestClass
        include Kyu::Worker

        max_retries 3
        threadpool_size 10
        logger 'LOGGER'
        error_callback 'CALLBACK'
        queue_options( foo: :bar )
      end
    end

    def should_delegate_with( option )
      manager_double = double( Kyu::Manager, start: nil )

      Kyu::Manager.should_receive( :new ) do |klass, queue_name, options|
        expect( klass ).to be( TestClass )
        expect( queue_name ).to eq( 'TEST_QUEUE' )
        expect( options ).to include( option )
        manager_double
      end

      TestClass.start( 'TEST_QUEUE' )
    end

    it 'allows to set the max_retries' do
      should_delegate_with( max_retries: 3 )
    end

    it 'allows to set the threadpool_size' do
      should_delegate_with( threadpool_size: 10 )
    end

    it 'allows to set the logger' do
      should_delegate_with( logger: 'LOGGER' )
    end

    it 'allows to set the error_callback' do
      should_delegate_with( error_callback: 'CALLBACK' )
    end

    it 'allows to set the queue_options' do
      should_delegate_with( queue_options: { foo: :bar } )
    end
  end
end
