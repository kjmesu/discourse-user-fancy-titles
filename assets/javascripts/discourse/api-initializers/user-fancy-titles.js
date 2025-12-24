import { apiInitializer } from "discourse/lib/api";
import { htmlSafe } from "@ember/template";

export default apiInitializer("1.14.0", (api) => {
  // Apply custom CSS to user titles
  api.registerValueTransformer("poster-name-user-title", ({ value, context }) => {
    console.log("Value Transformer called:", { value, context, user: context?.user });

    if (!value) {
      return value;
    }

    // Get the user object from context
    const user = context?.user;
    console.log("User object:", user);
    console.log("User title_css:", user?.title_css);

    if (!user?.title_css) {
      console.log("No title_css found, returning plain value");
      // No custom CSS, return plain title
      return value;
    }

    // Apply inline CSS styling
    const styledValue = `<span style="${user.title_css}">${value}</span>`;
    console.log("Applying CSS, returning:", styledValue);
    return htmlSafe(styledValue);
  });
});
