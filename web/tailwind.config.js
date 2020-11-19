module.exports = {
    purge: {
        content: ["./src/**/*.elm", "./src/**/*.ts"],
    },
    theme: {
        extend: {
            colors: {
                cyan: "#9cdbff",
            },
            margin: {
                default: "8px",
            },
            padding: {
                base: "8px",
                lg: "16px",
            },
        },
    },
    variants: {},
    plugins: [],
};
