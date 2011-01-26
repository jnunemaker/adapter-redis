require 'helper'
require 'adapter/redis'

describe "Redis adapter" do
  before do
    @client = Redis.new
    @adapter = Adapter[:redis].new(@client)
    @adapter.clear
  end

  let(:adapter) { @adapter }
  let(:client)  { @client }

  it_should_behave_like 'a marshaled adapter'

  describe "#lock" do
    let(:lock_key) { :add_game }

    it "defaults expiration to 1" do
      now = Time.mktime(2010, 10, 10, 5, 5, 5)
      Timecop.freeze(now) do
        expiration = now.to_i + 1
        client.should_receive(:setnx).with(lock_key.to_s, expiration).and_return(true)
        adapter.lock(lock_key) { }
      end
    end

    it "allows setting expiration" do
      now = Time.mktime(2010, 10, 10, 5, 5, 5)
      Timecop.freeze(now) do
        expiration = now.to_i + 5
        client.should_receive(:setnx).with(lock_key.to_s, expiration).and_return(true)
        adapter.lock(lock_key, :expiration => 5) { }
      end
    end

    describe "with no existing lock" do
      it "acquires lock, performs block, and clears lock" do
        result = false
        adapter.lock(lock_key) { result = true }

        result.should be_true
        adapter.read(lock_key).should be_nil
      end
    end

    describe "with lock set" do
      it "waits for unlock, performs block, and clears lock" do
        result = false
        client.set(lock_key.to_s, adapter.generate_expiration(1))
        adapter.lock(lock_key, :timeout => 2) { result = true }

        result.should be_true
        adapter.read(lock_key).should be_nil
      end
    end

    describe "with lock set that does not expire before timeout" do
      it "raises lock timeout error" do
        result = false
        client.set(lock_key.to_s, adapter.generate_expiration(2))

        lambda do
          adapter.lock(lock_key, :timeout => 1) { result = true }
        end.should raise_error(Adapter::LockTimeout, 'Timeout on lock add_game exceeded 1 sec')
      end
    end
  end
end