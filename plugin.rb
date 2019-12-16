# name: allow-pms-to-staff
# about: Allow pms to staff even if PMs are otherwise not allowed
# version: 0.1
# authors: pfaffman

after_initialize do
  add_to_class(:guardian, :can_send_private_message?) do |target , notify_moderators: false|
    is_user = target.is_a?(User)
    is_group = target.is_a?(Group)

    (is_group || is_user || target.id < 0 ) &&
    # User is authenticated
    authenticated? &&
    # Have to be a basic level at least -- and now: OR SENDING TO ADMIN
    (is_group || @user.has_trust_level?(SiteSetting.min_trust_to_send_messages) || notify_moderators || target.admin) &&
    # User disabled private message
    (is_staff? || is_group || target.user_option.allow_private_messages) &&
    # PMs are enabled
    (is_staff? || SiteSetting.enable_personal_messages || notify_moderators) &&
    # Can't send PMs to suspended users
    (is_staff? || is_group || !target.suspended?) &&
    # Check group messageable level
    (is_staff? || is_user || Group.messageable(@user).where(id: target.id).exists?) &&
    # Silenced users can only send PM to staff
    (!is_silenced? || target.staff?)
  end
end
