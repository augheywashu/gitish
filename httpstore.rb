require 'net/http'
require 'curb'
require 'cgi'

class HTTPStore
  def initialize(child,options)
    raise "BlobStoreLocal: child really must be nil" unless child.nil?
    @host = options['http_host'] || raise("HTTPStore: http_host not found in options")
    @port = options['http_port'].to_i || raise("HTTPStore: http_port not found in options")
  end

  def stats
    []
  end

  def close
  end

  def has_shas?(shas, skip_cache)
    res = get("/shas?shas=#{shas.join('.')}")
    return res == '1'
  end

  def sync
    get("/sync")
  end

  def read_sha(sha)
    get("/read/#{sha}")
  end

  def write_commit(sha,message)
    post("/commit", :sha => sha, :message => message)
  end

  def write(data,sha)
    post("/write/#{sha}", :data => data)
  end

  protected
  def get(url)
    res = Net::HTTP.start(@host, @port) {|http|
      http.get(url)
    }
    res.body
  end

  def post(url,params)
    req = Net::HTTP::Post.new(url)
    req.set_form_data(params)
    res = Net::HTTP.start(@host, @port) {|http|
      http.request(req)
    }
    res.body
  end

  def postcurl(url,params)
    postvalues = params.map {|k,v| Curl::PostField.content(k.to_s,v)}
    STDERR.puts "Starting post"
    curl = Curl::Easy.new("http://#{@host}:#{@port}#{url}")
    STDERR.puts "a"
    curl.http_post(postvalues)
    STDERR.puts "done"
    curl.body_str
  end

end

