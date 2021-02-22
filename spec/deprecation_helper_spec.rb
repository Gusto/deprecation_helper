RSpec.describe DeprecationHelper do
  describe 'deprecate!' do
    subject { DeprecationHelper.deprecate!(input_parameter) }

    let(:error_backtrace) do
      ['frame0', 'frame1', 'frame2', 'some_special_complicated_frame']
    end
    let(:expected_exception_class) { DeprecationHelper::DeprecationException }
    let(:message) { 'This thing is deprecated' }
    let(:input_parameter) { message }

    let(:logger) { sorbet_double(Logger, warn: nil) }

    before do
      allow(Logger).to receive(:new).with(STDOUT).and_return(logger)
      allow(DeprecationHelper).to receive(:caller).and_return(error_backtrace)
    end

    shared_examples 'it raises the error' do |expected_message|
      it do
        expect { subject }.to raise_error(expected_exception_class, expected_message)
      end
    end

    shared_examples 'it does not raise an error' do
      it do
        expect { subject }.to_not raise_error
      end
    end

    context 'configured to do nothing' do
      before do
        DeprecationHelper.configure do |config|
          config.deprecation_strategies = []
        end
      end

      it_behaves_like 'it does not raise an error'
    end

    context 'configured to raise' do
      before do
        DeprecationHelper.configure do |config|
          config.deprecation_strategies = [DeprecationHelper::Strategies::RaiseError.new]
        end
      end

      context 'allow list is not passed in' do
        it_behaves_like 'it raises the error', 'This thing is deprecated'
      end

      context 'allow list is passed in' do
        before { allow(DeprecationHelper).to receive(:caller).and_return(['frame0', 'frame1', 'frame2', 'some_special_complicated_frame']) }

        subject { DeprecationHelper.deprecate!(input_parameter, allow_list: allow_list) }

        context 'allow list is passed in, but empty' do
          let(:allow_list) { [] }

          it_behaves_like 'it raises the error', 'This thing is deprecated'
        end

        context 'allow list is passed in, but does not cover permit this exception' do
          let(:allow_list) { ['frame10'] }

          it_behaves_like 'it raises the error', 'This thing is deprecated'
        end

        context 'allow list permits this exception with a simple string match list' do
          let(:allow_list) { ['frame1'] }

          it_behaves_like 'it does not raise an error'
        end

        context 'allow list permits this exception with a simple regexp match list' do
          let(:allow_list) { [/frame1/] }

          it_behaves_like 'it does not raise an error'
        end

        context 'allow list permits this exception with a more complex regexp match list' do
          let(:allow_list) { [/special.*?frame/] }

          it_behaves_like 'it does not raise an error'
        end
      end
    end

    context 'configured to do log' do
      before do
        DeprecationHelper.configure do |config|
          config.deprecation_strategies = [DeprecationHelper::Strategies::LogError.new]
        end
      end

      context 'logger is not set' do
        before do
          DeprecationHelper.configure do |config|
            config.deprecation_strategies = [DeprecationHelper::Strategies::LogError.new]
          end
        end

        it_behaves_like 'it does not raise an error'

        it 'logs an error' do
          expect(logger).to receive(:warn).with('This thing is deprecated')
          subject
        end
      end
    end

    context 'configured for multiple purposes' do
      let(:logger) { Logger.new(STDOUT) }

      before do
        DeprecationHelper.configure do |config|
          config.deprecation_strategies = [DeprecationHelper::Strategies::LogError.new(logger: logger), DeprecationHelper::Strategies::RaiseError.new]
        end
      end

      it_behaves_like 'it raises the error', 'This thing is deprecated'

      it 'logs an error' do
        expect(logger).to receive(:warn).with('This thing is deprecated')
        expect { subject }.to raise_error(StandardError)
      end
    end
  end
end
