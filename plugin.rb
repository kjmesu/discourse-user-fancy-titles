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
      .select { |rule| rule.present? }
      .filter_map do |rule|
        property, value = rule.split(":", 2).map(&:strip)
        next unless property && value

        # Only allow allowlisted properties
        next unless ALLOWED_CSS_PROPERTIES.include?(property.downcase)

        # Additional validation for font-size (must have valid unit)
        if property.downcase == "font-size"
          next unless value =~ /^\d+(\.\d+)?(px|em|rem|%)$/i
        end

        "#{property}: #{value}"
      end
      .join("; ")
  end
end

require_relative "lib/discourse_user_fancy_titles/engine"

after_initialize do
  # Register custom field as staff-editable
  register_editable_user_custom_field(
    DiscourseUserFancyTitles::TITLE_CSS_FIELD,
    staff_only: true
  )

  # Register custom field to be preloaded
  register_user_custom_field_type(DiscourseUserFancyTitles::TITLE_CSS_FIELD, :text)

  # Preload custom field for serializers
  preload_custom_fields(User, [DiscourseUserFancyTitles::TITLE_CSS_FIELD]) if User.respond_to?(:preload_custom_fields)

  # Expose custom field to serializers
  # BasicUserSerializer is the base for all user serializations
  add_to_serializer(:basic_user, :title_css) do
    object.custom_fields[DiscourseUserFancyTitles::TITLE_CSS_FIELD]
  end

  # Include condition: only include if the field exists
  add_to_serializer(:basic_user, :include_title_css?) do
    object.custom_fields[DiscourseUserFancyTitles::TITLE_CSS_FIELD].present?
  end

  # Add custom route for updating title CSS
  Discourse::Application.routes.append do
    put "/admin/users/:user_id/title-css" => "admin/users#update_title_css"
  end

  # Add controller action
  require_dependency "admin/users_controller"

  add_to_class(Admin::UsersController, :update_title_css) do
    params.require(:user_id)
    user = User.find(params[:user_id])
    guardian.ensure_can_edit!(user)

    css_value = params[:title_css].to_s
    sanitized_css = DiscourseUserFancyTitles.sanitize_css(css_value)

    if sanitized_css.present?
      user.custom_fields[DiscourseUserFancyTitles::TITLE_CSS_FIELD] = sanitized_css
    else
      user.custom_fields.delete(DiscourseUserFancyTitles::TITLE_CSS_FIELD)
    end

    user.save_custom_fields(true)

    # Log staff action
    StaffActionLogger.new(current_user).log_custom(
      "update_user_title_css",
      {
        user_id: user.id,
        username: user.username,
        title_css: sanitized_css,
      }
    )

    render json: success_json.merge(
             title_css: sanitized_css,
             sanitized: sanitized_css != params[:title_css],
           )
  end
end
