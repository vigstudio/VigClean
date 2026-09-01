document.documentElement.classList.add("js");

const languageButton = document.querySelector(".language-switch");
const languageLabel = document.querySelector("[data-language-label]");
const translatableElements = document.querySelectorAll("[data-vi][data-en]");
const localizedImages = document.querySelectorAll("[data-alt-vi][data-alt-en]");

function applyLanguage(language) {
  document.documentElement.lang = language;
  document.title = language === "vi"
    ? "Hướng dẫn sử dụng VigClean"
    : "VigClean User Guide";

  document.querySelector('meta[name="description"]').content = language === "vi"
    ? "Hướng dẫn cài đặt và sử dụng VigClean trên macOS, có ảnh minh họa bằng tiếng Việt và tiếng Anh."
    : "A visual guide to installing and using VigClean on macOS, available in English and Vietnamese.";

  translatableElements.forEach((element) => {
    element.textContent = element.dataset[language];
  });

  localizedImages.forEach((image) => {
    image.alt = image.dataset[`alt${language[0].toUpperCase()}${language.slice(1)}`];
  });

  languageLabel.textContent = language === "vi" ? "English" : "Tiếng Việt";
  localStorage.setItem("vigclean-language", language);
}

languageButton.addEventListener("click", () => {
  applyLanguage(document.documentElement.lang === "vi" ? "en" : "vi");
});

const savedLanguage = localStorage.getItem("vigclean-language");
const preferredLanguage = "vi";
applyLanguage(savedLanguage === "vi" || savedLanguage === "en" ? savedLanguage : preferredLanguage);

const contentsLinks = [...document.querySelectorAll(".contents a")];
const documentedSections = contentsLinks
  .map((link) => document.querySelector(link.getAttribute("href")))
  .filter(Boolean);

const sectionObserver = new IntersectionObserver((entries) => {
  entries.forEach((entry) => {
    if (!entry.isIntersecting) return;
    contentsLinks.forEach((link) => {
      const isCurrent = link.getAttribute("href") === `#${entry.target.id}`;
      link.classList.toggle("active", isCurrent);
      if (isCurrent) link.setAttribute("aria-current", "location");
      else link.removeAttribute("aria-current");
    });
  });
}, { rootMargin: "-18% 0px -72% 0px", threshold: 0 });

documentedSections.forEach((section) => sectionObserver.observe(section));
