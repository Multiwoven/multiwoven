import React from "react";
import ReactDOM from "react-dom/client";
import App from "./App";
import { BrowserRouter } from "react-router-dom";
import { ChakraProvider } from "@chakra-ui/react";
import { theme} from './theme'
import "./assets/styles/common_styles.scss"
// import { theme } from "./chakra.config";
//import { ChakraProvider } from "@chakra-ui/provider";
// const proTheme = extendTheme(theme)
// const extenstion = {
//   colors: {
//     ...proTheme.colors, brand: proTheme.colors.teal, mw_orange: "#E63D2D",
//     secondary: "#731447",
//     nav_bg: "#2d3748",
//     nav_text: "#a0aec0",
//     primary: "#EB524C",
//     hyperlink: "#5383EC",
//     black: "#171923",
//     dark_gray: "#4b5563",
//     border: "#E2E8F0"
//   },
// }
// const myTheme = extendTheme(extenstion, proTheme)
ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <BrowserRouter>
      <ChakraProvider theme={theme}>
        <App />
      </ChakraProvider>
    </BrowserRouter>
  </React.StrictMode>
);
