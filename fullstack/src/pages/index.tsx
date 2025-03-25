import React from "react";
import Head from "next/head";

const Home: React.FC = () => {

    return (
        <>
            <Head>
                <title>Приложение</title>
                <link rel="icon" href="/favicon.ico" />
            </Head>
            <div>
                <h1 className="hello">Приложение</h1>
            </div>
        </>
    );
};

export default Home;
