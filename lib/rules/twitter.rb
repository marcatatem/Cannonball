class Twitter < Cannonball::Rule

  domain 'twitter.com'
  
  # turn http://twitter.com/#!/marca_tatem into http://twitter.com/marca_tatem
  def self.process url
    if !url.fragment.nil? && url.fragment[0] == '!'
      url.path += url.fragment.match(/^!(.+)$/)[1]
      url.path = url.path.squeeze('/')
      url.fragment = nil
    end
    url
  end

end