class CircuitBreaker
  attr_reader :state, :failures, :threshold, :timeout
  STATES = [:closed, :open, :half_open]

  def initialize(threshold: 3, timeout: 10, fallback: nil)
    @threshold = threshold
    @timeout = timeout
    @fallback = fallback
    @failures = 0
    @state = :closed
    @last_failure_time = nil
  end

  def call(&block)
    check_state
    if @state == :open
      return @fallback.call if @fallback
      raise "CircuitBreaker is OPEN"
    end
    begin
      res = block.call
      on_success
      res
    rescue => e
      on_failure
      return @fallback.call if @fallback
      raise e
    end
  end

  private
  def on_success
    @failures = 0
    @state = :closed
  end
  def on_failure
    @failures += 1
    @last_failure_time = Time.now
    @state = :open if @failures >= @threshold
  end
  def check_state
    if @state == :open && Time.now - @last_failure_time > @timeout
      @state = :half_open
    end
  end
end
