/**
 * Manual mock for React
 * Re-exports the actual React module to ensure all React features
 * (including React.Fragment) are available in tests.
 * This is needed because some test environments may not properly
 * resolve React imports, causing React.Fragment to be undefined.
 */
/* eslint-env jest, node */
const React = jest.requireActual('react');

// Export React with both CommonJS and ES module compatibility
module.exports = React;
module.exports.default = React;
