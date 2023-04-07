# frozen_string_literal: true

# name: allow-pms-to-staff
# about: Allow pms to staff even if PMs are otherwise not allowed
# version: 0.1
# authors: pfaffman

after_initialize do
  add_to_class(:guardian, :old_can_send_private_message?) do |target, notify_moderators: false|
    # copied from guardian.rb
    target_is_user = target.is_a?(User)
    target_is_group = target.is_a?(Group)
    from_system = @user.is_system_user?

    # Must be a valid target
    return false if !(target_is_group || target_is_user)

    # Users can send messages to certain groups with the `everyone` messageable_level
    # even if they are not in personal_message_enabled_groups
    group_is_messageable = target_is_group && Group.messageable(@user).where(id: target.id).exists?

    # User is authenticated and can send PMs, this can be covered by trust levels as well via AUTO_GROUPS
    (can_send_private_messages?(notify_moderators: notify_moderators) || group_is_messageable) &&
      # User disabled private message
      (is_staff? || target_is_group || target.user_option.allow_private_messages) &&
      # Can't send PMs to suspended users
      (is_staff? || target_is_group || !target.suspended?) &&
      # Check group messageable level
      (from_system || target_is_user || group_is_messageable || notify_moderators) &&
      # Silenced users can only send PM to staff
      (!is_silenced? || target.staff?)
  end

  add_to_class(:guardian, :can_send_private_message?) do |target, notify_moderators: false|
    target_is_user = target.is_a?(User)
    target_is_group = target.is_a?(Group)
    from_system = @user.is_system_user?

    # Must be a valid target
    return false if !(target_is_group || target_is_user)

    # Users can send messages to certain groups with the `everyone` messageable_level
    # even if they are not in personal_message_enabled_groups
    group_is_messageable = target_is_group && Group.messageable(@user).where(id: target.id).exists?

    receiving_group = target_is_group ? false :
      (target.groups.pluck(:name) & SiteSetting.allow_pm_allowed_pm_groups.split("|")).length > 0
      
    # User is authenticated and can send PMs, this can be covered by trust levels as well via AUTO_GROUPS
    (can_send_private_messages?(notify_moderators: notify_moderators) || group_is_messageable) &&
      # User disabled private message
      (
        is_staff? || target_is_group ||
          (target.user_option.allow_private_messages && receiving_group)
      ) &&
      # Can't send PMs to suspended users
      (is_staff? || target_is_group || !target.suspended?) &&
      # Check group messageable level
      (from_system || target_is_user || group_is_messageable || notify_moderators) &&
      # Silenced users can only send PM to staff
      (!is_silenced? || target.staff?)
  end
end
