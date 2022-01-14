# frozen_string_literal: true

class ApplicationExperiment < Gitlab::Experiment # rubocop:disable Gitlab/NamespacedClass
  def enabled?
    return false if Feature::Definition.get(feature_flag_name).nil? # there has to be a feature flag yaml file
    return false unless Gitlab.dev_env_or_com? # we have to be in an environment that allows experiments

    # the feature flag has to be rolled out
    Feature.get(feature_flag_name).state != :off # rubocop:disable Gitlab/AvoidFeatureGet
  end

  def publish(_result = nil)
    super

    publish_to_client
  end

  def publish_to_client
    return unless should_track?

    Gon.push({ experiment: { name => signature } }, true)
  rescue NoMethodError
    # means we're not in the request cycle, and can't add to Gon. Log a warning maybe?
  end

  def publish_to_database
    ActiveSupport::Deprecation.warn('publish_to_database is deprecated and should not be used for reporting anymore')

    return unless should_track?

    # if the context contains a namespace, group, project, user, or actor
    value = context.value
    subject = value[:namespace] || value[:group] || value[:project] || value[:user] || value[:actor]
    return unless ExperimentSubject.valid_subject?(subject)

    variant_name = :experimental if variant&.name != 'control'
    Experiment.add_subject(name, variant: variant_name || :control, subject: subject)
  end

  def control_behavior
    # define a default nil control behavior so we can omit it when not needed
  end

  def track(action, **event_args)
    super(action, **tracking_context.merge(event_args))
  end

  # TODO: remove
  # This is deprecated logic as of v0.6.0 and should eventually be removed, but
  # needs to stay intact for actively running experiments. The new strategy
  # utilizes Digest::SHA2, a secret seed, and generates a 64-byte string.
  def key_for(source, seed = name)
    source = source.keys + source.values if source.is_a?(Hash)

    ingredients = Array(source).map { |v| identify(v) }
    ingredients.unshift(seed)

    Digest::MD5.hexdigest(ingredients.join('|'))
  end

  def nest_experiment(other)
    instance_exec(:nested, { label: other.name }, &Configuration.tracking_behavior)
  end

  private

  def tracking_context
    {
      namespace: context.try(:namespace) || context.try(:group),
      project: context.try(:project),
      user: user_or_actor
    }.compact || {}
  end

  def user_or_actor
    actor = context.try(:actor)
    actor.respond_to?(:id) ? actor : context.try(:user)
  end

  def feature_flag_name
    name.tr('/', '_')
  end

  def experiment_group?
    Feature.enabled?(feature_flag_name, self, type: :experiment, default_enabled: :yaml)
  end
end
