# name: moderation-plusplus
# about: Enhance Moderation Features for Discourse
# version: 0.0.3
# authors: Benjamin Kampmann, Guido Drehsen



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

  def mpp_has_reached_daily_max_posts_in_cat?(category)
    return true if current_user
      .posts
      .public_posts
      .created_since(Time.now - 24.hours)
      .joins(:topic)
      .where("topic.id = ?", category.id)
      .count() >= SiteSetting.moderation_pp_daily_max_posts
  end

  def mpp_has_reached_daily_max_posts_on_topic?(topic, limit)
    return true if current_user
      .posts
      .public_posts
      .created_since(Time.now - 24.hours)
      .where(:topic => topic)
      .count() >= limit
  end

  def mpp_has_reached_fiveday_max_posts_on_topic?(topic, limit)
    return true if current_user
      .posts
      .public_posts
      .created_since(Time.now - 120.hours)
      .where(:topic => topic)
      .count() >= limit
  end

  def mpp_has_reached_max_posts_on_topic?(topic, limit)
    return true if current_user
      .posts
      .public_posts
      .where(:topic => topic)
      .count() >= limit
  end

  def moderation_pp_can_create_post(topic)
    # only in charge if enabled.
    return true unless SiteSetting.moderation_pp_enabled
    # we only restrict more
    return true unless topic
    # we are not in charge for direct messages
    return true unless topic.category

    cat_fields = topic.category.custom_fields

    if cat_fields['moderation_pp_daily_max_posts'].to_i > 0
      return false if mpp_has_reached_daily_max_posts_in_cat?(category)

    elsif cat_fields['moderation_pp_daily_max_posts'] != -1 && SiteSetting.moderation_pp_daily_max_posts
      return false if mpp_has_reached_daily_max_posts?
    end


    if cat_fields['moderation_pp_daily_max_posts_per_topic'].to_i > 0
      return false if mpp_has_reached_daily_max_posts_on_topic?(topic,
          cat_fields['moderation_pp_daily_max_posts_per_topic'])
    elsif cat_fields['moderation_pp_daily_max_posts_per_topic'] != -1 && SiteSetting.moderation_pp_daily_max_posts_per_topic
      return false if mpp_has_reached_daily_max_posts_on_topic?(topic,
          SiteSetting.moderation_pp_daily_max_posts_per_topic)
    end


    if cat_fields['moderation_pp_fiveday_max_posts_per_topic'].to_i > 0
      return false if mpp_has_reached_fiveday_max_posts_on_topic?(topic,
          cat_fields['moderation_pp_fiveday_max_posts_per_topic'])
    elsif cat_fields['moderation_pp_fiveday_max_posts_per_topic'] != -1 && SiteSetting.moderation_pp_fiveday_max_posts_per_topic
      return false if mpp_has_reached_fiveday_max_posts_on_topic?(topic,
          SiteSetting.moderation_pp_fiveday_max_posts_per_topic)
    end

    if cat_fields['moderation_pp_max_posts_per_topic'].to_i > 0
      return false if mpp_has_reached_max_posts_on_topic?(topic,
          cat_fields['moderation_pp_max_posts_per_topic'])
    elsif cat_fields['moderation_pp_max_posts_per_topic'] != 1 && SiteSetting.moderation_pp_max_posts_per_topic  
      return false if mpp_has_reached_max_posts_on_topic?(topic,
          SiteSetting.moderation_pp_max_posts_per_topic)
    end

    true
  end

  def can_create_post?(topic)
    # We override the original Guardian method to figure out our own
    return false if !moderation_pp_can_create_post(topic) 
    super(topic)
  end
end

after_initialize do

  # custom fields per category
  Category.register_custom_field_type('moderation_pp_daily_max_posts', :integer)
  Category.register_custom_field_type('moderation_pp_daily_max_posts_per_topic', :integer)
  Category.register_custom_field_type('moderation_pp_fiveday_max_posts_per_topic', :integer)
  Category.register_custom_field_type('moderation_pp_max_posts_per_topic', :integer)
  puts "Now with category based limitations"

  Guardian.send :include, ModerationPlusPlusGuardian
  puts "DC Mod++: We have patched!"
end

puts "DC Mod++: We have been loaded"
