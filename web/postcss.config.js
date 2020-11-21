const purgecss = require("@fullhuman/postcss-purgecss");
const tailwindcss = require("tailwindcss");

const development = {
    plugins: [tailwindcss],
};

const production = {
    plugins: [
        tailwindcss,
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
