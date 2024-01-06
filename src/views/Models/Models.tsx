import {
    Avatar,
    Badge,
    HStack,
    Icon,
    IconButton,
    Table,
    Tbody,
    Td,
    Th,
    Thead,
    Tr,
    Box,
    Button,
    Container,
    Stack,
    Text,
    Heading
} from '@chakra-ui/react'
import { FiEdit2, FiTrash2 } from 'react-icons/fi'
import { IoArrowDown } from 'react-icons/io5'
const members = [
    {
        id: '1',
        name: 'Christian Nwamba',
        handle: '@christian',
        email: 'christian@chakra-ui.com',
        avatarUrl: 'https://bit.ly/code-beast',
        status: 'active',
        role: 'Senior Developer Advocate',
        rating: 4,
    },
    {
        id: '2',
        name: 'Kent C. Dodds',
        handle: '@kent',
        email: 'kent@chakra-ui.com',
        avatarUrl: 'https://bit.ly/kent-c-dodds',
        status: 'active',
        role: 'Director of DX',
        rating: 4,
    },
    {
        id: '3',
        name: 'Prosper Otemuyiwa',
        handle: '@prosper',
        email: 'prosper@chakra-ui.com',
        avatarUrl: 'https://bit.ly/prosper-baba',
        status: 'active',
        role: 'Director of Evangelism',
        rating: 4,
    },
    {
        id: '4',
        name: 'Ryan Florence',
        handle: '@ryan',
        email: 'ryan@chakra-ui.com',
        avatarUrl: 'https://bit.ly/ryan-florence',
        status: 'active',
        role: 'Co-Founder',
        rating: 4,
    },
    {
        id: '5',
        name: 'Segun Adebayo',
        handle: '@segun',
        email: 'segun@chakra-ui.com',
        avatarUrl: 'https://bit.ly/sage-adebayo',
        status: 'active',
        role: 'Frontend UI Engineer',
        rating: 4,
    },
]
const Models = () => {

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
                        <Table>
                            <Thead>
                                <Tr>
                                    <Th>
                                        <HStack spacing="3">
                                            {/* <Checkbox /> */}
                                            <HStack spacing="1">
                                                <Text>Name</Text>
                                                <Icon as={IoArrowDown} color="fg.muted" boxSize="4" />
                                            </HStack>
                                        </HStack>
                                    </Th>
                                    <Th>Status</Th>
                                    <Th>Email</Th>
                                    <Th>Role</Th>

                                    <Th></Th>
                                </Tr>
                            </Thead>
                            <Tbody>
                                {members.map((member) => (
                                    <Tr key={member.id}>
                                        <Td>
                                            <HStack spacing="3">
                                                {/* <Checkbox /> */}
                                                <Avatar name={member.name} src={member.avatarUrl} boxSize="10" />
                                                <Box>
                                                    <Text fontWeight="medium">{member.name}</Text>
                                                    <Text color="fg.muted">{member.handle}</Text>
                                                </Box>
                                            </HStack>
                                        </Td>
                                        <Td>
                                            <Badge size="sm" colorScheme={member.status === 'active' ? 'purple' : 'red'}>
                                                {member.status}
                                            </Badge>
                                        </Td>
                                        <Td>
                                            <Text color="fg.muted">{member.email}</Text>
                                        </Td>
                                        <Td>
                                            <Text color="fg.muted">{member.role}</Text>
                                        </Td>

                                        <Td>
                                            <HStack spacing="1">
                                                <IconButton icon={<FiTrash2 />} variant="tertiary" aria-label="Delete member" />
                                                <IconButton icon={<FiEdit2 />} variant="tertiary" aria-label="Edit member" />
                                            </HStack>
                                        </Td>
                                    </Tr>
                                ))}
                            </Tbody>
                        </Table>
                    </Box>
                  
                </Stack>
            </Box>
           
        </Container>
    )
}
export default Models;






