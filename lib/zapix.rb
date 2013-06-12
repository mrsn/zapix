require "zapix/version"
require_relative "zapix/zabbix_rpc_client"

class ZabbixAPI
  attr :client

  def self.connect(options = {})
    new(options)
  end

  def initialize(options = {})
    @client = ZabbixRPCClient.new(options)
    Dir["#{File.dirname(__FILE__)}/zabbixapi/zabbix_classes/*.rb"].each { |f| load(f) }
    Dir["#{File.dirname(__FILE__)}/zabbixapi/proxies/*.rb"].each { |f| load(f) }
  end

  def hostgroups
    @hostgroups ||= HostGroups.new(@client)
  end

  def hosts
    @hosts ||= Hosts.new(@client)
  end

  def templates
    @templates ||= Templates.new(@client)
  end

end
