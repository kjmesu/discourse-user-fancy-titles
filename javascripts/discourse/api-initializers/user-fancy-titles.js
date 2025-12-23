import { apiInitializer } from "discourse/lib/api";
import { htmlSafe } from "@ember/template";

export default apiInitializer("1.14.0", (api) => {
  // Apply custom CSS to user titles
  api.registerValueTransformer("poster-name-user-title", ({ value, context }) => {
    if (!value) {
      return value;
    }

    // Get the user object from context
    const user = context?.user;
    if (!user?.title_css) {
      // No custom CSS, return plain title
      return value;
    }

    // Apply inline CSS styling
    // The value is already the title text, we wrap it with styling
    return htmlSafe(`<span style="${user.title_css}">${value}</span>`);
  });
});
