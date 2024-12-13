import { expect } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';

import getTitle from '@/utils/getPageTitle';

describe('getTitle', () => {
  it('should return the correct title for a known route', () => {
    expect(getTitle('/')).toBe('Dashboard | Multiwoven');
    expect(getTitle('/settings')).toBe('Settings | Multiwoven');
    expect(getTitle('/activate/syncs')).toBe('Syncs | Multiwoven');
    expect(getTitle('/setup/sources')).toBe('Sources | Multiwoven');
    expect(getTitle('/define/models')).toBe('Models | Multiwoven');
    expect(getTitle('/setup/destinations')).toBe('Destinations | Multiwoven');
  });

  it('should return "Multiwoven" for an unknown route', () => {
    expect(getTitle('/unknown')).toBe('Multiwoven');
    expect(getTitle('/another/unknown/path')).toBe('Multiwoven');
  });

  it('should return the correct title for a route with additional path segments', () => {
    expect(getTitle('/')).toBe('Dashboard | Multiwoven');
    expect(getTitle('/define/models/ai/28')).toBe('Models | Multiwoven');
    expect(getTitle('/define/models/28')).toBe('Models | Multiwoven');
  });
});
