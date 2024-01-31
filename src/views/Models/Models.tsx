import {
    Box,
    Container,
    Stack,
} from '@chakra-ui/react'
import ModdelTable from "./table";
import TopBar from './topBar';

const Models = (): JSX.Element => {

    return (
        <Container minW={'100%'}>
            <TopBar />
            <Box
                bg="bg.surface"
                boxShadow={{ base: 'none', md: 'sm' }}
                borderRadius={{ base: 'none', md: 'lg' }}
            >
                <Stack spacing="5">
                    <Box overflowX="auto">
                        <ModdelTable />
                    </Box>
                </Stack>
            </Box>
           
        </Container>
    )
}
export default Models;






