const tailwindcss = require("tailwindcss");

const development = {
    plugins: [tailwindcss],
};

const production = {
    plugins: [tailwindcss],
};

if (process.env.NODE_ENV === "production") {
    module.exports = production;
} else {
    module.exports = development;
}
