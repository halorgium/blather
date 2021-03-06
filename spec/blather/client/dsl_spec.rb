require File.join(File.dirname(__FILE__), *%w[.. .. spec_helper])
require 'blather/client/dsl'

describe 'Blather::DSL' do
  before do
    @client = mock()
    @dsl = class MockDSL; include Blather::DSL; end.new
    Client.stubs(:new).returns(@client)
  end

  it 'wraps the setup' do
    args = ['jid', 'pass', 'host', 0000]
    @client.expects(:setup).with *args
    @dsl.setup *args
  end

  it 'allows host to be nil in setup' do
    args = ['jid', 'pass']
    @client.expects(:setup).with *(args + [nil, nil])
    @dsl.setup *args
  end

  it 'allows port to be nil in setup' do
    args = ['jid', 'pass', 'host']
    @client.expects(:setup).with *(args + [nil])
    @dsl.setup *args
  end

  it 'stops when shutdown is called' do
    @client.expects(:close)
    @dsl.shutdown
  end

  it 'sets up handlers' do
    type = :message
    guards = [:chat?, {:body => 'exit'}]
    @client.expects(:register_handler).with type, *guards
    @dsl.handle type, *guards
  end

  it 'provides a helper for ready state' do
    @client.expects(:register_handler).with :ready
    @dsl.when_ready
  end

  it 'sets the initial status' do
    state = :away
    msg = 'do not disturb'
    @client.expects(:status=).with [state, msg]
    @dsl.set_status state, msg
  end

  it 'provides a roster accessor' do
    @client.expects :roster
    @dsl.my_roster
  end

  it 'provides a writer' do
    stanza = Blather::Stanza::Iq.new
    @client.expects(:write).with stanza
    @dsl.write stanza
  end

  it 'provides a "say" helper' do
    to, msg = 'me@me.com', 'hello!'
    Blather::Stanza::Message.stubs(:next_id).returns 0
    @client.expects(:write).with Blather::Stanza::Message.new(to, msg)
    @dsl.say to, msg
  end

  it 'provides a JID accessor' do
    @client.expects :jid
    @dsl.jid
  end

  it 'provides a disco helper for items' do
    what, who, where = :items, 'me@me.com', 'my/node'
    Blather::Stanza::Disco::DiscoItems.stubs(:next_id).returns 0
    @client.expects(:temporary_handler).with '0'
    expected_stanza = Blather::Stanza::Disco::DiscoItems.new
    expected_stanza.to = who
    expected_stanza.node = where
    @client.expects(:write).with expected_stanza
    @dsl.discover what, who, where
  end

  it 'provides a disco helper for info' do
    what, who, where = :info, 'me@me.com', 'my/node'
    Blather::Stanza::Disco::DiscoInfo.stubs(:next_id).returns 0
    @client.expects(:temporary_handler).with '0'
    expected_stanza = Blather::Stanza::Disco::DiscoInfo.new
    expected_stanza.to = who
    expected_stanza.node = where
    @client.expects(:write).with expected_stanza
    @dsl.discover what, who, where
  end

  Blather::Stanza.handler_list.each do |handler_method|
    it "provides a helper method for #{handler_method}" do
      guards = [:chat?, {:body => 'exit'}]
      @client.expects(:register_handler).with handler_method, *guards
      @dsl.__send__(handler_method, *guards)
    end
  end
end
