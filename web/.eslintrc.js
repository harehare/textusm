module.exports = {
    env: {
        browser: true,
        es2021: true,
    },

    extends: ["eslint:recommended", "plugin:@typescript-eslint/recommended"],
    rules: {
        "import/prefer-default-export": "off",
        "@typescript-eslint/ban-ts-comment": "off",
        "no-bitwise": "off",
        "new-cap": "off",
        "no-underscore-dangle": "off",
    },
    parser: "@typescript-eslint/parser",
    parserOptions: {
        project: "./tsconfig.json",
        sourceType: "module",
        ecmaVersion: 12,
    },
    plugins: ["@typescript-eslint"],
};
