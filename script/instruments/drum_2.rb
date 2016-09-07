Instrument.register :drum, 0 do |live|
  play live.clip(:drum), 1
  play live.clip(:drum_two), 17
end
