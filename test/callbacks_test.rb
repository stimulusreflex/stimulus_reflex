# frozen_string_literal: true

require_relative "test_helper"

# standard:disable Lint/ConstantDefinitionInBlock

class CallbacksTest < ActionCable::Channel::TestCase
  tests StimulusReflex::Channel

  setup do
    stub_connection(session_id: SecureRandom.uuid)
    def connection.env
      @env ||= {}
    end
  end

  test "basic before_reflex works" do
    class BeforeCallbackReflex < StimulusReflex::Reflex
      before_reflex :init_counter

      def increment
        @count += 1
      end

      private

      def init_counter
        @count = 5
      end
    end

    data = StimulusReflex::ReflexData.new(url: "https://test.stimulusreflex.com", target: "test#increment", version: StimulusReflex::VERSION)
    reflex = BeforeCallbackReflex.new(subscribe, data: data)
    reflex.process(:increment)
    assert_equal 6, reflex.instance_variable_get(:@count)
  end

  test "before_reflex with block works" do
    class BeforeBlockCallbackReflex < StimulusReflex::Reflex
      before_reflex do
        @count = 5
      end

      def increment
        @count += 1
      end
    end

    data = StimulusReflex::ReflexData.new(url: "https://test.stimulusreflex.com", target: "test#increment", version: StimulusReflex::VERSION)
    reflex = BeforeBlockCallbackReflex.new(subscribe, data: data)
    reflex.process(:increment)
    assert_equal 6, reflex.instance_variable_get(:@count)
  end

  test "basic after_reflex works" do
    class AfterCallbackReflex < StimulusReflex::Reflex
      after_reflex :reset

      def increment
        @count = 5
      end

      private

      def reset
        @count = 1
      end
    end

    data = StimulusReflex::ReflexData.new(url: "https://test.stimulusreflex.com", target: "test#increment", version: StimulusReflex::VERSION)
    reflex = AfterCallbackReflex.new(subscribe, data: data)
    reflex.process(:increment)
    assert_equal 1, reflex.instance_variable_get(:@count)
  end

  test "after_reflex with block works" do
    class AfterBlockCallbackReflex < StimulusReflex::Reflex
      after_reflex do
        @count = 1
      end

      def increment
        @count = 5
      end
    end

    data = StimulusReflex::ReflexData.new(url: "https://test.stimulusreflex.com", target: "test#increment", version: StimulusReflex::VERSION)
    reflex = AfterBlockCallbackReflex.new(subscribe, data: data)
    reflex.process(:increment)
    assert_equal 1, reflex.instance_variable_get(:@count)
  end

  test "basic around_reflex works" do
    class AroundCallbackReflex < StimulusReflex::Reflex
      around_reflex :around

      def increment
        @count += 8
      end

      private

      def around
        @count = 2
        yield
        @count += 4
      end
    end

    data = StimulusReflex::ReflexData.new(url: "https://test.stimulusreflex.com", target: "test#increment", version: StimulusReflex::VERSION)
    reflex = AroundCallbackReflex.new(subscribe, data: data)
    reflex.process(:increment)
    assert_equal 14, reflex.instance_variable_get(:@count)
  end

  test "execute methods in order" do
    class CallbackOrderReflex < StimulusReflex::Reflex
      before_reflex :one
      before_reflex :two, :three

      def increment
      end

      private

      def one
        @count = 1
      end

      def two
        @count = 2 if @count == 1
      end

      def three
        @count = 3 if @count == 2
      end
    end

    data = StimulusReflex::ReflexData.new(url: "https://test.stimulusreflex.com", target: "test#increment", version: StimulusReflex::VERSION)
    reflex = CallbackOrderReflex.new(subscribe, data: data)
    reflex.process(:increment)
    assert_equal 3, reflex.instance_variable_get(:@count)
  end

  test "basic if option works" do
    class IfCallbackReflex < StimulusReflex::Reflex
      before_reflex :init, if: :present
      around_reflex :around, if: :blank
      after_reflex :after, if: :present

      def increment
        @count += 8
      end

      private

      def present
        true
      end

      def blank
        false
      end

      def init
        @count = 5
      end

      def around
        @count += 2
        yield
        @count += 4
      end

      def after
        @count += 10
      end
    end

    data = StimulusReflex::ReflexData.new(url: "https://test.stimulusreflex.com", target: "test#increment", version: StimulusReflex::VERSION)
    reflex = IfCallbackReflex.new(subscribe, data: data)
    reflex.process(:increment)
    assert_equal 23, reflex.instance_variable_get(:@count)
  end

  test "if option with proc/lambda works" do
    class IfProcCallbackReflex < StimulusReflex::Reflex
      before_reflex :init, if: -> { true }
      around_reflex :around, if: lambda { false }
      after_reflex :after, if: proc { true }

      def increment
        @count += 8
      end

      private

      def init
        @count = 5
      end

      def around
        @count += 2
        yield
        @count += 4
      end

      def after
        @count += 10
      end
    end

    data = StimulusReflex::ReflexData.new(url: "https://test.stimulusreflex.com", target: "test#increment", version: StimulusReflex::VERSION)
    reflex = IfProcCallbackReflex.new(subscribe, data: data)
    reflex.process(:increment)
    assert_equal 23, reflex.instance_variable_get(:@count)
  end

  test "basic unless option works" do
    class UnlessCallbackReflex < StimulusReflex::Reflex
      before_reflex :init, unless: :blank
      around_reflex :around, unless: :present
      after_reflex :after, unless: :blank

      def increment
        @count += 8
      end

      private

      def present
        true
      end

      def blank
        false
      end

      def init
        @count = 5
      end

      def around
        @count += 2
        yield
        @count += 4
      end

      def after
        @count += 10
      end
    end

    data = StimulusReflex::ReflexData.new(url: "https://test.stimulusreflex.com", target: "test#increment", version: StimulusReflex::VERSION)
    reflex = UnlessCallbackReflex.new(subscribe, data: data)
    reflex.process(:increment)
    assert_equal 23, reflex.instance_variable_get(:@count)
  end

  test "unless option with proc/lambda works" do
    class UnlessProcCallbackReflex < StimulusReflex::Reflex
      before_reflex :init, unless: -> { false }
      around_reflex :around, unless: lambda { true }
      after_reflex :after, unless: proc { false }

      def increment
        @count += 8
      end

      private

      def init
        @count = 5
      end

      def around
        @count += 2
        yield
        @count += 4
      end

      def after
        @count += 10
      end
    end

    data = StimulusReflex::ReflexData.new(url: "https://test.stimulusreflex.com", target: "test#increment", version: StimulusReflex::VERSION)
    reflex = UnlessProcCallbackReflex.new(subscribe, data: data)
    reflex.process(:increment)
    assert_equal 23, reflex.instance_variable_get(:@count)
  end

  test "only option works" do
    class OnlyCallbackReflex < StimulusReflex::Reflex
      before_reflex :init
      before_reflex :increment_bonus, only: :increment
      before_reflex :decrement_bonus, only: [:decrement]

      def increment
        @count += 1
      end

      def decrement
        @count -= 1
      end

      private

      def init
        @count = 0
      end

      def increment_bonus
        @count += 5
      end

      def decrement_bonus
        @count -= 7
      end
    end

    data = StimulusReflex::ReflexData.new(url: "https://test.stimulusreflex.com", target: "test#decrement", version: StimulusReflex::VERSION)
    reflex = OnlyCallbackReflex.new(subscribe, data: data)
    reflex.process(:decrement)
    assert_equal(-8, reflex.instance_variable_get(:@count))
  end

  test "except option works" do
    class ExceptCallbackReflex < StimulusReflex::Reflex
      before_reflex :init
      before_reflex :increment_bonus, except: :decrement
      before_reflex :decrement_bonus, except: :increment

      def increment
        @count += 1
      end

      def decrement
        @count -= 1
      end

      private

      def init
        @count = 0
      end

      def increment_bonus
        @count += 5
      end

      def decrement_bonus
        @count -= 7
      end
    end

    data = StimulusReflex::ReflexData.new(url: "https://test.stimulusreflex.com", target: "test#increment", version: StimulusReflex::VERSION)
    reflex = ExceptCallbackReflex.new(subscribe, data: data)
    reflex.process(:increment)
    assert_equal 6, reflex.instance_variable_get(:@count)

    data = StimulusReflex::ReflexData.new(url: "https://test.stimulusreflex.com", target: "test#decrement", version: StimulusReflex::VERSION)
    reflex = ExceptCallbackReflex.new(subscribe, data: data)
    reflex.process(:decrement)
    assert_equal(-8, reflex.instance_variable_get(:@count))
  end

  test "skip_before_reflex works" do
    class SkipBeforeCallbackReflex < StimulusReflex::Reflex
      before_reflex :blowup
      before_reflex :init_counter
      before_reflex :bonus

      skip_before_reflex :blowup
      skip_before_reflex :init_counter, if: -> { false }
      skip_before_reflex :bonus, if: -> { true }

      def increment
        @count += 1
      end

      private

      def blowup
        raise StandardError
      end

      def init_counter
        @count = 5
      end

      def bonus
        @count += 100
      end
    end

    data = StimulusReflex::ReflexData.new(url: "https://test.stimulusreflex.com", target: "test#increment", version: StimulusReflex::VERSION)
    reflex = SkipBeforeCallbackReflex.new(subscribe, data: data)
    reflex.process(:increment)
    assert_equal 6, reflex.instance_variable_get(:@count)
  end

  test "skip_after_reflex works" do
    class SkipAfterCallbackReflex < StimulusReflex::Reflex
      after_reflex :blowup
      after_reflex :reset
      after_reflex :clear

      skip_after_reflex :blowup
      skip_after_reflex :reset, if: -> { false }
      skip_after_reflex :clear, if: -> { true }

      def increment
        @count = 0
      end

      private

      def blowup
        raise StandardError
      end

      def reset
        @count += 1
      end

      def clear
        @count += 10
      end
    end

    data = StimulusReflex::ReflexData.new(url: "https://test.stimulusreflex.com", target: "test#increment", version: StimulusReflex::VERSION)
    reflex = SkipAfterCallbackReflex.new(subscribe, data: data)
    reflex.process(:increment)
    assert_equal 1, reflex.instance_variable_get(:@count)
  end

  test "skip_around_reflex works" do
    class SkipAroundCallbackReflex < StimulusReflex::Reflex
      around_reflex :blowup
      around_reflex :around
      around_reflex :bonus

      skip_around_reflex :blowup
      skip_around_reflex :around, if: -> { false }
      skip_around_reflex :bonus, if: -> { true }

      def increment
        @count += 2
      end

      private

      def blowup
        raise StandardError
      end

      def around
        @count = 1
        yield
        @count += 4
      end

      def bonus
        @count += 100
        yield
        @count += 1000
      end
    end

    data = StimulusReflex::ReflexData.new(url: "https://test.stimulusreflex.com", target: "test#increment", version: StimulusReflex::VERSION)
    reflex = SkipAroundCallbackReflex.new(subscribe, data: data)
    reflex.process(:increment)
    assert_equal 7, reflex.instance_variable_get(:@count)
  end

  test "skip_before_reflex works in inherited reflex" do
    class SkipApplicationReflex < StimulusReflex::Reflex
      before_reflex :blowup
      before_reflex :init_counter

      private

      def blowup
        raise StandardError
      end

      def init_counter
        @count = 5
      end
    end

    class InheritedSkipApplicationReflex < SkipApplicationReflex
      skip_before_reflex :blowup

      def increment
        @count += 1
      end
    end

    data = StimulusReflex::ReflexData.new(url: "https://test.stimulusreflex.com", target: "test#increment", version: StimulusReflex::VERSION)
    reflex = InheritedSkipApplicationReflex.new(subscribe, data: data)
    reflex.process(:increment)
    assert_equal 6, reflex.instance_variable_get(:@count)
  end

  test "basic prepend_before_reflex works" do
    class SimplePrependBeforeCallbackReflex < StimulusReflex::Reflex
      before_reflex :two
      prepend_before_reflex :one

      def increment
        @count += 1 if @count == 2
      end

      private

      def one
        @count = 1
      end

      def two
        @count += 1 if @count == 1
      end
    end

    data = StimulusReflex::ReflexData.new(url: "https://test.stimulusreflex.com", target: "test#increment", version: StimulusReflex::VERSION)
    reflex = SimplePrependBeforeCallbackReflex.new(subscribe, data: data)
    reflex.process(:increment)
    assert_equal 3, reflex.instance_variable_get(:@count)
  end

  test "prepend_before_reflex with block works" do
    class BlockPrependBeforeCallbackReflex < StimulusReflex::Reflex
      before_reflex do
        @count += 1 if @count == 1
      end

      prepend_before_reflex do
        @count = 1
      end

      def increment
        @count += 1 if @count == 2
      end
    end

    data = StimulusReflex::ReflexData.new(url: "https://test.stimulusreflex.com", target: "test#increment", version: StimulusReflex::VERSION)
    reflex = BlockPrependBeforeCallbackReflex.new(subscribe, data: data)
    reflex.process(:increment)
    assert_equal 3, reflex.instance_variable_get(:@count)
  end

  test "basic prepend_before_reflex works in inherited reflex" do
    class PrependBeforeCallbackReflex < StimulusReflex::Reflex
      before_reflex :two

      def increment
        @count += 5 if @count == 4
      end

      private

      def two
        @count += 3 if @count == 1
      end
    end

    class InheritedPrependBeforeCallbackReflex < PrependBeforeCallbackReflex
      prepend_before_reflex :one

      private

      def one
        @count = 1
      end
    end

    data = StimulusReflex::ReflexData.new(url: "https://test.stimulusreflex.com", target: "test#increment", version: StimulusReflex::VERSION)
    reflex = InheritedPrependBeforeCallbackReflex.new(subscribe, data: data)
    reflex.process(:increment)
    assert_equal 9, reflex.instance_variable_get(:@count)
  end

  test "basic prepend_around_reflex works" do
    class SimplePrependAroundCallbackReflex < StimulusReflex::Reflex
      around_reflex :two
      prepend_around_reflex :one

      def increment
        @count += 10
      end

      private

      def one
        @count = 1
        yield
        @count += 3 if @count == 23
      end

      def two
        @count += 5 if @count == 1
        yield
        @count += 7 if @count == 16
      end
    end

    data = StimulusReflex::ReflexData.new(url: "https://test.stimulusreflex.com", target: "test#increment", version: StimulusReflex::VERSION)
    reflex = SimplePrependAroundCallbackReflex.new(subscribe, data: data)
    reflex.process(:increment)
    assert_equal 26, reflex.instance_variable_get(:@count)
  end

  test "basic prepend_after_reflex works" do
    class SimplePrependAfterCallbackReflex < StimulusReflex::Reflex
      after_reflex :two
      prepend_after_reflex :one

      def increment
        @count = 1
      end

      private

      def one
        @count += 3 if @count == 6
      end

      def two
        @count += 5 if @count == 1
      end
    end

    data = StimulusReflex::ReflexData.new(url: "https://test.stimulusreflex.com", target: "test#increment", version: StimulusReflex::VERSION)
    reflex = SimplePrependAfterCallbackReflex.new(subscribe, data: data)
    reflex.process(:increment)
    assert_equal 9, reflex.instance_variable_get(:@count)
  end

  test "append before_, around_ and after_reflex works" do
    class AppendCallbackReflex < StimulusReflex::Reflex
      append_before_reflex :before
      append_around_reflex :around
      append_after_reflex :after

      def increment
        @count += 5 if @count == 4
      end

      private

      def before
        @count = 1 unless @counts
      end

      def around
        @count += 3 if @count == 1
        yield
        @count += 9 if @count == 16
      end

      def after
        @count += 7 if @count == 9
      end
    end

    data = StimulusReflex::ReflexData.new(url: "https://test.stimulusreflex.com", target: "test#increment", version: StimulusReflex::VERSION)
    reflex = AppendCallbackReflex.new(subscribe, data: data)
    reflex.process(:increment)
    assert_equal 25, reflex.instance_variable_get(:@count)
  end
end

# standard:enable Lint/ConstantDefinitionInBlock
