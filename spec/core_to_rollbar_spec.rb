require_relative '../lib/core_to_rollbar'

RSpec.describe CoreToRollbar do
  subject(:core_to_rollbar) { CoreToRollbar.new }

  let(:pid) { '1234' }
  let(:uid) { '1000' }
  let(:host) { 'host' }
  let(:signal) { '11' }
  let(:time) { '1491351192' }
  let(:executable) { '!prog!name' }
  let(:soft_limit) { '1024' }
  let(:initial_pid) { '2345' }
  let(:args) { [pid, uid, host, signal, time, executable, soft_limit, initial_pid] }

  let(:access_key) { 'access_key' }
  let(:environment) { 'env' }

  let(:config_file) { double('config file') }

  before do
    allow(Syslog).to receive(:open)
    allow(Syslog).to receive(:log)
    allow(subject).to receive(:exec)
    allow(Rollbar).to receive(:configure)
    allow(Rollbar).to receive(:error)
    allow(File).to receive(:open) { |&block| block.call(config_file) }
    allow(config_file).to receive(:read) { "access_token: #{access_key}\nenvironment: #{environment}" }
  end

  describe 'rollbar forwarding' do
    let(:config) { double('rollbar config') }

    context 'on success' do
      it 'receives configuration' do
        expect(Rollbar).to receive(:configure) { |&block| block.call(config) }
        expect(config).to receive(:access_token=).with(access_key)
        expect(config).to receive(:host=).with(host)
        expect(config).to receive(:environment=).with(environment)
        subject.run(args)
      end

      it 'has default environment' do
        expect(Rollbar).to receive(:configure) { |&block| block.call(config) }
        allow(config_file).to receive(:read) { "access_token: #{access_key}" }
        expect(config).to receive(:access_token=)
        expect(config).to receive(:host=)
        expect(config).to receive(:environment=).with('production')
        subject.run(args)
      end

      it 'reports error' do
        expect(Rollbar).to receive(:error).with(/Process.*#{pid}.*#{uid}.*#{signal}/)
        subject.run(args)
      end

      it 'reports true' do
        ret = subject.run(args)
        expect(ret).to be(true)
      end
    end

    context 'on failure' do
      before do
        expect(Rollbar).to receive(:error).and_raise('some error')
      end

      it 'prints failure to syslog' do
        expect(Syslog).to receive(:log).ordered
        expect(Syslog).to receive(:log).ordered.with(Syslog::LOG_CRIT,
                                                     /rollbar/)
        subject.run(args)
      end

      it 'returns false' do
        ret = subject.run(args)
        expect(ret).to be(false)
      end
    end
  end

  describe 'apport forwarding' do
    context 'on success' do
      it 'runs apport' do
        expect(subject).to receive(:exec).with(/.*\/apport$/, pid, time, soft_limit, initial_pid)
        subject.run(args)
      end

      it 'returns true' do
        ret = subject.run(args)
        expect(ret).to be(true)
      end
    end

    context 'on failure' do
      before do
        expect(subject).to receive(:exec).and_raise('some error')
      end

      it 'prints to syslog' do
        expect(Syslog).to receive(:log).ordered
        expect(Syslog).to receive(:log).ordered.with(Syslog::LOG_CRIT,
                                                     /apport/)
        subject.run(args)
      end

      it 'returns false' do
        ret = subject.run(args)
        expect(ret).to be(false)
      end
    end
  end
end
