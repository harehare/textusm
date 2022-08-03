/// <reference types="cypress" />

context('TextUSM', () => {
    beforeEach(() => {
        cy.viewport(1920, 1880);
        cy.visit('/');
    });

    it('Save the diagram and load it', () => {
        // eslint-disable-next-line cypress/no-unnecessary-waiting
        cy.get('#editor')
            .click()
            .focused()
            .wait(500)
            .type('{ctrl}a')
            .wait(500)
            .type('test1\n    test2\ntest3')
            .get('[data-test="editor"]')
            .should('have.attr', 'value', 'test1\n    test2\n    test3');
        cy.get('[data-test="header-title"]')
            .click()
            .get('[data-test="header-input-title"]')
            .type('test');
        // eslint-disable-next-line cypress/no-unnecessary-waiting
        cy.get('[data-test="save-menu"]').should('exist').click().wait(500);
        cy.get('[data-test="disabled-save-menu"]').should('exist');
        // eslint-disable-next-line cypress/no-unnecessary-waiting
        cy.get('[data-test="list-menu"]').click().wait(500);
        cy.get('[data-test="diagram-list"]')
            .find('[data-test="diagram-list-item"]')
            .should('be.visible')
            .first()
            .click();
        cy.get('[data-test="editor"]').should(
            'have.attr',
            'value',
            'test1\n    test2\n    test3'
        );
    });

    it('Change background color of user story map', () => {
        cy.get('[data-test="new-menu"]')
            .first()
            .click()
            .get('[data-test="new-usm"]')
            .first()
            .click();
        cy.get('[data-test="diagram"]')
            .find('text')
            .next()
            .should('contain', 'USER ACTIVITY');
        cy.get('[data-test="diagram"]')
            .find('[data-test="card-6"]')
            .first()
            .click()
            .get('[data-test="context-menu"]')
            .should('be.visible');
        cy.get('[data-test="diagram"]')
            .find('[data-test="background-color-context-menu"]')
            .click()
            .get('[data-test="diagram"]')
            .find('.lime')
            .first()
            .click()
            .get('[data-test="diagram"]')
            .find('.ts-card')
            .first()
            .get('[data-test="diagram"]')
            .click()
            .find('.ts-card')
            .first()
            .should('have.attr', 'fill')
            .and('equal', '#00ff00');
    });

    it('Change foreground color of user story map', () => {
        cy.get('[data-test="new-menu"]')
            .first()
            .click()
            .get('[data-test="new-usm"]')
            .first()
            .click();
        cy.get('[data-test="diagram"]')
            .find('text')
            .next()
            .should('contain', 'USER ACTIVITY');
        cy.get('[data-test="diagram"]')
            .find('[data-test="card-6"]')
            .first()
            .click()
            .get('[data-test="context-menu"]')
            .should('be.visible');
        cy.get('[data-test="diagram"]')
            .find('[data-test="foreground-color-context-menu"]')
            .click()
            .get('[data-test="diagram"]')
            .find('.lime')
            .first()
            .click()
            .get('[data-test="diagram"]')
            .find('.ts-card')
            .first()
            .get('[data-test="diagram"]')
            .click()
            .find('[data-test="card-6"] text')
            .first()
            .should('have.attr', 'color')
            .and('equal', '#00ff00');
    });
});
