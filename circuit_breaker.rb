require 'thread'

class CircuitBreaker
  STATES = [:closed, :open, :half_open].freeze
  attr_reader :state, :failure_count, :threshold, :recovery_timeout

  def initialize(threshold: 5, recovery_timeout: 10)
    @threshold = threshold
    @recovery_timeout = recovery_timeout
    @failure_count = 0
    @state = :closed
    @last_failure_time = Time.now
    @mutex = Mutex.new
  end

  def execute(&block)
    @mutex.synchronize do
      check_state_transition
      raise "CircuitBreaker: Circuit is OPEN" if @state == :open
    end

    begin
      result = yield
      on_success
      result
    rescue StandardError => e
      on_failure
      raise e
    end
  end

  private

  def check_state_transition
    if @state == :open && (Time.now - @last_failure_time) > @recovery_timeout
      @state = :half_open
    end
  end

  def on_success
    @mutex.synchronize do
      @failure_count = 0
      @state = :closed
    end
  end

  def on_failure
    @mutex.synchronize do
      @failure_count += 1
      @last_failure_time = Time.now
      if @failure_count >= @threshold || @state == :half_open
        @state = :open
      end
    end
  end
end
