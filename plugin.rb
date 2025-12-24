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

    # Block dangerous patterns
    BLOCKED_PATTERNS.each do |pattern|
      return "" if css_string =~ pattern
    end

    # Parse and filter CSS declarations
    css_string
      .split(";")
      .map(&:strip)
      .reject(&:blank?)
      .filter_map do |rule|
        parts = rule.split(":", 2)
        next if parts.length != 2

        property = parts[0].strip
        value = parts[1].strip
        next if property.blank? || value.blank?

        # Only allow allowlisted properties
        next unless ALLOWED_CSS_PROPERTIES.include?(property.downcase)

        # Additional validation for font-size (must have valid unit)
        if property.downcase == "font-size"
          next unless value =~ /^\d+(\.\d+)?(px|em|rem|%)$/i
        end

        "#{property}: #{value}"
      end
      .join("; ")
      .presence || ""
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

  # Add title_css to PostSerializer (for post streams)
  add_to_serializer(:post, :user_title_css) do
    user_custom_fields_object[object.user_id]&.[](DiscourseUserFancyTitles::TITLE_CSS_FIELD)
  end

  add_to_serializer(:post, :include_user_title_css?) do
    user_title_css.present?
  end

  # Add title_css to BasicUserSerializer (for user cards, profiles, etc.)
  add_to_serializer(:basic_user, :title_css) do
    if object.is_a?(Hash)
      object.dig(:custom_fields, DiscourseUserFancyTitles::TITLE_CSS_FIELD) ||
        object.dig("custom_fields", DiscourseUserFancyTitles::TITLE_CSS_FIELD)
    else
      object.custom_fields&.[](DiscourseUserFancyTitles::TITLE_CSS_FIELD)
    end
  end

  add_to_serializer(:basic_user, :include_title_css?) do
    title_css.present?
  end

  # Also add to admin serializer
  add_to_serializer(:admin_detailed_user, :title_css) do
    object.custom_fields&.[](DiscourseUserFancyTitles::TITLE_CSS_FIELD)
  end

  add_to_serializer(:admin_detailed_user, :include_title_css?) do
    object.custom_fields&.[](DiscourseUserFancyTitles::TITLE_CSS_FIELD).present?
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
    sanitized_css = DiscourseUserFancyTitles.sanitize_css(css_value)

    if sanitized_css.present?
      user.custom_fields[DiscourseUserFancyTitles::TITLE_CSS_FIELD] = sanitized_css
    else
      user.custom_fields.delete(DiscourseUserFancyTitles::TITLE_CSS_FIELD)
    end

    user.save_custom_fields(true)
    user.reload

    actual_saved = user.custom_fields[DiscourseUserFancyTitles::TITLE_CSS_FIELD]

    render json: success_json.merge(
             title_css: actual_saved.presence || "",
             sanitized: sanitized_css != css_value,
           )
  end
end
