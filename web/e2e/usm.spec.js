/// <reference types="cypress" />

context('usm', () => {
    beforeEach(() => {
        cy.viewport(1920, 1880);
        cy.visit('/');
    });
    it('change background color of user story map', () => {
        cy.get('.menu-button').first().click().get('.new-item').first().click();
        cy.get('#usm')
            .find('text:nth-child(2)')
            .should('contain', 'USER ACTIVITY');
        cy.get('#usm')
            .find('.card')
            .first()
            .click()
            .get('.context-menu')
            .should('be.visible');
        cy.get('#usm')
            .find('.background-color-menu')
            .click()
            .get('#usm')
            .find('.lime')
            .first()
            .click()
            .get('#usm')
            .find('.ts-card')
            .first()
            .get('#usm')
            .click()
            .find('.ts-card')
            .first()
            .should('have.attr', 'fill')
            .and('equal', '#00ff00');
    });
});
