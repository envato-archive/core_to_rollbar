# frozen_string_literal: true

require 'date'
require 'etc'
require 'rollbar'
require 'syslog/logger'
require 'yaml'

APPORT_LOCATION = '/usr/share/apport/apport'.freeze
CONFIG_FILE = '/etc/core_to_rollbar.yaml'.freeze

class CoreToRollbar
  def run(args)
    # arguments assumed in core_pattern:
    #    %p %u %h %s %t %E %c %P
    @pid, @uid, @host, @signal, @time, @executable, @soft_limit, @initial_pid = args

    Syslog.open('core_to_rollbar', Syslog::LOG_CONS)
    Syslog.log(Syslog::LOG_ERR, "Reporting a crash of #{@executable} [#{@pid}] to rollbar")

    failed = false
    begin
      forward_to_rollbar
    rescue => e
      Syslog.log(Syslog::LOG_CRIT, "Could not report the crash to rollbar: #{e}")
      failed = true
    end
    begin
      forward_to_apport
    rescue => e
      Syslog.log(Syslog::LOG_CRIT, "Could not report the crash to apport: #{e}")
      failed = true
    end

    !failed
  end

  private

  def forward_to_rollbar
    read_config

    executable_fixed = @executable.tr('!', '/')
    time_fixed = DateTime.strptime(@time, '%s')

    message = "Process #{executable_fixed} [#{@pid}] running as uid #{@uid} on #{@host} crashed on signal #{@signal} at #{time_fixed}"

    report_crash(message)
  end

  def forward_to_apport
    exec(APPORT_LOCATION, @pid, @time, @soft_limit, @initial_pid)
  end

  def read_config
    File.open(CONFIG_FILE) do |file|
      @config = YAML.safe_load(file.read)
    end
  end

  def report_crash(message)
    Rollbar.configure do |config|
      config.access_token = @config['access_token']
      config.host = @host
      config.environment = @config['environment'] || 'production'
    end

    Rollbar.error(message)
  end
end
