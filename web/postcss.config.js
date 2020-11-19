const purgecss = require("@fullhuman/postcss-purgecss");
const postcssPresetEnv = require("postcss-preset-env");
const tailwindcss = require("tailwindcss")("tailwind.config.js");

const development = {
    plugins: [
        tailwindcss,
        postcssPresetEnv({
            stage: 1,
        }),
    ],
};

const production = {
    plugins: [
        tailwindcss,
        postcssPresetEnv({
            stage: 1,
        }),
        purgecss({
            content: ["./src/**/*.elm", "index.ts"],
            whitelist: ["html", "body"],
        }),
    ],
};

if (process.env.NODE_ENV === "production") {
    module.exports = production;
} else {
    module.exports = development;
}
