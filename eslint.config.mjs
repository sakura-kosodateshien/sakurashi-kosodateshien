import js from "@eslint/js";
export default [
  {
    ...js.configs.recommended,
    rules: {
      "no-use-before-define": ["error", { "functions": false, "classes": false, "variables": true }],
      "no-undef": "off",        // windowなどブラウザグローバルは除外
      "no-unused-vars": "off",  // 未使用変数は今回の主旨外
    },
    languageOptions: {
      ecmaVersion: 2022,
      globals: {
        window: "readonly", document: "readonly", navigator: "readonly",
        console: "readonly", alert: "readonly", setTimeout: "readonly",
        clearTimeout: "readonly", setInterval: "readonly", clearInterval: "readonly",
        fetch: "readonly", Promise: "readonly", JSON: "readonly",
        localStorage: "readonly", location: "readonly", history: "readonly",
        HTMLElement: "readonly", Event: "readonly", URL: "readonly",
        liff: "readonly", firebase: "readonly",
      }
    }
  }
];
