import React from "react";
import Head from "next/head";
import { Container, Spinner } from "react-bootstrap";

const Home: React.FC = () => {

    return (
        <>
            <Head>
                <title>Приложение</title>
                <link rel="icon" href="/favicon.ico" />
            </Head>
            <Container>
                <h1>Приложение</h1>
                <Spinner animation="border" />
            </Container>
        </>
    );
};

export default Home;
