import titleCase from './TitleCase';

describe('TitleCase util test', () => {
  it('Return Hello Work when input is hello world', () => {
    expect(titleCase('hello world')).toBe('Hello World');
  });

  it('Return Typescript when input is typescript', () => {
    expect(titleCase('typescript')).toBe('Typescript');
  });

  it('Return empty string when input is empty', () => {
    expect(titleCase('')).toBe('');
  });
});
