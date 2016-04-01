describe 'README.md' do
  readme = File.read(__dir__ + '/../README.md')
           .scan(/```\n(.*?)\n```/m)
           .map do |block|
    File.basename(block[0].gsub(/.*(scripts\/\S*).*/, '\1'))
  end

  describe 'compared to the scripts' do
    scripts = Dir[__dir__ + '/../scripts/*.rb'].map do |path|
      File.basename(path)
    end
    it 'has script for each readme example' do
      expect(readme - scripts).to eq []
    end
    it 'has readme example for each script' do
      expect(scripts - readme).to eq []
    end
  end

  describe 'compared to everything.sh' do
    everything = File.read(__dir__ + '/everything.sh')
                 .scan(/scripts\/\w+.rb/)
                 .map { |path| File.basename(path) }
    it 'has line in everything.sh for each readme example' do
      expect(readme - everything).to eq []
    end
    it 'has readme example for each line in everything.sh' do
      expect(everything - readme).to eq []
    end
  end
end
