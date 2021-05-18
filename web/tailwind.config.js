module.exports = {
    purge: {
        content: ["./src/index.html", "./src/**/*.elm", "./src/**/*.ts"],
    },
    theme: {
        extend: {
            padding: {
                xs: "4px",
                sm: "8px",
                md: "16px",
                lg: "24px",
                xl: "48px",
            },
            margin: {
                xs: "4px",
                sm: "8px",
                md: "16px",
                lg: "24px",
                xl: "48px",
            },
        },
    },
    variants: {},
    plugins: [],
};
