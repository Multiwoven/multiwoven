import { pathsToModuleNameMapper } from "ts-jest";

export default {
  preset: "ts-jest",
  testEnvironment: "jest-environment-jsdom",
  moduleNameMapper: {
    "\\.(css|less|scss|sass)$": "identity-obj-proxy",
    "\\.(gif|ttf|eot|svg|jpg|png)$": "identity-obj-proxy",
    ...pathsToModuleNameMapper({
      "@/*": ["src/*"],
    }),
  },
  modulePaths: ["<rootDir>"],
  transform: {
<<<<<<< HEAD
    "^.+\\.tsx?$": "ts-jest",
  },
=======
    '^.+\\.tsx?$': [
      'ts-jest',
      {
        isolatedModules: true,
        tsconfig: {
          module: 'commonjs',
          moduleResolution: 'node',
          allowImportingTsExtensions: false,
        },
      },
    ],
  },
  transformIgnorePatterns: [
    '/node_modules/(?!react-markdown|remark-gfm|jose|@opencode-ai/sdk|lodash-es)/',
  ],
  testPathIgnorePatterns: ['/node_modules/', '/e2e/'],
  collectCoverageFrom: [
    'src/**/*.{ts,tsx}',
    '!src/**/*.test.{ts,tsx}',
    '!src/**/*.spec.{ts,tsx}',
    '!src/**/*.d.ts',
    '!src/**/__tests__/**',
    '!src/**/__mocks__/**',
    // Exclude files that use import.meta.env (Vite-specific, not Jest compatible)
    '!src/app-signal.ts',
    '!src/App.tsx',
    '!src/enterprise/utils/generateLogoUrl.ts',
  ],
>>>>>>> 749f0e956 (fix(CE): solve snyk vulnerabilites for the UI (#1857))
};
