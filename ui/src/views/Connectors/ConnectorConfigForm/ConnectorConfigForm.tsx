import { useQuery } from '@tanstack/react-query';
import { SteppedFormContext } from '@/components/SteppedForm/SteppedForm';
import { getConnectorDefinition } from '@/services/connectors';
import { useContext, useState, useEffect } from 'react';
import { Box, Button, useToast } from '@chakra-ui/react';
import { FaFacebook } from 'react-icons/fa';
import FormFooter from '@/components/FormFooter';
import Loader from '@/components/Loader';
import { processFormData } from '@/views/Connectors/helpers';
import ContentContainer from '@/components/ContentContainer';
import { generateUiSchema } from '@/utils/generateUiSchema';
import JSONSchemaForm from '@/components/JSONSchemaForm';
import { useStore } from '@/stores';
import { RJSFSchema } from '@rjsf/utils';

// Define type for the form data
type ConnectorFormData = {
  access_token?: string;
  [key: string]: any;
};

const ConnectorConfigForm = ({ connectorType }: { connectorType: string }): JSX.Element | null => {
  const { state, stepInfo, handleMoveForward } = useContext(SteppedFormContext);
  const { forms } = state;
  const selectedConnector = forms.find(
    ({ stepKey }) => stepKey === (connectorType === 'source' ? 'datasource' : connectorType),
  );
  const connector = selectedConnector?.data?.[
    connectorType === 'source' ? 'datasource' : connectorType
  ] as string;
  const activeWorkspaceId = useStore((state) => state.workspaceId);
  const [isConnectingFacebook, setIsConnectingFacebook] = useState(false);
  const [accessToken, setAccessToken] = useState<string | null>(null);
  const [formValues, setFormValues] = useState<ConnectorFormData>({});
  const toast = useToast();

  if (!connector) return null;
  const { data, isLoading } = useQuery({
    queryKey: ['connector_definition', connector, activeWorkspaceId],
    queryFn: () => getConnectorDefinition(connectorType, connector),
    enabled: !!connector && activeWorkspaceId > 0,
    refetchOnMount: false,
    refetchOnWindowFocus: false,
  });
  
  // Check if this is a Facebook connector
  const isFacebookConnector = connector === 'FacebookCustomAudience' && connectorType === "destination";

  // We'll use a different approach for Facebook authentication
  // Instead of relying on the SDK's login flow, we'll use a popup window approach
  // This is more reliable in server environments
  
  // No need to track SDK loading attempts with the popup approach
  
  // State to store the Facebook App ID
  const [facebookAppId, setFacebookAppId] = useState<string | null>(null);
  
  // Fetch environment variables from the server
  useEffect(() => {
    if (isFacebookConnector) {
      fetch('/env')
        .then(response => response.json())
        .then(data => {
          console.log('Environment variables from server:', data);
          if (data.VITE_FACEBOOK_APP_ID) {
            setFacebookAppId(data.VITE_FACEBOOK_APP_ID);
          }
        })
        .catch(error => {
          console.error('Error fetching environment variables:', error);
        });
    }
  }, [isFacebookConnector]);

  // Function to exchange short-lived token for long-lived token
  const handleTokenExchange = (accessToken: string) => {

    // Print first 5 and last 5 characters of the token
    if (accessToken && accessToken.length > 10) {
      const first5 = accessToken.substring(0, 5);
      const last5 = accessToken.substring(accessToken.length - 5);
      console.log(`Exchanging short-lived token for long-lived token...: ${first5}...${last5}`);
    } else {
      console.log('*** Token is too short or undefined');
    }
    
    exchangeForLongLivedToken(accessToken)
      .then(longLivedToken => {
        // Print first 5 and last 5 characters of the long-lived token
        if (longLivedToken && longLivedToken.length > 10) {
          const first5 = longLivedToken.substring(0, 5);
          const last5 = longLivedToken.substring(longLivedToken.length - 5);
          console.log(`Received long-lived token: ${first5}...${last5}`);
        } else {
          console.log('*** Long-lived token is too short or undefined');
        }
        
        // Set the access token in state
        setAccessToken(longLivedToken);
        
        // Directly update the form values to ensure the token is set in the form field
        setFormValues((prev: ConnectorFormData) => {
          const updatedForm = {
            ...prev,
            access_token: longLivedToken
          };
          // Print first 5 and last 5 characters of the token being set in form
          if (longLivedToken && longLivedToken.length > 10) {
            const first5 = longLivedToken.substring(0, 5);
            const last5 = longLivedToken.substring(longLivedToken.length - 5);
            console.log(`Set form token: ${first5}...${last5}`);
          } else {
            console.log('*** Form token is too short or undefined');
          }
          return updatedForm;
        });
        
        toast({
          title: "Success",
          description: "Connected to Facebook. The access token has been added to the form.",
          status: "success",
          duration: 5000,
          isClosable: true,
        });
        setIsConnectingFacebook(false);
      })
      .catch(error => {
        console.error('Error exchanging token:', error);
        toast({
          title: "Error",
          description: "Failed to get long-lived token",
          status: "error",
          duration: 5000,
          isClosable: true,
        });
        setIsConnectingFacebook(false);
      });
  };

  // Function to open Facebook OAuth dialog in a popup window
  const openFacebookAuthWindow = () => {
    // Use the Facebook App ID fetched from the server
    if (!facebookAppId) {
      console.error('Facebook App ID not found');
      toast({
        title: "Configuration Error",
        description: "Facebook App ID is missing. Please check your environment configuration.",
        status: "error",
        duration: 5000,
        isClosable: true,
      });
      setIsConnectingFacebook(false);
      return;
    }
    
    // Define the redirect URI - this should be configured in your Facebook App settings
    // Use the current origin (including ngrok URLs if applicable)
    const redirectUri = window.location.origin + '/auth/facebook/callback';
    
    console.log('Using redirect URI:', redirectUri);
    console.log('Make sure this domain is added to your Facebook App settings');
    
    // Define the permissions we need
    const scope = 'public_profile,email';
    
    // Create the Facebook OAuth URL
    const authUrl = `https://www.facebook.com/v18.0/dialog/oauth?client_id=${facebookAppId}&redirect_uri=${encodeURIComponent(redirectUri)}&scope=${scope}&response_type=token`;
    
    // Open the popup window
    const width = 600;
    const height = 600;
    const left = window.screen.width / 2 - width / 2;
    const top = window.screen.height / 2 - height / 2;
    
    try {
      // Attempt to open in a popup
      const popup = window.open(
        authUrl,
        'facebook-auth-window',
        `width=${width},height=${height},left=${left},top=${top}`
      );
      
      // Check if popup was blocked
      if (!popup || popup.closed || typeof popup.closed === 'undefined') {
        console.log('Popup was blocked');
        throw new Error('Popup blocked');
      }
      
      // If we got here, popup was opened successfully
      console.log('Popup opened successfully');
      
      // Set up a listener for the OAuth redirect
      window.addEventListener('message', function(event) {
        if (event.origin !== window.location.origin) return;
        
        if (event.data && event.data.type === 'FACEBOOK_AUTH_SUCCESS' && event.data.accessToken) {
          console.log('Received access token from popup');
          handleTokenExchange(event.data.accessToken);
        }
      });
      
      // No need to poll the popup - we'll use the message event instead
      
    } catch (error) {
      console.error('Error opening popup:', error);
      
      // Show a toast informing about popup blocking
      toast({
        title: "Popup Blocked",
        description: "Popups are blocked. Please enable popups for this website to connect with Facebook.",
        status: "warning",
        duration: 5000,
        isClosable: true,
      });
      
      setIsConnectingFacebook(false);
    }
    
    // The popup handling is now done inside the try-catch block above
  };


  // We're now directly updating the form values in handleTokenExchange
  // This useEffect is no longer needed as we're setting the form values directly
  // when we receive the long-lived token

  // Function to exchange short-lived token for long-lived token
  const exchangeForLongLivedToken = async (shortLivedToken: string) => {
    try {
      // Call our server endpoint instead of directly calling Facebook API
      const response = await fetch('/api/facebook/exchange-token', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ shortLivedToken }),
      });

      const data = await response.json();

      if (data.error) {
        throw new Error(data.error.message || JSON.stringify(data.error) || 'Failed to exchange token');
      }

      if (!data.access_token) {
        throw new Error('No access token returned from server');
      }

      return data.access_token;
    } catch (error) {
      console.error('Error exchanging token:', error);
      throw error;
    }
  };

  // We no longer need the initiateLoginProcess function as we're using the popup approach

  const handleFacebookConnect = () => {
    setIsConnectingFacebook(true);
    console.log('Facebook connect clicked, using popup approach');

    if (typeof window === 'undefined') {
      toast({
        title: "Error",
        description: "Browser environment not available",
        status: "error",
        duration: 5000,
        isClosable: true,
      });
      setIsConnectingFacebook(false);
      return;
    }

    // Try to open the Facebook authentication popup directly
    openFacebookAuthWindow();
  };
  


  if (isLoading) return <Loader />;

  const handleFormSubmit = async (submittedFormData: FormData) => {
    try {
      // If we have an access token, add it to the form data
      if (accessToken) {
        submittedFormData.append('access_token', accessToken);
      }
      
      const processedFormData = processFormData(submittedFormData);
      handleMoveForward(stepInfo?.formKey as string, processedFormData);
    } catch (error) {
      toast({
        title: 'Submission Error',
        description: 'Failed to process form data',
        status: 'error',
        duration: 5000,
        isClosable: true,
      });
    }
  };

  // Update form value change handler
  const handleChange = (formData: ConnectorFormData) => {
    setFormValues(formData);
  };

  const connectorSchema = data?.data?.connector_spec?.connection_specification;
  if (!connectorSchema) return null;

  // We already defined isFacebookConnector above
  const schemaToUse = isFacebookConnector ? {
    ...connectorSchema,
    properties: {
      ...connectorSchema.properties,
      access_token: {
        type: "string",
        title: "Access Token"
      } as RJSFSchema
    },
    required: [
      ...(connectorSchema.required || []),
      'access_token',
    ],
  } : connectorSchema;

  const schema = generateUiSchema(schemaToUse);


  return (
    <Box display='flex' justifyContent='center' marginBottom='80px'>
      <ContentContainer>
        <Box backgroundColor='gray.200' padding='24px' borderRadius='8px'>
          <JSONSchemaForm
            schema={schemaToUse}
            uiSchema={schema}
            onSubmit={(submittedFormData: FormData) => handleFormSubmit(submittedFormData)}
            formData={formValues}
            onChange={handleChange}
          >
            <>
              {!accessToken && isFacebookConnector && (
                <>
                  <Button 
                    leftIcon={<FaFacebook />}
                    colorScheme="facebook"
                    isLoading={isConnectingFacebook}
                    loadingText="Connecting..."
                    onClick={handleFacebookConnect}
                    mb={4}
                    mt={4}
                    size="lg"
                  >
                    Facebook
                  </Button>

                </>
              )}
              <FormFooter
                ctaName='Continue'
                ctaType='submit'
                isContinueCtaRequired
                isDocumentsSectionRequired
                isBackRequired
              />
            </>
          </JSONSchemaForm>
        </Box>
      </ContentContainer>
    </Box>
  );
};

// Add TypeScript interface for the Facebook SDK and environment variables
declare global {
  interface Window {
    FB: any;
    fbAsyncInit: () => void;
    __ENV__?: {
      FACEBOOK_APP_ID?: string;
      [key: string]: any;
    };
  }
}

export default ConnectorConfigForm;