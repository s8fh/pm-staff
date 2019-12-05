# name: allow-pms-to-staff
# about: Allow pms to staff even if PMs are otherwise not allowed
# version: 0.1
# authors: pfaffman

after_initialize do
  add_to_class(:guardian, :can_send_personal_message?) do |target|
    puts "u: #{target}, r: "
    target.is_a?(User)  &&
      # User is authenticated
      authenticated? &&
      # Have to be a basic level at least -- consider changing to require user level 1
      (target.staff? || @user.has_trust_level?(SiteSetting.min_trust_to_send_messages)) &&
      # User disabled private message
      (target.staff? || is_staff? || target.user_option.allow_personal_messages) &&
      # PMs are enabled -- TODO: remove target.staff? from this next line!!
      (target.staff? || is_staff? || SiteSetting.enable_personal_messages)
  end
end
