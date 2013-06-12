class Interface

  attr_reader :properties

  def initialize(options)
    @properties = {}
    @properties["type"] = options["type"] ||= 1
    @properties["main"] = options["main"] ||= 1
    @properties["useip"] = options["useip"] ||= 1
    @properties["ip"] = options["ip"]
    @properties["dns"] = options["dns"]
    @properties["port"] = options["port"] ||= 10050
  end

end
