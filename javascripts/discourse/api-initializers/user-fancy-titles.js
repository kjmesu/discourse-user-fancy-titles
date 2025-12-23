import { apiInitializer } from "discourse/lib/api";
import { htmlSafe } from "@ember/template";

export default apiInitializer("1.14.0", (api) => {
  api.registerValueTransformer("poster-name-user-title", ({ value }) => {
    if (!value) {
      return value;
    }

    const sanitized = sanitizeUserTitle(value);
    return htmlSafe(sanitized);
  });
});

function sanitizeUserTitle(html) {
  const allowedTags = ["span", "strong", "em", "i", "b"];
  const allowedStyles = ["color", "font-weight", "font-style"];

  const temp = document.createElement("div");
  temp.innerHTML = html;

  const elements = temp.querySelectorAll("*");
  elements.forEach((el) => {
    const tagName = el.tagName.toLowerCase();

    if (!allowedTags.includes(tagName)) {
      el.replaceWith(...el.childNodes);
      return;
    }

    Array.from(el.attributes).forEach((attr) => {
      if (attr.name === "style" && tagName === "span") {
        const sanitizedStyle = sanitizeStyle(attr.value, allowedStyles);
        el.setAttribute("style", sanitizedStyle);
      } else {
        el.removeAttribute(attr.name);
      }
    });
  });

  return temp.innerHTML;
}

function sanitizeStyle(styleString, allowedProps) {
  return styleString
    .split(";")
    .filter((rule) => {
      const prop = rule.split(":")[0]?.trim();
      return allowedProps.includes(prop);
    })
    .join(";");
}
