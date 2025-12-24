import { apiInitializer } from "discourse/lib/api";

export default apiInitializer("1.14.0", (api) => {
  // Apply custom CSS to user titles via decorateCooked
  api.decorateCooked(
    ($elem, helper) => {
      if (!helper) {
        return;
      }

      const post = helper.getModel?.();
      if (!post?.user_title_css) {
        return;
      }

      // Find the user title span and apply custom CSS
      const titleSpan = $elem.find(".names .user-title");
      if (titleSpan.length > 0) {
        titleSpan.attr("style", post.user_title_css);
      }
    },
    { id: "user-fancy-titles" }
  );
});
