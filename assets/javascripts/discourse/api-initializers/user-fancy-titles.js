import { apiInitializer } from "discourse/lib/api";
import { htmlSafe } from "@ember/template";

export default apiInitializer("1.14.0", (api) => {
  // Apply custom CSS to user titles
  api.registerValueTransformer("poster-name-user-title", ({ value, context }) => {
    console.log("Value Transformer called:", { value, context });

    if (!value) {
      return value;
    }

    // Get CSS from either post.user_title_css (post streams) or user.title_css (other contexts)
    const titleCss = context?.post?.user_title_css || context?.user?.title_css;

    console.log("Post:", context?.post);
    console.log("Post user_title_css:", context?.post?.user_title_css);
    console.log("User:", context?.user);
    console.log("User title_css:", context?.user?.title_css);
    console.log("Final titleCss:", titleCss);

    if (!titleCss) {
      console.log("No title_css found, returning plain value");
      return value;
    }

    // Apply inline CSS styling
    const styledValue = `<span style="${titleCss}">${value}</span>`;
    console.log("Applying CSS, returning:", styledValue);
    return htmlSafe(styledValue);
  });
});
