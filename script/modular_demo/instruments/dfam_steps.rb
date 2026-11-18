RCoreMidi::Instrument.register :dfam_steps, 9, output: 'Port 1' do
  play 1..1000, :dfam_steps
end
