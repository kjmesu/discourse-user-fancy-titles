import { apiInitializer } from "discourse/lib/api";
import { slugify } from "discourse/lib/utilities";

const MAX_CACHE_SIZE = 1000;

export default apiInitializer("1.14.0", (api) => {
  let styleElement = null;
  const titleStylesCache = new Map();

  function updateTitleStyles(posts) {
    if (!posts?.length) {
      return;
    }

    let hasChanges = false;

    posts.forEach((post) => {
      if (post.user_title_css && post.user_title) {
        const className = slugify(post.user_title);

        if (!titleStylesCache.has(className)) {
          if (titleStylesCache.size >= MAX_CACHE_SIZE) {
            titleStylesCache.clear();
            hasChanges = true;
          }
          titleStylesCache.set(className, post.user_title_css);
          hasChanges = true;
        }
      }
    });

    if (!hasChanges && styleElement) {
      return;
    }

    if (titleStylesCache.size === 0) {
      return;
    }

    if (!styleElement) {
      styleElement = document.createElement("style");
      styleElement.id = "discourse-user-fancy-titles-styles";
      document.head.appendChild(styleElement);
    }

    styleElement.textContent = Array.from(titleStylesCache.entries())
      .map(([className, css]) => `.user-title--${className} { ${css} }`)
      .join("\n");
  }

  api.onAppEvent("page:topic-loaded", (topic) => {
    if (topic?.postStream?.posts) {
      updateTitleStyles(topic.postStream.posts);
    }
  });
});
