import React from "react";
import "@/globals.scss";
import type { AppProps } from "next/app";

export default function App({ Component, pageProps }: AppProps): React.JSX.Element {
    return (
        <>
            <Component {...pageProps} />
            ;
        </>
    );
}
