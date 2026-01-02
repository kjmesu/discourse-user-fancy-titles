export default {
  name: "title-position",

  initialize(container) {
    const siteSettings = container.lookup("service:site-settings");
    const titlePosition = siteSettings.title_position;
    document.documentElement.classList.add(`title-position-${titlePosition}`);
  },
};
