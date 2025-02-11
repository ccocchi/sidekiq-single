#!lua name=ratelimit

local function single_release_lock(keys, args)
  local existing = redis.call("GET", keys[1])

  if existing == args[1] then
    return redis.call("DEL", keys[1])
  else
    return 0
  end
end

redis.register_function('single_release_lock', single_release_lock)
