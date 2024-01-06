# Blueberry theme

Blueberry theme is a premium theme, that brings your chakra-ui experience on another level. To bootstrap it in your application, please follow the next steps.

## Setup

1. Create or open a chakra-ui react app project

   ```bash
   yarn create react-app my-chakra-app --template @chakra-ui/typescript && cd my-chakra-app/
   ```

   ⚠️ Currently there are (issues with the create-react-app)[https://github.com/chakra-ui/chakra-ui/issues/5804] in combination with react 18. If you have problems starting the app, you can add `// @ts-nocheck` to the first line of the `index.ts` file. This might solve the problems until react 18 works in the CRA for chakra-ui with typescript.

2. Install the pro-theme

   ```bash
   yarn add @chakra-ui/pro-theme # or npm install @chakra-ui/pro-theme
   ```

   The theme extends the base-theme @chakra-ui/pro-theme. Please make sure, that you have installed it.

3. Create the folder "src/theme" and copy the extracted files from the zip-archive into that folder. Afterwards, your folder structure should look like this:

   ```bash
   ├── package.json
   ├── src
   │   ├── App.tsx
   │   └── theme
   │       ├── README.md
   │       ├── components
   │       ├── foundations
   │       ├── index.ts
   │       └── styles.ts
   ├── tsconfig.json
   ```

4. Import the theme from the folder and add it to your ChakraProvider in the App.tsx file

   ```jsx
   import { ChakraProvider, Button } from '@chakra-ui/react'
   import { theme } from './theme'

   export const App = () => (
     <ChakraProvider theme={theme}>
       <Button>Hello World</Button>
     </ChakraProvider>
   )
   ```

5. Font: The Blueberry Theme uses Google Font Inter by default, but can be configured otherwise. Since Inter is only a suggestion, we have not bundled the font with it. The easiest way to install the font is as follows:

   ```bash
   yarn add @fontsource-variable/spline-sans @fontsource-variable/open-sans
   # or npm install @fontsource-variable/spline-sans @fontsource-variable/open-sans
   ```

   Now import the font in a convenient place, for example in your app.

   ```jsx
   import { ChakraProvider, Button } from '@chakra-ui/react'
   import { theme } from './theme'
   import '@fontsource-variable/open-sans'
   import '@fontsource-variable/spline-sans'

   export const App = () => (
     <ChakraProvider theme={theme}>
       <Button>Hello World</Button>
     </ChakraProvider>
   )
   ```

## License

Please see more information about the license on the [Chakra UI Pro Website](https://pro.chakra-ui.com/license)
