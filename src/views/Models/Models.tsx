import {
    Box,
    Button,
    Container,
    Stack,
    Text,
    Heading
} from '@chakra-ui/react'
import ModdelTable from "./table";

const Models = (): JSX.Element => {

    return (
        <Container minW={'100%'}>
            <Box bgColor={'transparent'} as="section" pt={{ base: '4', md: '10' }} pb={{ base: '12', md: '12' }}>
                <Stack spacing="4" direction={{ base: 'column', md: 'row' }} justify="space-between">
                    <Stack spacing="1">
                        <Heading size={{ base: 'xs', md: 'sm' }} fontWeight="medium">
                            Member overview
                        </Heading>
                        <Text color="fg.muted">All registered users in the overview</Text>
                    </Stack>
                    <Stack direction="row" spacing="3">
                        <Button variant="secondary">Invite</Button>
                        <Button>Create</Button>
                    </Stack>
                </Stack>

            </Box>
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






