## Setup ENV and require stuff
ENV['RACK_ENV'] = 'test'
require 'lib/boot'

class OwmwTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end


  ### Fixtures ...
  def an_access_point(hostname, common_name, mac_address)
    AccessPoint.new.load(
        :name => hostname,
        :mac_address => mac_address,
        :l2vpn_clients => [
            :identifier => common_name
        ]
    )
  end

  def an_online_user(mac_address)
    OnlineUser.new.load(
        :radius_accounting => {:calling_station_id => mac_address}
    )
  end


  ### Tests ...
  def test_there_are_no_online_users_on_access_point
    AccessPoint.expects(:find).returns an_access_point('cool_ap', 'cn_1', '00:11:22:33:44:55')
    OnlineUser.expects(:all).returns [an_online_user('55:44:33:22:11:00')]
    OpenVpn.any_instance.stubs(:users).returns [['A0:5E:11:22:22:44', 'cn_2', "1.2.3.4:4099", "Thu May 26 14:39:41 2011"]]

    get '/access_points/cool_ap/online_users.xml'
    assert last_response.ok?
    assert last_response.body == [].to_xml
  end

  def test_there_are_some_online_users_on_access_point
    AccessPoint.expects(:find).returns an_access_point('cool_ap', 'cn_1', '00:11:22:33:44:55')
    OnlineUser.expects(:all).returns [an_online_user('A0:5E:11:22:22:44')]
    OpenVpn.any_instance.stubs(:users).returns [['A0:5E:11:22:22:44', 'cn_1', "1.2.3.4:4099", "Thu May 26 14:39:41 2011"]]

    get '/access_points/cool_ap/online_users.xml'
    assert last_response.ok?
    assert last_response.body == [an_online_user('A0:5E:11:22:22:44')].to_xml
  end

  def test_online_users_but_access_point_not_found
    AccessPoint.expects(:find).returns(nil)
    get '/access_points/non_existant_ap/online_users.xml'
    assert last_response.not_found?
  end
end
