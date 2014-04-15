require 'rubygems'
require 'bundler/setup'
require 'rest_client'
require 'json'
require 'pi_piper'
require 'thread'

LED_UPDATE_INTERVAL = 1

module CiPi
  class Monitor
    def initialize(name, options, &block)
      @name = name
      gpio = options[:gpio].to_i
      @interval = options[:interval] || 180
      @status = :unavailable
      @pin = PiPiper::Pin.new(pin: gpio, direction: :out)
      @pin.off

      @updater_thread = Thread.new do
        while true
          @status = begin
                      block.call ? :ok : :fail
                    rescue
                      :unavailable
                    end

          sleep @interval
        end
      end

      @status_thread = Thread.new do
        while true
          case @status
            when :unavailable
            blink(4, LED_UPDATE_INTERVAL)
            when :ok
            @pin.on
            when :fail
            @pin.off
            when :error
            blink(2, LED_UPDATE_INTERVAL)
            else
            puts "unknown status: #{@status}"
          end

          sleep LED_UPDATE_INTERVAL
        end
      end

      def blink(times, duration)
        times.times do
          @pin.on
          sleep(duration / times)
          @pin.off
        end
      end
    end

    def go!
      @updater_thread.join
      @status_thread.join
    end
  end

  class << self
    def monitor(name, options, &block)
      @monitors ||= {}
      @monitors[name] = Monitor.new(name, options, &block)
    end

    def read_config!
      module_eval File.read(File.dirname(__FILE__) + "/config.rb")
    end

    def go!
      self.read_config!
      @monitors.values.each(&:go!)
    end
  end
end

CiPi.go!
