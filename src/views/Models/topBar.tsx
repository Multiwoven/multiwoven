import {
    Box,
    Button,
    Stack,
    Text,
    Heading
} from '@chakra-ui/react'

const TopBar = (): JSX.Element => {

    return (
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
    )
}
export default TopBar;






