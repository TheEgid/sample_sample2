import React from "react";
import { generateColors } from "@mantine/colors-generator";
import { createTheme, MantineProvider, type MantineColorsTuple } from "@mantine/core";
import type { AppProps } from "next/app";

import "../styles/styles.scss";

const themePalette: MantineColorsTuple = [
    "#f5f5f5",
    "#e7e7e7",
    "#cdcdcd",
    "#b2b2b2",
    "#9a9a9a",
    "#8b8b8b",
    "#848484",
    "#717171",
    "#656565",
    "#575757",
];

const theme = createTheme({
    primaryColor: "mainColor",
    colors: { mainColor: themePalette, blue: generateColors("#575757") },
    headings: {
        fontFamily: "Open Sans Condensed", // Шрифт для всех заголовков
    },
});

export default function App({ Component, pageProps }: AppProps): React.JSX.Element {
    return (
        <MantineProvider theme={theme}>
            <Component {...pageProps} />
        </MantineProvider>
    );
}
