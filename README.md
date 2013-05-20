# Cannonball

URI Canonicalization gem by Marca Tatem <marca.tatem@gmail.com>.

## Installation

Add this line to your application's Gemfile:

    gem 'cannonball'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install cannonball

## Usage

    a = Cannonball::URI.new('http://www.nytimes.com')
    => <#Cannonball::URI id:0x3fd9b5c3d95c url="http://www.nytimes.com/">

    a.to_s
    => "http://www.nytimes.com/"

See [tests](spec/cannonball_spec.rb) for more information

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
