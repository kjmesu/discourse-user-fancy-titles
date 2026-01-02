export default {
  name: "title-position",

  initialize(container) {
    const siteSettings = container.lookup("service:site-settings");
    if (!siteSettings.discourse_user_fancy_titles_enabled) {
      return;
    }
    const titlePosition = siteSettings.title_position || "default";
    document.documentElement.classList.add(`title-position-${titlePosition}`);
  },
};
