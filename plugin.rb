# frozen_string_literal: true

# name: discourse-user-fancy-titles
# about: Allows staff to add custom CSS styling to user titles
# version: 2.0.0
# authors: Discourse
# url: https://github.com/discourse/discourse-user-fancy-titles

module ::DiscourseUserFancyTitles
  PLUGIN_NAME = "discourse-user-fancy-titles"
  TITLE_CSS_FIELD = "title_css"

  # Allowed CSS properties (security allowlist)
  ALLOWED_CSS_PROPERTIES = %w[
    color
    font-weight
    font-style
    text-decoration
    text-transform
    font-size
  ].freeze

  # Dangerous patterns to block
  BLOCKED_PATTERNS = [
    /url\s*\(/i,
    /@import/i,
    /javascript:/i,
    /expression\s*\(/i,
    /behavior\s*:/i,
    /-moz-binding/i,
  ].freeze

  def self.sanitize_css(css_string)
    return "" if css_string.blank?

    Rails.logger.warn("=== CSS Sanitization Debug ===")
    Rails.logger.warn("Input: #{css_string.inspect}")

    # Block dangerous patterns
    BLOCKED_PATTERNS.each do |pattern|
      if css_string =~ pattern
        Rails.logger.warn("Blocked by pattern: #{pattern}")
        return ""
      end
    end

    # Parse and filter CSS declarations
    parts_array = css_string.split(";").map(&:strip).reject(&:blank?)
    Rails.logger.warn("After split by semicolon: #{parts_array.inspect}")

    result = parts_array.filter_map do |rule|
      parts = rule.split(":", 2)
      Rails.logger.warn("Rule: #{rule.inspect}, Parts: #{parts.inspect}")

      next if parts.length != 2

      property = parts[0].strip
      value = parts[1].strip
      Rails.logger.warn("Property: #{property.inspect}, Value: #{value.inspect}")

      next if property.blank? || value.blank?

      # Only allow allowlisted properties
      unless ALLOWED_CSS_PROPERTIES.include?(property.downcase)
        Rails.logger.warn("Property #{property} not in allowlist: #{ALLOWED_CSS_PROPERTIES.inspect}")
        next
      end

      # Additional validation for font-size (must have valid unit)
      if property.downcase == "font-size"
        next unless value =~ /^\d+(\.\d+)?(px|em|rem|%)$/i
      end

      output = "#{property}: #{value}"
      Rails.logger.warn("Accepted: #{output.inspect}")
      output
    end.join("; ")

    Rails.logger.warn("Final result: #{result.inspect}")
    result.blank? ? "" : result
  end
end

require_relative "lib/discourse_user_fancy_titles/engine"

after_initialize do
  # Register custom field
  register_editable_user_custom_field(
    DiscourseUserFancyTitles::TITLE_CSS_FIELD,
    staff_only: true
  )

  register_user_custom_field_type(DiscourseUserFancyTitles::TITLE_CSS_FIELD, :text)
  allow_staff_user_custom_field(DiscourseUserFancyTitles::TITLE_CSS_FIELD)
  allow_public_user_custom_field(DiscourseUserFancyTitles::TITLE_CSS_FIELD)

  # Expose custom field to serializers
  add_to_serializer(:basic_user, :title_css) do
    # Handle both User objects and Hash representations
    if object.is_a?(Hash)
      object.dig(:custom_fields, DiscourseUserFancyTitles::TITLE_CSS_FIELD) ||
        object.dig("custom_fields", DiscourseUserFancyTitles::TITLE_CSS_FIELD)
    else
      object.custom_fields&.dig(DiscourseUserFancyTitles::TITLE_CSS_FIELD)
    end
  end

  add_to_serializer(:basic_user, :include_title_css?) do
    value = if object.is_a?(Hash)
              object.dig(:custom_fields, DiscourseUserFancyTitles::TITLE_CSS_FIELD) ||
                object.dig("custom_fields", DiscourseUserFancyTitles::TITLE_CSS_FIELD)
            else
              object.custom_fields&.dig(DiscourseUserFancyTitles::TITLE_CSS_FIELD)
            end
    value.present?
  end

  # Add custom route
  Discourse::Application.routes.append do
    put "/admin/users/:user_id/title-css" => "admin/users#update_title_css"
  end

  # Add controller action
  require_dependency "admin/users_controller"

  add_to_class(Admin::UsersController, :update_title_css) do
    params.require(:user_id)
    user = User.find(params[:user_id])
    guardian.ensure_can_edit!(user)

    css_value = params[:title_css].to_s.strip
    original_value = css_value.dup

    sanitized_css = DiscourseUserFancyTitles.sanitize_css(css_value)

    if sanitized_css.present?
      user.custom_fields[DiscourseUserFancyTitles::TITLE_CSS_FIELD] = sanitized_css
    else
      user.custom_fields.delete(DiscourseUserFancyTitles::TITLE_CSS_FIELD)
    end

    user.save_custom_fields(true)

    # Reload to get the saved value
    user.reload

    render json: success_json.merge(
             title_css: sanitized_css.presence || "",
             sanitized: sanitized_css != original_value,
           )
  end
end
