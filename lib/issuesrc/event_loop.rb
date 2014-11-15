require 'em-http-request'
require 'net/http'

module Issuesrc
  class EventLoop
    def async_http_request(method, url, opts, &callback)
      @http_channel.push([method, url, opts, callback])
    end

    def wait_for_pending()
      if @waiting == 0 || !@thread.alive?
        return
      end
      @wakeup_when_done << Thread.current
      Thread.stop
    end

    def initialize()
      @pending = []
      @http_channel = EM::Channel.new
      @waiting = 0
      @wakeup_when_done = []

      @thread = Thread.new do
        begin
          EM.run do
            handle_http_channel()
          end
        rescue
          # TODO: Proper error handling here.
          wakeup_waiters()
        end
      end
    end

    private
    def done_request()
      @waiting -= 1
      if @waiting > 0
        return
      end
      wakeup_waiters()
    end

    def wakeup_waiters()
      @wakeup_when_done.each do |t|
        t.wakeup
      end
    end

    def handle_http_channel()
      @http_channel.subscribe do |msg|
        method, url, opts, callback = msg
        req = EM::HttpRequest.new(url).send(method, opts)
        # TODO: Err handling.
        req.callback do
          callback.call req
          done_request()
        end
        req.errback do
          callback.call req
          done_request()
        end
      end
    end
  end

  class SequentialEventLoop < EventLoop
    def async_http_request(method, url, opts, &callback)
      @waiting += 1
      if @busy
        @pending << [method, url, opts, callback]
        return
      end

      @busy = true
      @http_channel.push([method, url, opts, lambda do |req|
        if !callback.nil?
          callback.call req
        end
        @busy = false
        if @pending.length > 0
          method, url, opts, callback = @pending[0]
          @pending = @pending[1..-1]
          @waiting -= 1
          async_http_request(method, url, opts, &callback)
        end
      end])
    end
  end
end
