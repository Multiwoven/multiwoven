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
          // Check for both possible environment variable names
          if (data.FACEBOOK_APP_ID) {
            setFacebookAppId(data.FACEBOOK_APP_ID);
          } else if (data.VITE_FACEBOOK_APP_ID) {
            setFacebookAppId(data.VITE_FACEBOOK_APP_ID);
          } else {
            console.error('Facebook App ID not found in environment variables');
          }
        })
        .catch(error => {
          console.error('Error fetching environment variables:', error);
        });
    }
  }, [isFacebookConnector]);

  // Function to exchange short-lived token for long-lived token
  const handleTokenExchange = (accessToken: string) => {
    exchangeForLongLivedToken(accessToken)
      .then(longLivedToken => {
        // Set the access token in state
        setAccessToken(longLivedToken);
        
        // Directly update the form values to ensure the token is set in the form field
        setFormValues((prev: ConnectorFormData) => ({
          ...prev,
          access_token: longLivedToken
        }));
        
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
    
    
    // Define the permissions we need for Facebook Custom Audience
    // ads_management - Allows you to manage ads
    // ads_read - Allows you to read ad account data
    // business_management - Allows access to business accounts
    const scope = 'public_profile,email,ads_management,ads_read,business_management';
    
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
      
      
      // Set up a listener for the OAuth redirect
      window.addEventListener('message', function(event) {
        if (event.origin !== window.location.origin) return;
        
        if (event.data && event.data.type === 'FACEBOOK_AUTH_SUCCESS' && event.data.accessToken) {
          
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


  // Update form data when access token changes
  useEffect(() => {
    if (accessToken) {
      setFormValues((prev: ConnectorFormData) => ({
        ...prev,
        access_token: accessToken
      }));
    }
  }, [accessToken]);

  // Function to exchange short-lived token for long-lived token
  const exchangeForLongLivedToken = async (shortLivedToken: string) => {
    try {
      // Exchange the token using the server endpoint
      const response = await fetch('/facebook-token-exchange', {
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
      throw error;
    }
  };

  // We no longer need the initiateLoginProcess function as we're using the popup approach

  const handleFacebookConnect = () => {
    setIsConnectingFacebook(true);
    

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
      if (accessToken && submittedFormData instanceof FormData) {
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
      // Only include unique values in the required array
      ...new Set([...(connectorSchema.required || []), 'access_token'])
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