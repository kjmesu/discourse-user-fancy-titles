import { apiInitializer } from "discourse/lib/api";
import { htmlSafe } from "@ember/template";

export default apiInitializer("1.14.0", (api) => {
  // Apply custom CSS to user titles
  api.registerValueTransformer("poster-name-user-title", ({ value, context }) => {
    // Don't process if no value
    if (!value) {
      return value;
    }

    // Get CSS from either post.user_title_css (post streams) or user.title_css (other contexts)
    const titleCss = context?.post?.user_title_css || context?.user?.title_css;

    // No CSS to apply
    if (!titleCss) {
      return value;
    }

    // Convert value to string (it might be an htmlSafe object)
    const valueStr = typeof value === 'string' ? value : value.toString();

    // Don't re-wrap if already wrapped
    if (valueStr.includes('<span style=')) {
      return value;
    }

    // Apply inline CSS styling
    return htmlSafe(`<span style="${titleCss}">${valueStr}</span>`);
  });
});
