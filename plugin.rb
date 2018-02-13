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

  def moderation_pp_can_create_post(parent)
  	# we only restrict more
  	return true unless parent
  	return true unless SiteSetting.moderation_pp_enabled

	binding.pry
	return false if mpp_has_reached_daily_max_posts?
	return false if mpp_has_reached_daily_max_posts_on_topic?(parent) 

  	true
  end

  def can_create_post?(parent)
    # We override the original Guardian method to figure out our own
    return false if !moderation_pp_can_create_post(parent) 
    super(parent)
  end
end

Guardian.send :include, ModerationPlusPlusGuardian

puts "yeah"