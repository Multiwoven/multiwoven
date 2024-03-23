const actualMoment = jest.requireActual('moment');

const mockMoment = jest.fn(() => actualMoment('2024-01-01T00:00:00.000Z').utc());
mockMoment.default = mockMoment;
Object.assign(mockMoment, actualMoment);

module.exports = mockMoment;
