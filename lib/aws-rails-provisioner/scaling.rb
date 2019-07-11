module Aws::RailsProvisioner 
  class Scaling

    # Configuration for Fargate service scaling
    # @param [Hash] options
    #
    # @option options [required, Integer] :max_capacity maximum capacity to scale to
    #
    # @option options [Integer] :min_capacity minimum capacity to scale to
    #   default to 1
    #
    # @option options [Hash] :on_cpu scale out or in to achieve a
    #   target CPU utilization
    #   @example: at `aws-rails-provisioner.yml`
    #     scaling:
    #       on_cpu:
    #         target_util_percent: 80
    #         scale_in_cool_down: 300
    #   @see {Aws::RailsProvisioner::Scaling::BaseScaling}
    #
    # @option options [Hash] :on_memory scale out or in to achieve a
    #   target memory utilization
    #   @example: at `aws-rails-provisioner.yml`
    #     scaling:
    #       on_memory:
    #         target_util_percent: 80
    #         scale_out_cool_down: 200
    #   @see {Aws::RailsProvisioner::Scaling::BaseScaling}
    #
    # @option options [Hash] :on_metric scale out or in based on a
    #   metric value
    #   @example: at `aws-rails-provisioner.yml`
    #     on_metric:
    #       adjustment_type: percentchangeincapacity
    #       min_adjustment_magnitude: 10
    #       cooldown: 300
    #       metric:
    #         name: foo
    #   @see {Aws::RailsProvisioner::Scaling::MetricScaling}
    #
    # @option options [Hash] :on_custom_metric scale out or in to track
    #   a custom metric
    #   @example: at `aws-rails-provisioner.yml`
    #     scaling:
    #       on_custom_metric:
    #         target_value: 100
    #         scale_in_cooldown: 300
    #         scale_out_cooldown: 500
    #         metric:
    #           name: foo
    #   @see {Aws::RailsProvisioner::Scaling::MetricScaling}
    #
    # @option options [Hash] :on_request scale out or in to achieve a
    #   target ALB request count per target
    #   @example: at `aws-rails-provisioner.yml`
    #     scaling:
    #       on_request:
    #         requests_per_target: 100000
    #         disable_scale_in: true
    #   @see {Aws::RailsProvisioner::Scaling::BaseScaling}
    #
    # @option options [Hash] :on_schedule scale out or in based on time
    #   @example: at `aws-rails-provisioner.yml`
    #     scaling:
    #       on_schedule:
    #         schedule: 'at(yyyy-mm-ddThh:mm:ss)'
    #         max_capacity: 10
    #         min_capacity: 5
    #   @see {Aws::RailsProvisioner::Scaling::ScheduleScaling}
    #
    def initialize(options = {})
      @max_capacity = options.fetch(:max_capacity)
      @min_capacity = options[:min_capacity]

      @on_cpu = _scaling_props(:cpu, options[:cpu])
      @on_memory = _scaling_props(:memory, options[:memory])
      @on_metric = _scaling_props(:metric, options[:metric])
      @on_request = _scaling_props(:request, options[:request])
      @on_schedule = _scaling_props(:schedule, options[:schedule])
      @to_track_custome_metric = _scaling_props(:custom, options[:custom_metric])
    end

    # @return [Integer]
    attr_reader :max_capacity

    # @return [Integer]
    attr_reader :min_capacity

    # @return [BaseScaling]
    attr_reader :on_cpu

    # @return [BaseScaling]
    attr_reader :on_memory

    # @return [BaseScaling]
    attr_reader :on_request

    # @return [MetricScaling]
    attr_reader :on_metric

    # @return [MetricScaling]
    attr_reader :to_track_custom_metric

    # @return [ScheduleScaling]
    attr_reader :on_schedule

    private

    def _scaling_props(type, opts)
      return if opts.nil?
      case type
      when :cpu, :memory, :request
        BaseScaling.new(type, opts)
      when :metric, :custom
        MetricScaling.new(type, opts)
      when :schedule
        ScheduleScaling.new(type, opts)
      else
        raise Aws::RailsProvisioner::Errors::ValidationError.new(
          'Unsupported Scaling type.')
      end
    end

    class MetricScaling

      # Configuration for metric scaling policy
      # @param [Hash] options
      #
      # @option options [String] :adjustment_type how the adjustment numbers
      #   inside 'intervals' are interpreted, available for `:on_metric`, supporting
      #   types: `change_in_capacity`, `percent_change_in_capacity` or `exact_capacity`
      #
      # @option options [Integer] :min_adjustment_magnitude available for
      #   `:on_metric`, when :adjustment_type set to `percentchangeincapacity`
      #   minimum absolute number to adjust capacity with as result of percentage scaling.
      #
      # @option options [Integer] :cooldown grace period after scaling activity
      #   in seconds, available for `:on_metric`
      #
      # @option options [Array<ScalingInterval>] :scaling_steps intervals for scaling, array of
      #   Aws::RailsProvisioner::Scaling::MetricScaling::ScalingInterval, available for
      #   `:on_metric`
      #   @example: at `aws-rails-provisioner.yml`
      #     on_metric:
      #       scaling_steps:
      #         -
      #           change: 10
      #           lower: 30
      #           upper: 60
      #         -
      #           change: 20
      #           lower: 0
      #           upper: 20
      #   @see {Aws::RailsProvisioner::Scaling::MetricScaling::ScalingInterval}
      #
      # @option options [Hash] :metric
      #   @example: at `aws-rails-provisioner.yml`
      #     on_metric:
      #       metric:
      #         name: foo
      #         namespace: bar
      #         dimensions:
      #           key:value
      #     on_custom_metric:
      #       metric:
      #         name: baz
      #   @see {Aws::RailsProvisioner::Scaling::MetricScaling::Metric}
      #
      # @option options [Integer] :target_value the target value to achieve for the metric
      #   available for :custom_metric
      # 
      # @option options [Boolean] :disable_scale_in whether scale in by the
      #   target tracking policy is disabled, available for :custom_metric
      #
      # @option options [Integer] :scale_in_cooldown period (in seconds) after a scale in activity
      #   completes before another scale in activity can start, available for :custom_metric
      #
      # @option options [Integer] :scale_out_cooldown period (in seconds) after a scale out activity
      #   completes before another scale out activity can start, available for :custom_metric
      #
      def initialize(type, options)
        @metric = Metric.new(type, options)
        if type == :custom
          @target_value = options[:target_value]
          @disable_scale_in = !!options[:disable_scale_in]
          @scale_in_cooldown = options[:scale_in_cooldown]
          @scale_out_cooldown = options[:scale_out_cooldown]
        else # :metric
          @scaling_steps = _scaling_steps(options[:scaling_steps] || [])
          @cooldown_sec = options[:cooldown]
          @adjustment_type = Aws::RailsProvisioner::Utils.adjustment_type(
            options[:adjustment_type]) if options[:adjustment_type]
          if @adjustment_type == 'PercentChangeInCapacity'
            @min_adjustment_magnitude = options[:min_adjustment_magnitude]
          end
        end
      end

      # @return [Metric]
      attr_reader :metric

      # @return [Integer]
      attr_reader :target_value

      # @return [Boolean]
      attr_reader :disable_scale_in

      # @return [Integer]
      attr_reader :scale_in_cooldown

      # @return [Integer]
      attr_reader :scale_out_cooldown

      # @return [Array<ScalingInterval>]
      attr_reader :scaling_steps

      # @return [String]
      attr_reader :adjustment_type

      # @return [Integer]
      attr_reader :cooldown_sec

      # @return [Integer]
      attr_reader :min_adjustment_magnitude

      class ScalingInterval

        # Configuration for each scaling interval in
        # scaling steps
        # @param [Hash] options
        #
        # @option options [Integer] :change the capacity adjustment
        #   to apply in this interval, interpreted differently based on :adjustment_type
        #   * `changeincapacity` - add the adjustment to the current capacity. The number
        #     can be positive or negative
        #   * `percentchangeincapacity` - add or remove the given percentage of the
        #     current capacity to itself. The number can be in the range [-100..100]
        #   * `exactcapacity` - set the capacity to this number. The number must be positive 
        #
        # @option options [Integer] :lower lower bound of the interval, scaling
        #   adjustment will be applied if the metric is higher than this value
        #
        # @option options [Integer] :upper upper bound of the interval, scaling
        #   adjustment will be applied if the metric is lower than this value
        #
        def initialize(options = {})
          @change = options[:change]
          @lower = options[:lower]
          @upper = options[:upper]
        end

        # @return [Integer]
        attr_reader :change

        # @return [Integer]
        attr_reader :lower

        # @return [Integer]
        attr_reader :upper

      end

      class Metric

        # Metric to scale on
        # https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/cloudwatch_concepts.html
        # @param [Hash] options
        #
        # @option options [String] :name
        #
        # @option options [String] :namespace
        #
        # @option options [Integer] :period
        #
        # @option options [String] :statistic
        #
        # @option options [String] :color
        #
        # @option options [String] :label
        #
        # @option options [Hash] :dimensions
        #
        # @option options [String] :unit available unit:
        #   `Seconds`, `Microseconds`, `Milliseconds`
        #   `Bytes`, `Kilobytes`, `Megabytes`, `Gigabytes`, `Terabytes`
        #   `Bits`, `Kilobits`, `Megabits`, `Gigabits`, `Terabits`,
        #   `Percent`, `Count`, `None`,
        #   `BytesPerSecond`, `KilobytesPerSecond`, `MegabytesPerSecond`,
        #   `GigabytesPerSecond`, `TerabytesPerSecond`, `BitsPerSecond`,
        #   `KilobitsPerSecond`, `MegabitsPerSecond`, `GigabitsPerSecond`,
        #   `TerabitsPerSecond`, `CountPerSecond` 
        #
        def initialize(type, options = {})
          @name = options.fetch(:name)
          @namespace = options.fetch(:namespace)
          @color = options[:color]
          @dimensions = Aws::RailsProvisioner::Utils.to_pairs(
            options[:dimensions]) if options[:dimensions]
          @label = options[:label]
          @period_sec = options[:period]
          @statistic = options[:statistics]
          @unit = options[:unit]
        end

        # @return [String]
        attr_reader :name

        # @return [String]
        attr_reader :namespace

        # @return [String]
        attr_reader :color

        # @return [String]
        attr_reader :dimensions

        # @return [String]
        attr_reader :label

        # @return [Integer]
        attr_reader :period_sec

        # @return [String]
        attr_reader :statistic

        # @return [String]
        attr_reader :unit

      end

      def scaling_steps?
        @scaling_steps && !@scaling_steps.empty?
      end

      private

      def _scaling_steps(steps)
        steps.map {|step| ScalingInterval.new(step)}
      end

    end

    class BaseScaling

      # Configuration for scaling policy
      # @param [Hash] options
      #
      # @option options [Boolean] :disable_scale_in whether scale in
      #   by the target tracking policy is disabled, default as `false`
      #
      # @option options [Integer] :scale_in_cooldown period in seconds
      #   after a scale in activity completes before another scale in activity
      #   can start
      #
      # @option options [Integer] :scale_out_cooldown period in seconds 
      #   after a scale in activity completes before another scale in activity
      #   can start
      #
      # @option options [Integer] :target_util_percent available for
      #   * :on_cpu , target average CPU utilization across the task
      #   * :on_memory , target average memory utilization across the task
      #   
      # @option options [Integer] :requests_per_target available for
      #   :on_request, ALB requests per target
      #
      def initialize(type, options = {})
        @disable_scale_in = !!options[:disable_scale_in]
        @scale_in_cooldown = options[:scale_in_cooldown]
        @scale_out_cooldown = options[:scale_out_cooldown]
        var_name = _type_2_var(type)
        instance_variable_set("@#{var_name}", options[var_name.to_sym])
      end

      # @return [Integer]
      attr_reader :target_util_percent

      # @return [Integer]
      attr_reader :requests_per_target

      # @return [Boolean]
      attr_reader :disable_scale_in

      # @return [Integer]
      attr_reader :scale_in_cooldown

      # @return [Integer]
      attr_reader :scale_out_cooldown

      private

      def _type_2_var(type)
        case type
        when :cpu, :memory then 'target_util_percent' 
        when :request then 'requests_per_target'
        end
      end

    end

    class ScheduleScaling

      # Configurations for scaling policy based on time
      # @param [Hash] options
      #
      # @option options [required, String] :schedule when to perform this action
      #   support formats:
      #     * 'at(yyyy-mm-ddThh:mm:ss)'
      #     * 'rate(value unit)'
      #     * 'cron(fields)'
      #
      # @option options [Integer] :max_capacity the new maximum capacity
      #
      # @option options [Integer] :min_capacity the new minimum capacity
      #
      # @option options [Integer] :start_time when this scheduled action becomes active 
      #    milliseconds since Epoch time
      #
      # @option options [Integer] :end_time when this scheduled action expires
      #    milliseconds since Epoch time
      #
      def initialize(options = {})
        @schedule = options.fetch(:schedule)
        @max_capacity = options[:max_capacity]
        @min_capacity = options[:min_capacity]
        @start_time = options[:start_time]
        @end_time = options[:end_time]
      end

      # @return [String]
      attr_reader :schedule

      # @return [Integer]
      attr_reader :max_capacity

      # @return [Integer]
      attr_reader :min_capacity

      # @return [Integer]
      attr_reader :start_time

      # @return [Integer]
      attr_reader :end_time

    end

  end

end
