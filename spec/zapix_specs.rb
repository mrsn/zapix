require 'spec_helper'
#require 'rspec'
#require_relative 'zapix'
#require 'zapix'

# settings
@api_url = ''
@api_login = ''
@api_password = ''

zrc = ZabbixAPI.connect(
  :service_url => @api_url,
  :username => @api_login,
  :password => @api_password,
  :debug => true
  )

hostgroup = "hostgroup"
another_hostgroup = "anotherhostgroup"
hostgroup_with_hosts = "withhosts"
template  = "template"
application = "application"
item = "item"
host = "hostname"
screen_name = "screen_name"
trigger = "trigger"
user = "user"
user2 = "user2"
usergroup = "SomeUserGroup"
graph = "graph"
mediatype = "somemediatype"

hostgroupid = 0
templateid = 0
applicationid = 0
itemid = 0
hostid = 0
triggerid = 0
userid = 0
usergroupid = 0
graphid = 0
screenid = 0
mediatypeid = 0




#puts "### Zabbix API server version #{zbx.server.version} ###"

describe ZabbixAPI do

  it "creates a hostgroup" do
    result = zrc.hostgroups.create(another_hostgroup)
    result.should be_kind_of(Hash)
    result.should include("groupids")
    zrc.hostgroups.delete(another_hostgroup)
  end


  it "creates or updates a hostgroup" do
    zrc.hostgroups.create_or_update(hostgroup)
    result = zrc.hostgroups.create_or_update(hostgroup)
    result.should be_kind_of(Hash)
    result.should include("groupids")
  end

  it "returns false if hostgroup does not exist" do
    result = zrc.hostgroups.exists?("nonexisting")
    result.should be_false
  end

  it "succeeds if a hostgroup exist" do
    result = zrc.hostgroups.exists?(hostgroup)
    result.should be_true
  end

  it "returns hostgroup id" do
    result = zrc.hostgroups.get_id(hostgroup)
    (result.to_i).should >= 0
  end

  it "throws exception if hostgroup id does not exist" do
    expect { zrc.hostgroups.get_id("nonexisting") }.to raise_error(HostGroups::NonExistingHostgroup)
  end

  it "returns all hostgroup ids" do
  end

  it "deletes a group" do

    zrc.hostgroups.create(another_hostgroup)

    id = zrc.hostgroups.get_id(another_hostgroup)

    result = zrc.hostgroups.delete(another_hostgroup)

    result["groupids"].should include(id)
  end

  it "deletes a group with attached hosts" do
    create_hostgroup_with_hosts
#    zrc.hostgroups.delete(another_hostgroup)
  end

  it "throws exception if someone checks for attached tests of nonexisting group" do
     expect { zrc.hostgroups.any_hosts?("nonexisting") }.to raise_error(HostGroups::NonExistingHostgroup)
  end

  it "returns true if a hostgroup has attached hosts" do
    
  end

  it "returns false if a hostgroup has no attached hosts" do
    zrc.hostgroups.any_hosts?(hostgroup).should be_false
  end

  it "creates host" do
  end

  it "deletes host" do

  end

  it "updates host" do

  end

  

  it "returns true if a hostgroup has attached hosts" do

  end

  def create_hostgroup_with_hosts
    zrc.hostgroups.create(hostgroup_with_hosts)
    id = zrc.hostgroups.get_id(hostgroup_with_hosts)
    iface = Interface.new("ip" => "127.0.0.1", "dns" => "stoyanov.ams-cloud.de")
    test_host = (Host.new())
    test_host.add_group_ids(id)
    test_host.add_interface(iface.properties)
    test_host.add_template_ids(zrc.templates.get_id("Template OS Linux"))
    test_host.add_name(host)
  end

end


