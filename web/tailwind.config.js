module.exports = {
    purge: {
        content: ["./src/index.html", "./src/**/*.elm", "./src/**/*.ts"],
    },
    theme: {
        extend: {},
    },
    variants: {},
    plugins: [require("@tailwindcss/typography")],
};
