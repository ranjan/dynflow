module Dynflow
  module ActiveJob
    module QueueAdapters
      module QueueMethods
        def enqueue(job)
          ::Rails.application.dynflow.world.trigger(JobWrapper, job.serialize).tap do |plan|
            job.provider_job_id = plan.id
          end
        end

        def enqueue_at(job, timestamp)
          ::Rails.application.dynflow.world.delay(JobWrapper, { :start_at => Time.at(timestamp) }, job.serialize).tap do |plan|
            job.provider_job_id = plan.id
          end
        end
      end

      # To use Dynflow, set the queue_adapter config to +:dynflow+.
      #
      #   Rails.application.config.active_job.queue_adapter = :dynflow
      class DynflowAdapter
        # For ActiveJob >= 5
        include QueueMethods

        # For ActiveJob <= 4
        extend QueueMethods
      end

      class JobWrapper < Dynflow::Action
        def queue
          input[:queue].to_sym
        end

        def plan(attributes)
          input[:job_class] = attributes['job_class']
          input[:job_arguments] = attributes['arguments']
          input[:queue] = attributes['queue_name']
          plan_self
        end

        def run
          input[:job_class].constantize.perform_now(*input[:job_arguments])
        end

        def label
          input[:job_class]
        end

        def rescue_strategy
          Action::Rescue::Skip
        end
      end
    end
  end
end
