const purgecss = require("@fullhuman/postcss-purgecss");

const development = {
    plugins: ["postcss-preset-env"],
};

const production = {
    plugins: [
        "postcss-preset-env",
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
