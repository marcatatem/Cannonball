# Cannonball

URI Canonicalization gem

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

See [tests](spec/cannonball_spec.rb) for more information.

### Removing suspicious useless params from a query string

Configure the gem:

    Cannonball::configure do |config|
      config.should_test_possible_duplicate_uri = true # enable remote test of uris containing suspicious paramaters (false by default)
      config.should_cache = true # enable caching using Redis (recommanded)
      config.redis = Redis.new # a redis instance
    end

    a = Cannonball::URI.new('http://online.wsj.com/article/SB10001424127887324767004578487332636180800.html?mod=trending_now_1').to_s
    => "http://online.wsj.com/article/SB10001424127887324767004578487332636180800.html"


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Licence

Copyright (c) 2013 Marca Tatem

MIT License

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.