import { expect } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';

import getTitle from '@/utils/getPageTitle';

describe('getTitle', () => {
  it('should return the correct title for a known route', () => {
    expect(getTitle('/reports')).toBe('Reports | AI Squared');
    expect(getTitle('/data-apps')).toBe('Data Apps | AI Squared');
    expect(getTitle('/settings')).toBe('Settings | AI Squared');
    expect(getTitle('/activate/syncs')).toBe('Syncs | AI Squared');
    expect(getTitle('/setup/sources')).toBe('Sources | AI Squared');
    expect(getTitle('/define/models')).toBe('Models | AI Squared');
    expect(getTitle('/setup/destinations')).toBe('Destinations | AI Squared');
  });

  it('should return "AI Squared" for an unknown route', () => {
    expect(getTitle('/unknown')).toBe('AI Squared');
    expect(getTitle('/another/unknown/path')).toBe('AI Squared');
  });

  it('should return the correct title for a route with additional path segments', () => {
    expect(getTitle('/')).toBe('Reports | AI Squared');
    expect(getTitle('/reports/2023')).toBe('Reports | AI Squared');
    expect(getTitle('/data-apps/list')).toBe('Data Apps | AI Squared');
    expect(getTitle('/define/models/ai/28')).toBe('Models | AI Squared');
    expect(getTitle('/define/models/28')).toBe('Models | AI Squared');
  });
});
