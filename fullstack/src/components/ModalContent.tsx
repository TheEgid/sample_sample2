import { Modal, Button } from "@mantine/core";
import { useDisclosure } from "@mantine/hooks";

const FancyboxExample = (): React.JSX.Element => {
    const [opened, { open, close }] = useDisclosure(false);

    return (
        <>
            <Modal opened={opened} onClose={close} title="Newwww">
                Modal content
            </Modal>

            <Button variant="default" onClick={open}>
                Open modal
            </Button>
        </>
    );
};

export default FancyboxExample;
