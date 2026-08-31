document.documentElement.classList.add("js");

const languageButton = document.querySelector(".language-switch");
const languageLabel = document.querySelector("[data-language-label]");
const translatableElements = document.querySelectorAll("[data-vi][data-en]");
const localizedImages = document.querySelectorAll("[data-alt-vi][data-alt-en]");

function applyLanguage(language) {
  document.documentElement.lang = language;
  document.title = language === "vi"
    ? "VigClean | Hướng dẫn sử dụng"
    : "VigClean | User Guide";

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
const preferredLanguage = navigator.language.toLowerCase().startsWith("vi") ? "vi" : "en";
applyLanguage(savedLanguage === "vi" || savedLanguage === "en" ? savedLanguage : preferredLanguage);

const observer = new IntersectionObserver((entries) => {
  entries.forEach((entry) => {
    if (entry.isIntersecting) {
      entry.target.classList.add("is-visible");
      observer.unobserve(entry.target);
    }
  });
}, { threshold: 0.14 });

document.querySelectorAll(".reveal").forEach((element) => observer.observe(element));
