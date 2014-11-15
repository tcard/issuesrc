require_relative '../lib/issuesrc'

describe Issuesrc do
  before :each do
    @obj = Class.new do
      include Issuesrc
    end.new
    @obj.send(:set_config, {
      :arg => 'fake arg'
    }, {
      'config' => ['fake', 'config']
    })
  end

  describe '#load_sourcer' do
    it 'loads the sourcer component' do
      allow(@obj).to receive(:load_component)
        .and_return(['fake path', 'fake cls'])
      allow(@obj).to receive(:do_require)
      allow(@obj).to receive(:make_sourcer).and_return('fake sourcer')

      expect(@obj).to receive(:load_component).with(
        ['sourcer', 'sourcer'],
        :sourcer,
        Issuesrc::DEFAULT_SOURCER,
        Issuesrc::SOURCERS)
      expect(@obj).to receive(:do_require).with('fake path')
      expect(@obj).to receive(:make_sourcer).with('fake cls')

      sourcer = @obj.send(:load_sourcer)

      expect(sourcer).to be == 'fake sourcer'
    end
  end

  describe '#load_issuer' do
    it 'loads the issuer component' do
      allow(@obj).to receive(:load_component)
        .and_return(['fake path', 'fake cls'])
      allow(@obj).to receive(:do_require)
      allow(@obj).to receive(:make_issuer).and_return('fake issuer')
      
      @obj.send(:set_config, 'fake args', 'fake config')

      expect(@obj).to receive(:load_component).with(
        ['issuer', 'issuer'],
        :issuer,
        Issuesrc::DEFAULT_ISSUER,
        Issuesrc::ISSUERS)
      expect(@obj).to receive(:do_require).with('fake path')
      expect(@obj).to receive(:make_issuer).with('fake cls', 'fake event loop')

      issuer = @obj.send(:load_issuer, 'fake event loop')

      expect(issuer).to be == 'fake issuer'
    end
  end

  describe '#load_component' do
    it 'loads a required component for issuesrc' do
      component = @obj.send(:load_component,
        ['config'], :arg, 'def', {'fake arg' => 'foo'})
      expect(component).to be == 'foo'
    end

    it 'loads the default component when no option is given' do
      component = @obj.send(:load_component,
        ['fake'], :fake, 'def', {'def' => 'bar'})
      expect(component).to be == 'bar'
    end

    it 'fails when loading an unknown component' do
      allow(@obj).to receive(:exec_fail).and_raise('failed')

      expect { @obj.send(:load_component, ['fake'], :fake, 'def', {}) }
        .to raise_error('failed')
    end
  end

  # TODO: Complete testing.
end
