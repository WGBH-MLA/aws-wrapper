describe 'README' do

  examples = File.read(__dir__+'/../README.md')
    .scan(/```\n(.*?)\n```/m)
    .map do |block|
      File.basename(block[0].gsub(/.*(scripts\/\S*).*/, '\1'))
    end
    
  scripts = Dir[__dir__+'/../scripts/*.rb'].map do |path|
    File.basename(path)
  end
  
  it 'has script for each example' do
    expect(examples - scripts).to eq []
  end
  
  it 'has example for each script' do
    expect(scripts - examples).to eq []
  end
  
end