# Zapix

Zapix is a tool which makes the communication with the zabbix's api simple.

## Installation

Add this line to your application's Gemfile:

    gem 'zapix'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install zapix

## Usage

### Remote client
First we need the zapix remote client:

```ruby
require 'zapix'
zrc = ZabbixAPI.connect(
  :service_url => http://ourzabbix.server-cp,,
  :username => guybrush,
  :password => threepwood,
  :debug => true
)
```
### Hostgroup Operations
* creating a hostgroup
```ruby
zrc.hostgroups.create('test_hostgroup')
```

* Checking if a hostgroup exists
```ruby
zrc.hostgroups.exists?('test_hostgroup')
```

* Checking if a hostgroup has any attached hosts
```ruby
zrc.hostgroups.any_hosts?('test_hostgroup')
```

* Getting all host ids of hosts belonging to a hostgroup
```ruby
zrc.hostgroups.get_host_ids_of('test_hostgroup')
```

* Deleting a hostgroup
Note that deleting a hostgroups with attached hosts also deletes the hosts.

```ruby
zrc.hostgroups.delete('test_hostgroup')
```

* Getting an id of a hostgroup
```ruby
zrc.hostgroups.get_id('test_hostgroup')
```

* Getting all hostgroups
```ruby
zrc.hostgroups.get_all
```

### Host Operations

* Getting host id
```ruby
zrc.hosts.get_id('test_host')
```
* Getting Templates for a host
```ruby
zrc.templates.get_templates_for_host(zrc.hosts.get_id('test_host'))
```

* Creating a host
Note that in zabbix host cannot exists on its own, it always needs a hostgroup.

```ruby 
hostgroup_id = zrc.hostgroups.get_id('test_hostgroup')

zabbix_interface = Interface.new(
  'ip'  => '127.0.0.1',
  'dns' => 'abrakadabra.com'
)

jmx_interface = Interface.new(
  'ip'  => '127.0.0.1',
  'dns' => 'abrakadabra.com',
  'type' => 4, # JMX
  'main' => 1, # default jmx interface
  'port' => 9003
)

template_1 = zrc.templates.get_id('example_template_1')
template_2 = zrc.templates.get_id('example_template_2')

example_host = Host.new
example_host.add_name('test_host')
example_host.add_interfaces(zabbix_interface.to_hash)
example_host.add_interfaces(jmx_interface.to_hash)
example_host.add_macros({'macro' => '{$TESTMACRO}', 'value' => 'test123'})
example_host.add_group_ids(hostgroup_id)
example_host.add_template_ids(template_1, template_2)
zrc.hosts.create(example_host.to_hash)
```

      
      example_host.add_name(host)
      example_host.add_interfaces(create_interface.to_hash)
      example_host.add_macros({'macro' => '{$TESTMACRO}', 'value' => 'test123'})
      example_host.add_group_ids(hostgroup_id)
      example_host.add_template_ids(zrc.templates.get_id(template_1), zrc.templates.get_id(template_2))
      zrc.hosts.create_or_update(example_host.to_hash)







## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
