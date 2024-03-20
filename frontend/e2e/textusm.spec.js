/// <reference types="cypress" />

context('TextUSM', () => {
  beforeEach(() => {
    cy.viewport(1920, 1880);
    cy.visit('/');
  });

  it('Save the diagram to local and load it', () => {
    // eslint-disable-next-line cypress/no-unnecessary-waiting
    cy.get('#editor')
      .click()
      .focused()
      .wait(500)
      .type('{ctrl}a')
      .wait(500)
      .type('test1\n    test2\ntest3')
      .get('[data-test-id="editor"]')
      .should('have.attr', 'value', 'test1\n    test2\n    test3');
    cy.get('[data-test-id="header-title"]').click().get('[data-test-id="header-input-title"]').type('test');
    // eslint-disable-next-line cypress/no-unnecessary-waiting
    cy.get('[data-test-id="save-menu"]').should('exist').click().wait(500);
    cy.get('[data-test-id="disabled-save-menu"]').should('exist');
    // eslint-disable-next-line cypress/no-unnecessary-waiting
    cy.get('[data-test-id="list-menu"]').click().wait(500);
    cy.get('[data-test-id="diagram-list"]')
      .find('[data-test-id="diagram-list-item"]')
      .should('be.visible')
      .first()
      .click();
    cy.get('[data-test-id="editor"]').should('have.attr', 'value', 'test1\n    test2\n    test3');
  });

  it('Change background color of user story map', () => {
    cy.get('[data-test-id="new-menu"]').first().click().get('[data-test-id="new-usm"]').first().click();
    cy.get('[data-test-id="diagram"]').find('text').next().should('contain', 'USER ACTIVITY');
    cy.get('[data-test-id="diagram"]')
      .find('[data-test-id="card-6"]')
      .first()
      .click()
      .get('[data-test-id="context-menu"]')
      .should('be.visible');
    cy.get('[data-test-id="diagram"]')
      .find('[data-test-id="background-color-context-menu"]')
      .click()
      .get('[data-test-id="diagram"]')
      .find('.lime')
      .first()
      .click()
      .get('[data-test-id="diagram"]')
      .find('.ts-card')
      .first()
      .get('[data-test-id="diagram"]')
      .click()
      .find('.ts-card')
      .first()
      .should('have.attr', 'fill', '#00ff00');
  });

  it('Change foreground color of user story map', () => {
    cy.get('[data-test-id="new-menu"]').first().click().get('[data-test-id="new-usm"]').first().click();
    cy.get('[data-test-id="diagram"]').find('text').next().should('contain', 'USER ACTIVITY');
    cy.get('[data-test-id="diagram"]')
      .find('[data-test-id="card-6"]')
      .first()
      .click()
      .get('[data-test-id="context-menu"]')
      .should('be.visible');
    cy.get('[data-test-id="diagram"]')
      .find('[data-test-id="foreground-color-context-menu"]')
      .click()
      .get('[data-test-id="diagram"]')
      .find('.lime')
      .first()
      .click()
      .get('[data-test-id="diagram"]')
      .find('.ts-card')
      .first()
      .get('[data-test-id="diagram"]')
      .click()
      .find('[data-test-id="card-6"] text')
      .first()
      .should('have.attr', 'color', '#00ff00');
  });

  it('Change background color settings', () => {
    cy.get("a[data-test-id='header-settings']").click();
    cy.get("div[data-test-id='background-color']").click();
    cy.get("div[data-test-id='background-color'] > div:nth-of-type(2) > div:first-child").click();
    cy.get("div[data-test-id='header-back']").click();
    cy.get('#usm').should('have.css', 'background-color').and('eq', 'rgb(254, 254, 254)');
  });
});
