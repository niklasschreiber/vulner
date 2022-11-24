# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20160127
#
#

def sorted_spec?
  (ENV['SPEC_SORT'] || '0').to_s == '1'
end

def pretty_diffs?
  (ENV['PRETTY_DIFFS'] || '0').to_s == '1'
end

# PATCH for Minitest bad :io option handling
module Minitest
  module Reporters
    #
    class BaseReporter < Minitest::StatisticsReporter
      # PATCH 1a: redefined initialize to use the :io option
      def initialize(options = {})
        # PATCH 1b: changed first super arguments from $stdout to the specified :io option
        super(options.delete(:io) || $stdout, options)
        self.tests = []
      end

      # PATCH 2a: redefine io attr_writer to avoid overwrite
      def io=(value)
        # PATCH 2b: avoid the oveerwrite of io once it has been assigned
        @io ||= value
        @io
      end
    end

    #
    class SpecReporter < BaseReporter
      # PATCH 3: define the color methods for the SpecReporter in the base class (same impl. as DefaultReporter)
      def color?
        return @color if defined?(@color)
        @color = @options.fetch(:color) do
          io.tty? && (
            ENV['TERM'] =~ /^screen|color/ ||
            ENV['EMACS'] == 't'
          )
        end
      end

      def green(&block)
        color? ? ANSI::Code.green(&block) : yield
      end

      def yellow(&block)
        color? ? ANSI::Code.yellow(&block) : yield
      end

      def red(&block)
        color? ? ANSI::Code.red(&block) : yield
      end

      # PATCH 4: polish output test descriptions
      def record(test) # rubocop:disable Metrics/AbcSize
        super
        if test.name.respond_to?(:gsub)
          print pad_test(test.name.gsub(/^test_\d+_/, ''))
          print_colored_status(test)
          print(format(' (%.2fs)', test.time)) unless test.time.nil?
          puts
        end
        if !test.skipped? && test.failure
          print_info(test.failure)
          puts
        end
        test
      end

      def before_suite(suite)
        puts suite.to_s.gsub('::/', '/').gsub('::.', '.').gsub('::#', '#').gsub(/::((\w|à|è|ì|ò|ù|')+) /, ' \1 ')
      end
    end

    # rubocop:disable all
    class HtmlReporter < BaseReporter
      # PATCH: remove it from the output
      def friendly_name(test)
        groups = test.name.scan(/(test_\d+_)(.*)/i)
        return test.name if groups.empty?
        "#{groups[0][1]}"
      end

      # PATCH: remove puts
      def start
        super
        FileUtils.mkdir_p(@reports_path)
        File.delete(html_file) if File.exist?(html_file)
      end

      # PATCH: fix round with floor in hours and minutes
      def total_time_to_hms
        return ('%.2fs' % total_time) if total_time < 1

        hours = (total_time / (60 * 60)).floor
        minutes = ((total_time / 60) % 60).floor.to_s.rjust(2,'0')
        seconds = (total_time % 60).round.to_s.rjust(2,'0')

        "#{ hours }h#{ minutes }m#{ seconds }s"
      end


      # PATCH: fix suite name
      def summarize_suite(suite, tests)
        summary = Hash.new(0)
        summary[:name] = suite.to_s.gsub('::/', '/').gsub('::.', '.').gsub('::#', '#').gsub(/::((\w|à|è|ì|ò|ù|')+) /, ' \1 ')
        tests.each do |test|
          summary[:"#{result(test)}_count"] += 1
          summary[:assertion_count] += test.assertions
          summary[:test_count] += 1
          summary[:time] += test.time
        end
        summary[:has_errors_or_failures] = (summary[:fail_count] + summary[:error_count]) > 0
        summary[:has_skipps] = summary[:skip_count] > 0
        summary
      end
    end

    class JUnitReporter < BaseReporter

      # PATCH: change the suite name of single output file
      def report
        super

        puts "Writing XML reports to #{@reports_path}"
        suites = tests.group_by(&:class)

        if @single_file
          write_xml_file_for("spec", tests.group_by(&:class).values.flatten)
        else
          suites.each do |suite, tests|
            write_xml_file_for(suite, tests)
          end
        end

      end

      # PATCH: change the name of single output file
      def filename_for(suite)
        file_counter = 0
        suite_name = suite.to_s[0..240].gsub(/[^a-zA-Z0-9]+/, '-') # restrict max filename length, to be kind to filesystems
        filename = @single_file ? @single_file : "TEST-#{suite_name}.xml"
        while File.exist?(File.join(@reports_path, filename)) # restrict number of tries, to avoid infinite loops
          file_counter += 1
          filename = "TEST-#{suite_name}-#{file_counter}.xml"
          puts "Too many duplicate files, overwriting earlier report #{filename}" and break if file_counter >= 99
        end
        File.join(@reports_path, filename)
      end
    end
    # rubocop:enable all
  end
end

# New assertions and expections for raises_msg
# rubocop:disable Lint/RescueException, Lint/InheritException
module Minitest
  # PATCH: allow change of failure backtrace
  class Assertion < Exception
    def update_location_from_caller(caller_shift = 0)
      @location = caller[caller_shift + 1].sub(/:in .*$/, '')
    end

    def location
      @location ||= begin
                      last_before_assertion = ''
                      backtrace.reverse_each do |s|
                        break if s =~ /in .(assert|refute|flunk|pass|fail|raise|must|wont)/
                        last_before_assertion = s
                      end
                      last_before_assertion.sub(/:in .*$/, '')
                    end
    end
  end

  #
  module Assertions
    # keep original 5.8 assert implementation to avoid deprecation warning on version >= 5.8.2
    def assert_equal(exp, act, msg = nil)
      msg = message(msg, E) { diff exp, act }
      assert exp == act, msg
    end

    ##
    # Fails unless the block raises one of +exp+. Returns the
    # exception matched so you can check the message, attributes, etc.
    #
    # +exp+ takes an optional message on the end to help explain
    # failures and defaults to StandardError if no exception class is
    # passed.
    def assert_raises_msg(*exp) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      exception_message = exp.pop
      exp << StandardError if exp.empty?

      begin
        yield
      rescue *exp => e
        case exception_message
        when String
          e.message.must_equal exception_message
        when Regexp
          e.message.must_match exception_message
        end
        pass # count assertion
        return e
      rescue Minitest::Skip, Minitest::Assertion
        # don't count assertion
        raise
      rescue SignalException, SystemExit
        raise
      rescue Exception => e
        flunk proc {
          exception_details(e, "#{mu_pp(exp)} exception expected, not")
        }
      end

      exp = exp.first if exp.size == 1

      flunk "#{mu_pp(exp)} expected but nothing was raised."
    end

    def assert_completes_in(max_seconds, max_memory = nil, hash = {}) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
      Irma.gc
      if max_memory
        stability_start_time = Time.now

        # per consentire al GC di effettuare il cleanup e stabilizzare la memoria
        loop do
          start_memory = memory_used
          sleep(hash[:sleep_time_before] || 0.1)
          break if (memory_used - start_memory).abs < (hash[:max_delta_memory] || 10_000)
        end
        start_memory = memory_used
      end
      start_time = Time.now
      extra_msg = max_memory ? "(memoria attuale #{start_memory}, tempo di stabilizzazione #{(start_time - stability_start_time).round(1)} secondi)" : ''
      logger.info("PERFORMANCE TEST #{name} => inizio #{hash[:what] || 'esecuzione'}#{extra_msg}")

      yield
      elapsed = Time.now - start_time

      Irma.gc

      if max_memory
        stability_start_time = Time.now
        # per consentire al GC di effettuare il cleanup e stabilizzare la memoria
        loop do
          final_memory = memory_used
          sleep(hash[:sleep_time_after] || 0.1)
          break if (memory_used - final_memory).abs < (hash[:max_delta_memory] || 10_000)
        end
        delta_memory = memory_used - start_memory
      end
      extra_msg = max_memory ? " (memoria utilizzata #{delta_memory}, tempo di stabilizzazione #{(Time.now - stability_start_time).round(1)} secondi)" : ''
      logger.info("PERFORMANCE TEST #{name} => #{hash[:what] || 'esecuzione'} completata in #{elapsed} secondi#{extra_msg}")

      elapsed.must_be :<=, max_seconds
      delta_memory.must_be(:<=, max_memory) if max_memory
    end
  end

  #
  module Expectations
    infect_an_assertion :assert_raises_msg, :must_raise_msg, :block
    infect_an_assertion :assert_completes_in, :must_complete_in, :block
  end

  #
  # HACK: to sort test alpha
  #
  if sorted_spec?

    def self.__run(reporter, options)
      suites = Runnable.runnables
      parallel, serial = suites.partition { |s| s.test_order == :parallel }

      # If we run the parallel tests before the serial tests, the parallel tests
      # could run in parallel with the serial tests. This would be bad because
      # the serial tests won't lock around Reporter#record. Run the serial tests
      # first, so that after they complete, the parallel tests will lock when
      # recording results.
      serial.map { |suite| suite.run reporter, options } + parallel.map { |suite| suite.run reporter, options }
    end

    def Test.test_order
      :alpha
    end
  end

  #
  # EXTENSION: log init end result of test
  #
  class Test
    def logger
      DEFAULT_LOGGER
    end

    def log_prefix
      "[#{self.class}##{name}]"
    end

    def before_setup
      @st = Time.now
      logger.info("#{log_prefix} TEST BEGIN") if logger
      Irma::NativeExprParser.write_testfile_for_lib_irmaformuz(%@  printf("#{log_prefix} TEST BEGIN\\n");\n@) if ENV['OUTPUT_FOR_TEST_LIB_IRMAFORMUZ']
      super
    end

    def after_teardown # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      if skipped?
        logger.warn("#{log_prefix} TEST END (SKIPPED)") if logger
      elsif logger
        logger.send(passed? ? :info : :error, "#{log_prefix} TEST END #{passed? ? 'SUCCESS' : 'FAILURE'} (#{(Time.now - @st).round(3)})" + (failures.empty? ? '' : ": #{failures.first.message}"))
        Irma::NativeExprParser.write_testfile_for_lib_irmaformuz(%@  printf("#{log_prefix} TEST END #{passed? ? 'SUCCESS' : 'FAILURE'}\\n");\n@) if ENV['OUTPUT_FOR_TEST_LIB_IRMAFORMUZ']
      end
      super
    end
  end

  # web support
  require 'ostruct'
  class Spec
    def get(path = '/', env = {}, &block)
      req(path, env.merge('REQUEST_METHOD' => 'GET'), &block)
    end

    def post(path = '/', env = {}, &block)
      req(path, env.merge('REQUEST_METHOD' => 'POST'), &block)
    end

    def del(path = '/', env = {}, &block)
      req(path, env.merge('REQUEST_METHOD' => 'DELETE'), &block)
    end

    def put(path = '/', env = {}, &block)
      req(path, env.merge('REQUEST_METHOD' => 'PUT'), &block)
    end

    def req(path = '/', env = {}, &block) # rubocop:disable Metrics/AbcSize
      require 'irma/web'
      if path.is_a?(Hash)
        env = path
      else
        env['PATH_INFO'] = path
      end
      env = { 'QUERY_STRING' => '', 'REQUEST_METHOD' => 'GET', 'PATH_INFO' => '/', 'SCRIPT_NAME' => '' }.merge(env)
      Irma::Web::App.class_eval(&block) if block_given?
      response = Irma::Web::App.call(env)
      s = ''
      b = response[2]
      b.each { |x| s << x }
      b.close if b.respond_to?(:close)
      OpenStruct.new(status: response[0], header: response[1], body: s)
    end
  end

  #
  Test.make_my_diffs_pretty! if pretty_diffs?
end

# PATCH for changing the behaviour of before(:all) and after(:all) (now like rspec, the block is called once)
require 'minitest/hooks/default'

# rubocop:disable all
module Minitest::Hooks::ClassMethods
  # If type is :all, set the before_all hook instead of the before hook.
  def before(type=nil, &block) # rubocop:disable all
    if type == :all
      puts "I'M here #{self}, #{self.class} for before_all" if ENV['MINITEST_HOOK_PUTS'] == '1'
      me = self
      class <<me
        attr_accessor :before_all_counter
      end
      me.before_all_counter = 0
      define_method(:before_all) do
        super()
        if me.before_all_counter == 0 || !sorted_spec?
          puts "#{me}.before_all_counter is 0, invoking block" if ENV['MINITEST_HOOK_PUTS'] == '1'
          instance_exec(&block)
        else
          puts "#{me}.before_all_counter = #{me.before_all_counter} (!= 0)" if ENV['MINITEST_HOOK_PUTS'] == '1'
        end
        me.before_all_counter += 1
      end
      nil
    else
      super
    end
  end

  # If type is :all, set the after_all hook instead of the after hook.
  def after(type=nil, &block) # rubocop:disable all
    if type == :all
      puts "I'M here #{self}, #{self.class} for after_all" if ENV['MINITEST_HOOK_PUTS'] == '1'
      me = self
      class <<me
        attr_accessor :after_all_counter
      end
      me.after_all_counter = nil
      define_method(:after_all) do
        me.after_all_counter ||= begin
                                   test_desc = [me, me.descendants].flatten.select do |desc|
                                     ((desc.to_s||'' == me.to_s) || (desc.to_s||'').start_with?("#{me}::")) && !desc.instance_methods.select { |m| m.match(/^test_/)}.empty?
                                   end
                                   puts "#{me} test_desc: #{test_desc} (#{test_desc.size})" if ENV['MINITEST_HOOK_PUTS'] == '1'
                                   test_desc.size
                                 end
        me.after_all_counter -= 1
        if me.after_all_counter == 0 || !sorted_spec?
          puts "#{me}.after_all_counter is 0, invoking block" if ENV['MINITEST_HOOK_PUTS'] == '1'
          instance_exec(&block)
        else
          puts "#{me}.after_all_counter = #{me.after_all_counter} (!= 0)" if ENV['MINITEST_HOOK_PUTS'] == '1'
        end
        super()
      end
      nil
    else
      super
    end
  end
end
# ruboco:enable all
