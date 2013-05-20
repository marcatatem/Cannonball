# -*- encoding: utf-8 -*-
require 'bundler'
Bundler.setup

require './lib/cannonball'

describe Cannonball::URI do

  it "should convert the scheme and host to lower case" do
    Cannonball::URI.new('HTTP://www.Example.com/').to_s.should eq('http://www.example.com/')
  end

  it "should assume http" do
    Cannonball::URI.new('apple.com/imac').to_s.should eq('http://apple.com/imac')
  end

  it "should handle utf8 hosts" do
    Cannonball::URI.new('http://☁→❄→☃→☀→☺→☂→☹→✝.ws/about').to_s.should eq('http://xn--55gaaaaaa281gfaqg86dja792anqa.ws/about')
  end

  it "should assume base_uri protocol" do
    Cannonball::URI.new("//assets/application.js", 'https://www.example.com').to_s.should eq('https://www.example.com/assets/application.js')
  end

  it "should raise an ArgumentError exception if the protocol is not given and domain cannot be identified" do
    expect { Cannonball::URI.new('imac').to_s }.to raise_error
    expect { Cannonball::URI.new('/imac/technical-specifications').to_s }.to raise_error
    expect { Cannonball::URI.new('//assets/application.js').to_s }.to raise_error
    expect { Cannonball::URI.new('applecom/imac').to_s }.to raise_error
  end

  it "should add a trailing slash if no path is provided" do
    Cannonball::URI.new('http://www.example.com').to_s.should eq('http://www.example.com/')
  end

  it "should deal with creative uris" do
    Cannonball::URI.new('http://example.com/a/b/../../?q=asimodo').to_s.should eq('http://example.com/?q=asimodo')
  end

  it "should capitalize letters in escape sequences" do
    Cannonball::URI.new('http://www.example.com/a%c2%b1b').to_s.should eq('http://www.example.com/a%C2%B1b')
  end

  it "should join relative and base uri" do
    Cannonball::URI.new('about', 'http://www.example.com').to_s.should eq('http://www.example.com/about')
    Cannonball::URI.new('about', 'http://www.example.com/').to_s.should eq('http://www.example.com/about')
    Cannonball::URI.new('/about', 'http://www.example.com').to_s.should eq('http://www.example.com/about')
    Cannonball::URI.new('/marca', 'http://www.example.com/about').to_s.should eq('http://www.example.com/marca')
    Cannonball::URI.new('../about', 'http://www.example.com/about/marca').to_s.should eq('http://www.example.com/about')
    Cannonball::URI.new('../../', 'http://www.example.com/about/marca').to_s.should eq('http://www.example.com/')
    Cannonball::URI.new('../about', 'http://www.example.com').to_s.should eq('http://www.example.com/about')
    Cannonball::URI.new('../about.html?q=marca', 'http://www.example.com').to_s.should eq('http://www.example.com/about.html?q=marca')
  end

  it "should decode percent-encoded octets of unreserved characters" do
    Cannonball::URI.new('http://www.example.com/%7Eusername/').to_s.should eq('http://www.example.com/~username/')
  end

  it "should remove the default port for both http (80) and https (443)" do
    Cannonball::URI.new('http://www.example.com:80/bar.html').to_s.should eq('http://www.example.com/bar.html')
    Cannonball::URI.new('https://www.example.com:443/bar.html').to_s.should eq('https://www.example.com/bar.html')
  end

  it "should keep custom ports" do
    Cannonball::URI.new('http://www.example.com:8080/bar.html').to_s.should eq('http://www.example.com:8080/bar.html')
  end  

  it "should remove dot-segments" do
    Cannonball::URI.new('http://www.example.com/../a/b/../c/./d.html').to_s.should eq('http://www.example.com/a/c/d.html')
  end

  it "should remove directory index" do
    Cannonball::URI.new('http://www.example.com/a/index.html').to_s.should eq('http://www.example.com/a/')
  end

  it "should remove non hashbang (#!) fragments" do
    Cannonball::URI.new('http://www.example.com/#').to_s.should eq('http://www.example.com/')
    Cannonball::URI.new('http://www.example.com/a/contact.html#').to_s.should eq('http://www.example.com/a/contact.html')
    Cannonball::URI.new('http://www.example.com/a/index.html#').to_s.should eq('http://www.example.com/a/')
    Cannonball::URI.new('http://www.example.com/#contact').to_s.should eq('http://www.example.com/')
  end

  it "should keep hashbang style fragments in '_escaped_fragment_' query string parameters" do
    Cannonball::URI.new('http://www.example.com/#!contact').to_s.should eq('http://www.example.com/?_escaped_fragment_=contact')
    Cannonball::URI.new('http://www.example.com/#!Théophile Gauthier').to_s.should eq('http://www.example.com/?_escaped_fragment_=Th%C3%A9ophile%20Gauthier')
  end

  it "should remove duplicate slashes" do
    Cannonball::URI.new('http://www.example.com/foo//bar.html').to_s.should eq('http://www.example.com/foo/bar.html')
  end

  it "should sort query parameters if any" do
    Cannonball::URI.new('http://www.example.com/display?lang=en&article=fred').to_s.should eq('http://www.example.com/display?article=fred&lang=en')
  end

  it "should remove the ? of an empty query string" do
    Cannonball::URI.new('http://www.example.com/display?').to_s.should eq('http://www.example.com/display')
  end

  it "should guess domain" do
    Cannonball::URI.new('http://www.example.com/news').domain.should eq('example.com')
    Cannonball::URI.new('http://iro.example.co.uk/news').domain.should eq('example.co.uk')
    Cannonball::URI.new('http://☁→❄→☃→☀→☺→☂→☹→✝.ws/index.html').domain.should eq('☁→❄→☃→☀→☺→☂→☹→✝.ws')
  end

  it "should guess subdomain" do
    Cannonball::URI.new('http://www.example.com/news').subdomain.should eq('www.example.com')
    Cannonball::URI.new('http://iro.example.co.uk/news').subdomain.should eq('iro.example.co.uk')
  end

  it "should guess root domain" do
    Cannonball::URI.new('http://www.example.com/news').root.to_s.should eq('http://www.example.com/')
    Cannonball::URI.new('http://iro.example.co.uk/news').root.to_s.should eq('http://iro.example.co.uk/')
  end

  it "should guess robots.txt location from uri with path" do
    Cannonball::URI.new('http://iro.example.co.uk/news').robots_path.to_s.should eq('http://iro.example.co.uk/robots.txt')
  end

  it "should display utf8-encoded hosts" do
    Cannonball::URI.new('http://☁→❄→☃→☀→☺→☂→☹→✝.ws/index.html').display_url.should eq('http://☁→❄→☃→☀→☺→☂→☹→✝.ws/')
  end

  it "should apply cannonicalization rules" do
    Cannonball::URI.new('http://twitter.com/#!/marca_tatem').to_s.should eq('http://twitter.com/marca_tatem')
  end

  it "should remove useless params" do
    Cannonball::URI.new('http://iro.example.co.uk/news?utm_source=foobar').to_s.should eq('http://iro.example.co.uk/news')
  end

end