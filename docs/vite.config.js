import { defineConfig } from "vite"
import { SearchPlugin } from "vitepress-plugin-search"

const searchOptions = {
  previewLength: 62,
  buttonLabel: "Search",
  placeholder: "Search docs"
};

export default defineConfig({
  plugins: [SearchPlugin(searchOptions)]
})
