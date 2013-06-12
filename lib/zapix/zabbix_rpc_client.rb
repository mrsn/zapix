require 'net/http'
require 'uri'
require 'json'
 
class ZabbixRPCClient

  attr_reader :uri, :debug, :auth_token

  def initialize(options)
    @uri = URI.parse(options[:service_url])
    @username = options[:username]
    @password = options[:password]
    @debug = options[:debug]
    @auth_token = authenticate
  end
 
  def method_missing(name, *args)
    method_name = map_name(name)
    post_body = { "method" => method_name, "params" => args[0], "id" => id, "jsonrpc" => "2.0", "auth" => auth_token }.to_json
    resp = JSON.parse( http_post_request(post_body) )
    raise JSONRPCError, resp["error"] if resp["error"]
    puts "[DEBUG] Get answer: #{resp}" if debug
    resp["result"]
  end
 
  def http_post_request(post_body)
    http    = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.request_uri)
    request.content_type = "application/json"
    request.body = post_body
    puts "[DEBUG] Send request: #{request.body}" if debug
    http.request(request).body
  end

  def authenticate
    user_login({"user" => @username, "password" => @password})
  end

  def id
    rand(100000)
  end

  def map_name(name)
   name.to_s.sub("_", ".")
  end

  class JSONRPCError < RuntimeError; end
end
