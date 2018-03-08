# name: moderation++
# about: Enhance Moderation Features for Discourse
# version: 0.0.1
# authors: Benjamin Kampmann, Ronja



enabled_site_setting :moderation_pp_enabled

require_dependency 'guardian'
require_dependency 'current_user'

module ModerationPlusPlusGuardian

  def mpp_has_reached_daily_max_posts?
    return true if current_user
      .posts
      .public_posts
      .created_since(Time.now - 24.hours)
      .count() >= SiteSetting.moderation_pp_daily_max_posts
  end

  def mpp_has_reached_daily_max_posts_on_topic?(topic)
    return true if current_user
      .posts
      .public_posts
      .created_since(Time.now - 24.hours)
      .where(:topic => topic)
      .count() >= SiteSetting.moderation_pp_daily_max_posts_per_topic
  end

  def mpp_has_reached_fiveday_max_posts_on_topic?(topic)
    return true if current_user
      .posts
      .public_posts
      .created_since(Time.now - 120.hours)
      .where(:topic => topic)
      .count() >= SiteSetting.moderation_pp_fiveday_max_posts_per_topic
  end

  def mpp_has_reached_max_posts_on_topic?(topic)
    return true if current_user
      .posts
      .public_posts
      .where(:topic => topic)
      .count() >= SiteSetting.moderation_pp_max_posts_per_topic
  end

  def moderation_pp_can_create_post(parent)
    # we only restrict more
    return true unless parent
    return true unless SiteSetting.moderation_pp_enabled

    return false if mpp_has_reached_daily_max_posts?
    return false if mpp_has_reached_daily_max_posts_on_topic?(parent)
    return false if mpp_has_reached_fiveday_max_posts_on_topic?(parent)
    return false if mpp_has_reached_max_posts_on_topic?(parent)

    true
  end

  def can_create_post?(parent)
    # We override the original Guardian method to figure out our own
    return false if !moderation_pp_can_create_post(parent) 
    super(parent)
  end
end

module ModerationPlusPlusTopicViewSerializer
  def self.included(base)
    base.instance_eval do
      alias_method :details_before_extra_create_post, :details
      alias_method :details, :new_details
    end
  end
  def new_details
    # and explicitly export the flag to make sure
    # the UI shows this properly
    data = details_before_extra_create_post
    data[:can_create_post] = false if !data[:can_create_post]
    data
  end
end


after_initialize do

  Guardian.send :include, ModerationPlusPlusGuardian
  TopicViewSerializer.send :include, ModerationPlusPlusTopicViewSerializer
  puts "DC Mod++: We have patched!"
end

puts "DC Mod++: We have been loaded"