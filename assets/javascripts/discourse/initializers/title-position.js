export default {
  name: "title-position",

  initialize(container) {
    const siteSettings = container.lookup("service:site-settings");
    // eslint-disable-next-line no-console
    console.log("Title position initializer running");
    // eslint-disable-next-line no-console
    console.log("Plugin enabled:", siteSettings.discourse_user_fancy_titles_enabled);
    // eslint-disable-next-line no-console
    console.log("Title position setting:", siteSettings.title_position);
    if (!siteSettings.discourse_user_fancy_titles_enabled) {
      return;
    }
    const titlePosition = siteSettings.title_position || "default";
    // eslint-disable-next-line no-console
    console.log("Adding class:", `title-position-${titlePosition}`);
    document.documentElement.classList.add(`title-position-${titlePosition}`);
  },
};
