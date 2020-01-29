/// <reference types="cypress"/>

const HOST_NAME = "https://app.textusm.com";

context("TextUSM", () => {
  beforeEach(() => {
    cy.visit(HOST_NAME);
  });

  it("user story map should work", () => {
    cy.get(".monaco-editor")
      .click()
      .focused()
      .type("{ctrl}a")
      .type("test1\n    test2")
      .get("body")
      .find("rect")
      .its("length")
      .should("eq", 4);
  });

  it("business model canvas should work", () => {
    cy.visit(`${HOST_NAME}/bmc`)
      .get(".monaco-editor")
      .click()
      .focused()
      .type("{ctrl}a")
      .type("test1\n    test2")
      .get("body")
      .find("rect")
      .its("length")
      .should("eq", 18);
  });

  it("edit title should work", () => {
    cy.get("div.title")
      .click()
      .get("#title")
      .type("title")
      .blur()
      .get("div.title")
      .should("have.text", "title");
  });

  it("save should work", () => {
    cy.get("div.save-button").click();
  });

  it("diagram list should work", () => {
    cy.get(".monaco-editor")
      .click()
      .focused()
      .type("{ctrl}a")
      .type("test1\n    test2")
      .get("div.save-button")
      .click()
      .get("div.list-button")
      .click()
      .get("div.diagram-list")
      .find("div.diagram-item")
      .should("to.have.length.gte", 1);
  });
});
