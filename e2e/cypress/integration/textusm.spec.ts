/// <reference types="cypress"/>

context("TextUSM", () => {
  beforeEach(() => {
    cy.visit("http://localhost:3000");
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
    cy.route("/bmc")
      .get(".monaco-editor")
      .click()
      .focused()
      .type("{ctrl}a")
      .type("test1\n    test2")
      .get("body")
      .find("rect")
      .its("length")
      .should("eq", 16);
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
    cy.get("div.list-button")
      .click()
      .get("div.diagram-list")
      .find("div.diagram-item")
      .should("to.have.length.gt", 1)
      .get("div.diagram-item")
      .first()
      .click()
      .get(".view-line")
      .first()
      .should("contain", "test1")
      .get(".view-line")
      .eq(1)
      .should("contain", "test2");
  });
});
