import { pathsToModuleNameMapper } from "ts-jest";

export default {
  preset: "ts-jest",
  testEnvironment: "jest-environment-jsdom",
  moduleNameMapper: {
    "\\.(css|less|scss|sass)$": "identity-obj-proxy",
    "\\.(gif|ttf|eot|svg|jpg|png)$": "<rootDir>/__mocks__/fileMock.js",
    ...pathsToModuleNameMapper({
      "@/*": ["src/*"],
    }),
  },
  modulePaths: ["<rootDir>"],
  transform: {
    "^.+\\.tsx?$": "ts-jest",
  },
};
