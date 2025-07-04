import {
  Box,
  Text,
  Modal,
  ModalBody,
  ModalCloseButton,
  ModalContent,
  ModalFooter,
  ModalHeader,
  ModalOverlay,
  Flex,
  Button,
  FormControl,
  FormLabel,
  Input,
  FormErrorMessage,
  useToast,
} from '@chakra-ui/react';
import { useState } from 'react';
// Navigation no longer needed as we handle closing via props
import { addMemberToWorkspace } from '../../../services/workspace';

interface AddMemberProps {
  onCancel: () => void;
  workspaceId: string;
  onSuccess?: () => void; // Optional callback to refresh data after successful addition
}

const AddMember = ({ onCancel, workspaceId, onSuccess }: AddMemberProps) => {
  // Modal is always open in this component
  const isOpen = true;
  const [email, setEmail] = useState('');
  const [error, setError] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const toast = useToast();

  const validateEmail = (email: string) => {
    const regex = /\S+@\S+\.\S+/;
    return regex.test(email);
  };

  const handleSubmit = async () => {
    // Reset error
    setError('');
    
    // Add debug toast
    toast({
      title: 'Processing request',
      description: `Trying to add member with email: ${email} to workspace: ${workspaceId}`,
      status: 'info',
      duration: 3000,
      isClosable: true,
    });
    
    console.log('Starting add member process', { email, workspaceId });
    
    // Validate email
    if (!email) {
      setError('Email is required');
      return;
    }
    
    if (!validateEmail(email)) {
      setError('Please enter a valid email address');
      return;
    }
    
    setIsLoading(true);
    
    try {
      console.log('Calling addMemberToWorkspace with:', { workspaceId, email });
      const response = await addMemberToWorkspace(workspaceId as string, email);
      console.log('Response from addMemberToWorkspace:', response);
      
      if (response.success) {
        toast({
          title: 'Member added successfully',
          status: 'success',
          duration: 3000,
          isClosable: true,
        });
        
        // Call success callback if provided (to refresh data)
        if (onSuccess) {
          onSuccess();
        }
        
        // Close the modal
        onCancel();
      } else {
        console.error('Error from API:', response.message);
        setError(response.message || 'Failed to add member');
      }
    } catch (err: any) {
      console.error('Exception caught in handleSubmit:', err);
      setError(err.message || 'User not found or could not be added to workspace');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <Modal isOpen={isOpen} onClose={onCancel} isCentered motionPreset="slideInBottom">
      <ModalOverlay bg="blackAlpha.400" backdropFilter="blur(8px)" />
      <ModalContent>
      <ModalHeader paddingX='24px' paddingY='20px'>
        <Text fontWeight={700} size='xl' color='black.500' letterSpacing='-0.2px'>
          Add Member to Workspace
        </Text>
        <ModalCloseButton color='gray.600' onClick={onCancel} />
      </ModalHeader>

      <ModalBody marginX='24px' marginY='8px'>
        <FormControl isInvalid={!!error}>
          <FormLabel>Email address</FormLabel>
          <Input 
            type='email' 
            value={email} 
            onChange={(e) => setEmail(e.target.value)} 
            placeholder='Enter user email'
          />
          {error && <FormErrorMessage>{error}</FormErrorMessage>}
        </FormControl>
      </ModalBody>

      <ModalFooter paddingX='24px' paddingY='20px'>
        <Box w='full'>
          <Flex flexDir='row' justifyContent='end'>
            <Button
              variant='ghost'
              mr={3}
              onClick={onCancel}
              size='md'
              color='black.500'
              minWidth={0}
              width='auto'
            >
              Cancel
            </Button>
            <Button
              variant='solid'
              color='white'
              rounded='lg'
              onClick={handleSubmit}
              minWidth={0}
              width='auto'
              isLoading={isLoading}
              loadingText="Adding..."
            >
              Add Member
            </Button>
          </Flex>
        </Box>
      </ModalFooter>
    </ModalContent>
    </Modal>
  );
};

export default AddMember;
