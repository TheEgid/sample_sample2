import React from "react";
import { Button, Container, Loader } from "@mantine/core";
import { useUnit } from "effector-react";
import Head from "next/head";
import { ToastContainer } from "react-toastify";
import ExpandableDiv from "@/components/ExpandableDiv";
import FancyboxExample from "@/components/ModalContent";
import { $addBlogItemStatus } from "@/model/some/state";

const Home: React.FC = () => {
    const { loading, error } = useUnit($addBlogItemStatus);

    return (
        <>
            <ToastContainer />
            <Head>
                <title>Приложение</title>
            </Head>
            <Container>
                <Button variant="success">
                    {/* {onClick={}> /* checkPetitionFieldFx()}> */}
                    Click Me!
                </Button>
                <div className="hello">
                    <ExpandableDiv />
                    <FancyboxExample />
                    <p>{error?.message ?? "без ошибок"}</p>
                    <div style={{ height: "40px" }}>{loading ? <Loader /> : "загружено"}</div>
                </div>
            </Container>
        </>
    );
};

export default Home;
