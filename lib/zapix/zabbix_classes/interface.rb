require "active_record"

class Interface
  include ActiveModel::Validations

  attr_reader :type, :main, :useip, :ip, :dns, :port
  validates_presence_of :type, :main, :useip, :ip, :dns, :port

  # for more info see
  #  https://www.zabbix.com/documentation/2.0/manual/appendix/api/hostinterface/definitions#host_interface
  # we assume ip and dns shall always be set
  validates_inclusion_of :type, :in => 1..4
  validates_inclusion_of :main, :in => 0..1
  validates_inclusion_of :useip, :in => 0..1

  def initialize(attributes)
    @type = attributes["type"] ||= 1
    @main = attributes["main"] ||= 1
    @useip = attributes["useip"] ||= 1
    @ip = attributes["ip"] = attributes["ip"]
    @dns = attributes["dns"] = attributes["dns"]
    @port = attributes["port"] = attributes["port"] ||= 10050
    @result = { "type" => type,
                "main" => main,
                "useip" => useip,
                "ip" => ip,
                "dns" => dns,
                "port" => port }
  end

  def read_attribute_for_validation(key)
    send(key)
  end

  def to_hash
    @result
  end

end
