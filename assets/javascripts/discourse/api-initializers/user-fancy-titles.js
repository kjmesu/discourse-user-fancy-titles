import { apiInitializer } from "discourse/lib/api";
import { slugify } from "discourse/lib/utilities";

const MAX_CACHE_SIZE = 1000;

export default apiInitializer("1.14.0", (api) => {
  const titlePosition = api.container.lookup("service:site-settings")
    .title_position;
  document.documentElement.classList.add(`title-position-${titlePosition}`);

  let styleElement = null;
  const titleStylesCache = new Map();

  function updateTitleStyles(posts) {
    if (!posts || posts.length === 0) {
      return;
    }

    let hasChanges = false;

    posts.forEach((post) => {
      const titleCss = post.user_title_css;
      const userTitle = post.user_title;

      if (titleCss && userTitle) {
        const className = slugify(userTitle);

        if (!titleStylesCache.has(className)) {
          if (titleStylesCache.size >= MAX_CACHE_SIZE) {
            titleStylesCache.clear();
            hasChanges = true;
          }
          titleStylesCache.set(className, titleCss);
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

    const cssRules = Array.from(titleStylesCache.entries()).map(
      ([className, css]) => `.user-title--${className} { ${css} }`
    );

    styleElement.textContent = cssRules.join("\n");
  }

  api.onAppEvent("page:topic-loaded", (topic) => {
    if (topic?.postStream?.posts) {
      updateTitleStyles(topic.postStream.posts);
    }
  });
});
