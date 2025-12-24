import { apiInitializer } from "discourse/lib/api";

export default apiInitializer("1.14.0", (api) => {
  let styleElement = null;

  // Generate CSS class selector from title text (matches Discourse's native pattern)
  function titleToClass(title) {
    return title.replace(/\s+/g, "-").toLowerCase();
  }

  // Update the dynamic stylesheet with CSS rules for user titles
  function updateTitleStyles(posts) {
    if (!posts || posts.length === 0) {
      return;
    }

    const cssRules = [];

    posts.forEach((post) => {
      const titleCss = post.user_title_css;
      const userTitle = post.user_title;

      if (titleCss && userTitle) {
        const className = titleToClass(userTitle);
        cssRules.push(`.user-title--${className} { ${titleCss} }`);
      }
    });

    if (cssRules.length === 0) {
      return;
    }

    // Create or update the style element
    if (!styleElement) {
      styleElement = document.createElement("style");
      styleElement.id = "discourse-user-fancy-titles-styles";
      document.head.appendChild(styleElement);
    }

    styleElement.textContent = cssRules.join("\n");
  }

  // Hook into topic view to update styles when posts are loaded
  api.onPageChange(() => {
    const topicController = api.container.lookup("controller:topic");
    if (topicController?.model?.postStream?.posts) {
      updateTitleStyles(topicController.model.postStream.posts);
    }
  });
});
