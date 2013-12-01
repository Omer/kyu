# Kyu

Kyu - SQS background processing for Ruby.

Unlike Rescue and Sidekiq, Kyu does not rely on Redis. It is simple, reliable,
and efficient way to handle background process in Ruby using SQS.

## Installation

Add this line to your application's Gemfile:

    gem 'kyu'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install kyu

## Usage

# image_resize_worker.rb
```ruby
require 'kyu'

class ImageResizerWorker
  include Kyu::Worker

  max_retries 3
  threadpool_size 10

  def process_message( msg )
    # ... Asyncronously resize the image
  end
end
```

`kyu start -- image_resize_worker.rb image_resizing`

# image_resize_postman.rb
```ruby
#!/usr/bin/env ruby
require 'kyu'

class ImageResizerPostman
  include Kyu::Postman

  queue_name 'image_resizing'
end

if __FILE__ == $PROGRAM_NAME
  ImageResizerWorker.send_message( url: ARGV[0], width: ARGV[1], height: ARGV[2] )
end
```

`./image_resize_postman.rb URL_FOR_A_LARGE_IMG 640 1136`

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
