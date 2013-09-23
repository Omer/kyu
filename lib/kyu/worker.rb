module Kyu
  module Worker
    def self.included( base )
      base.extend( ClassMethods )
    end

    module ClassMethods
      def start( queue_name, options={} )
        Manager.new( self, queue_name, options ).start
      end
    end
  end
end
