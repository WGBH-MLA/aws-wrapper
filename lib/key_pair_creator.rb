require_relative 'aws_wrapper'

class KeyPairCreator < AwsWrapper
  def create(name)
    key_path = "#{Dir.home}/.ssh/#{name}.pem"
    fail("PK already exists: #{key_path}") if File.exists?(key_path)
    key = create_key(name)
    File.write(key_path, key.key_material)
    LOGGER.info("Created key pair and stored private key at #{key_path}. Fingerprint: #{key.key_fingerprint}")
  end
end
