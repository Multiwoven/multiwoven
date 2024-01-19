import {
	Box,
	Button,
	Flex,
	Image,
	Modal,
	ModalBody,
	ModalCloseButton,
	ModalContent,
	ModalFooter,
	ModalHeader,
	ModalOverlay,
	Text,
	useDisclosure,
} from "@chakra-ui/react";
import { useNavigate } from "react-router-dom";

function ExitModal() {
	const { isOpen, onOpen, onClose } = useDisclosure();
    const navigate = useNavigate();

	return (
		<>
			{/* <Button onClick={onOpen}>Open Modal</Button> */}
			<Button variant='outline' onClick={onOpen} w={24}  colorScheme='gray'>
				Exit
			</Button>

			<Modal blockScrollOnMount={false} isOpen={isOpen} onClose={onClose}>
				<ModalOverlay />
				<ModalContent>
					{/* <ModalHeader>Modal Title</ModalHeader> */}
					<ModalCloseButton color='gray.300' />
					<ModalBody mx='auto' pt={10}>
						<Flex direction='column'>
							<Image src='' h={48}/>
							<Text fontWeight='bold' pt={8} fontSize={20} textAlign='center'>
								Are you sure you want to exit?
							</Text>
							<Text fontWeight='light' fontSize={14} textAlign='center'>
								Your progress will be lost
							</Text>
						</Flex>
					</ModalBody>

					<ModalFooter>
						<Box w='full'>
							<Flex flexDir='row' justifyContent='center'>
								<Button
									bgColor='gray.300'
                                    variant='ghost'
									color='black'
									mr={3}
									onClick={onClose}
									size='md'
									pr={8}
									pl={8}
									rounded='lg'
								>
									Cancel
								</Button>
								<Button
									// variant='ghost'
									_hover={{ bgColor: "orange.500" }}
									bgColor='orange.400'
									rounded='lg'
									pr={10}
									pl={10}
                                    onClick={() => navigate('/models')}
								>
									Exit
								</Button>
							</Flex>
						</Box>
					</ModalFooter>
				</ModalContent>
			</Modal>
		</>
	);
}

export default ExitModal;
