// cypress/integration/login.spec.js

describe('Login Component', () => {
    beforeEach(() => {
      cy.visit('/login');
    });
  
    it('should render the login form', () => {
      cy.get('form').should('exist');
      cy.get('#email').should('exist');
      cy.get('#password').should('exist');
      cy.get('button[type="submit"]').should('exist');
    });
  
  });
  