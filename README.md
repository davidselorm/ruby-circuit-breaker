# Ruby Circuit Breaker 🔴🟡🟢
Fault-tolerant circuit breaker for microservices in Ruby.

```ruby
breaker = CircuitBreaker.new(threshold: 3, timeout: 5)
breaker.call { external_api_call }
```
