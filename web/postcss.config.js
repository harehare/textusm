const purgecss = require("@fullhuman/postcss-purgecss");

const development = {
    plugins: [],
};

const production = {
    plugins: [
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
