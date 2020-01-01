# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Metrics::MethodLength, :config do
  subject(:cop) { described_class.new(config) }

  let(:cop_config) { { 'Max' => 5, 'CountComments' => false } }

  shared_examples 'ignoring an offense on an excluded method' do |excluded|
    before { cop_config['ExcludedMethods'] = [excluded] }

    it 'still rejects other methods with long blocks' do
      expect_offense(<<~RUBY)
        def m
        ^^^^^ Method has too many lines. [6/5]
          a = 1
          a = 2
          a = 3
          a = 4
          a = 5
          a = 6
        end
      RUBY
    end

    it 'accepts the foo method with a long block' do
      puts '****************'
      puts excluded
      puts '****************'
      expect_no_offenses(<<~RUBY)
        def #{excluded}
          a = 1
          a = 2
          a = 3
          a = 4
          a = 5
          a = 6
        end
      RUBY
    end
  end

  context 'when method is an instance method' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        def m
        ^^^^^ Method has too many lines. [6/5]
          a = 1
          a = 2
          a = 3
          a = 4
          a = 5
          a = 6
        end
      RUBY
    end
  end

  context 'when method is defined with `define_method`' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        define_method(:m) do
        ^^^^^^^^^^^^^^^^^^^^ Method has too many lines. [6/5]
          a = 1
          a = 2
          a = 3
          a = 4
          a = 5
          a = 6
        end
      RUBY
    end
  end

  context 'when method is a class method' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        def self.m
        ^^^^^^^^^^ Method has too many lines. [6/5]
          a = 1
          a = 2
          a = 3
          a = 4
          a = 5
          a = 6
        end
      RUBY
    end
  end

  context 'when method is defined on a singleton class' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        class K
          class << self
            def m
            ^^^^^ Method has too many lines. [6/5]
              a = 1
              a = 2
              a = 3
              a = 4
              a = 5
              a = 6
            end
          end
        end
      RUBY
    end
  end

  it 'accepts a method with less than 5 lines' do
    expect_no_offenses(<<~RUBY)
      def m
        a = 1
        a = 2
        a = 3
        a = 4
      end
    RUBY
  end

  it 'accepts a method with multiline arguments ' \
     'and less than 5 lines of body' do
    expect_no_offenses(<<~RUBY)
      def m(x,
            y,
            z)
        a = 1
        a = 2
        a = 3
        a = 4
      end
    RUBY
  end

  it 'does not count blank lines' do
    expect_no_offenses(<<~RUBY)
      def m()
        a = 1
        a = 2
        a = 3
        a = 4


        a = 7
      end
    RUBY
  end

  it 'accepts empty methods' do
    expect_no_offenses(<<~RUBY)
      def m()
      end
    RUBY
  end

  it 'is not fooled by one-liner methods, syntax #1' do
    expect_no_offenses(<<~RUBY)
      def one_line; 10 end
      def self.m()
        a = 1
        a = 2
        a = 4
        a = 5
        a = 6
      end
    RUBY
  end

  it 'is not fooled by one-liner methods, syntax #2' do
    expect_no_offenses(<<~RUBY)
      def one_line(test) 10 end
      def self.m()
        a = 1
        a = 2
        a = 4
        a = 5
        a = 6
      end
    RUBY
  end

  it 'properly counts lines when method ends with block' do
    expect_offense(<<~RUBY)
      def m
      ^^^^^ Method has too many lines. [6/5]
        something do
          a = 2
          a = 3
          a = 4
          a = 5
        end
      end
    RUBY
  end

  it 'does not count commented lines by default' do
    expect_no_offenses(<<~RUBY)
      def m()
        a = 1
        #a = 2
        a = 3
        #a = 4
        a = 5
        a = 6
      end
    RUBY
  end

  context 'when CountComments is enabled' do
    before { cop_config['CountComments'] = true }

    it 'also counts commented lines' do
      expect_offense(<<~RUBY)
        def m
        ^^^^^ Method has too many lines. [6/5]
          a = 1
          #a = 2
          a = 3
          #a = 4
          a = 5
          a = 6
        end
      RUBY
    end
  end

  context 'when ExcludedMethods is enabled' do
    it_behaves_like('ignoring an offense on an excluded method', 'foo')

    it_behaves_like('ignoring an offense on an excluded method',
                    'Gem::Specification.new')

    context 'when receiver contains whitespaces' do
      before { cop_config['ExcludedMethods'] = ['Foo::Bar.baz'] }

      it 'ignores whitespaces' do
        expect_no_offenses(<<~RUBY)
          Foo::
            Bar.baz do
            a = 1
            a = 2
            a = 3
            a = 4
            a = 5
            a = 6
          end
        RUBY
      end
    end

    context 'when a method is ignored, but receiver is a module' do
      before { cop_config['ExcludedMethods'] = ['baz'] }

      it 'does not report an offense' do
        expect_no_offenses(<<~RUBY)
          Foo::Bar.baz do
            a = 1
            a = 2
            a = 3
            a = 4
            a = 5
            a = 6
          end
        RUBY
      end
    end
  end
end
