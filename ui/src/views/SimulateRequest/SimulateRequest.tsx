import React, { useEffect, useState } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { 
  Box, 
  Heading, 
  Text, 
  Button, 
  Spinner, 
  Alert, 
  AlertIcon, 
  AlertTitle, 
  AlertDescription, 
  Container 
} from '@chakra-ui/react';
import Cookies from 'js-cookie';
import { CustomToastStatus } from '@/components/Toast';
import useCustomToast from '@/hooks/useCustomToast';
import { simulateRequest, SimulateRequestPayload } from '@/services/authentication';
import { useStore } from '@/stores';

const SimulateRequest: React.FC = () => {
  const location = useLocation();
  const navigate = useNavigate();
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  const showToast = useCustomToast();

  useEffect(() => {
    const verifyToken = async () => {
      try {
        // Get token from URL query parameter
        const params = new URLSearchParams(location.search);
        const token = params.get('token');

        if (!token) {
          setError('No token provided.');
          setIsLoading(false);
          return;
        }

        // Make API call to verify token using the service function
        // Include current auth token to allow backend to invalidate previous session if exists
        const currentAuthToken = Cookies.get('authToken') || '';
        const payload: SimulateRequestPayload = { 
          token: token,
          authToken: currentAuthToken 
        };
        const response = await simulateRequest(payload);
        
        if (response.data && response.data.attributes && response.data.attributes.token) {
          // Store token in cookies (matching SignIn behavior)
          const jwtToken = response.data.attributes.token;
          Cookies.set('authToken', jwtToken, { secure: true, sameSite: 'Lax' });
          
          // Clear any existing workspace state to prevent 400 Bad Request errors
          const { clearState } = useStore.getState();
          clearState(); // This resets workspaceId to 0 and clears localStorage
          
          // Navigate to dashboard or appropriate page
          showToast({
            duration: 3000,
            isClosable: true,
            position: 'bottom-right',
            title: 'Successfully Authenticated',
            status: CustomToastStatus.Success,
          });
          
          // Redirect to home with replace=true to prevent going back to the auth page
          navigate('/', { replace: true });
        } else {
          setError('Invalid or expired token.');
        }
      } catch (err) {
        console.error('Error verifying token:', err);
        showToast({
          duration: 3000,
          isClosable: true,
          position: 'bottom-right',
          title: 'There was an error connecting to the server. Please try again later.',
          status: CustomToastStatus.Error,
        });
        setError('Failed to verify token. Please try again.');
      } finally {
        setIsLoading(false);
      }
    };

    verifyToken();
  }, [location.search, navigate]);

  return (
    <Container maxW="container.md" centerContent py={10}>
      <Box textAlign="center" padding={8}>
        <Heading mb={6}>Authenticating...</Heading>
        
        {isLoading && (
          <Box mt={6} textAlign="center">
            <Spinner size="xl" mb={4} />
            <Text fontSize="lg">Please wait while we authenticate your request...</Text>
          </Box>
        )}
        
        {error && (
          <Alert status="error" variant="solid" flexDirection="column" alignItems="center" mt={6} p={6} borderRadius="md">
            <AlertIcon boxSize="40px" mr={0} />
            <AlertTitle mt={4} mb={1} fontSize="lg">Authentication Error</AlertTitle>
            <AlertDescription maxWidth="sm">{error}</AlertDescription>
            <Button colorScheme="red" mt={4} onClick={() => navigate('/login')}>
              Return to Login
            </Button>
          </Alert>
        )}
      </Box>
    </Container>
  );
};

export default SimulateRequest;
