require_relative '../lib/key_pair_creator'

if ARGV.count != 1
  puts <<EOF
USAGE: #{File.basename(__FILE__)} NAME

Creates a new AWS key-pair, and stores the private key at ~/.ssh/NAME.pem.
EOF
  exit 1
end

name = ARGV.shift

KeyPairCreator.new.create(name)