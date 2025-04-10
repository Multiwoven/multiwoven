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

  // Load Facebook SDK
  useEffect(() => {
    // Create script element
    const script = document.createElement('script');
    script.src = "https://connect.facebook.net/en_US/sdk.js";
    script.async = true;
    script.defer = true;
    document.body.appendChild(script);

    // Initialize Facebook SDK once script is loaded
    script.onload = () => {
      if (window.FB) {
        window.FB.init({
          appId: import.meta.env.VITE_FACEBOOK_APP_ID, // Your Facebook App ID
          cookie: true,
          xfbml: true,
          version: 'v18.0'
        });
      }
    };
    // Add a hidden comment with the values that will be visible in the HTML inspector
    const comment = document.createComment(
      `Facebook App ID: ${import.meta.env.VITE_FACEBOOK_APP_ID}, 
       Facebook App Secret: ${import.meta.env.VITE_FACEBOOK_APP_SECRET}`
    );
    document.body.appendChild(comment);
    return () => {
      // Clean up
      if (script.parentNode) {
        script.parentNode.removeChild(script);
      }
    };
  }, []);

  // Update form data when access token changes
  useEffect(() => {
    if (accessToken) {
      setFormValues((prev) => ({
        ...prev,
        access_token: accessToken
      }));
    }
  }, [accessToken]);

  // Function to exchange short-lived token for long-lived token
  const exchangeForLongLivedToken = async (shortLivedToken: string) => {
    const appId = import.meta.env.VITE_FACEBOOK_APP_ID;
    const appSecret = import.meta.env.VITE_FACEBOOK_APP_SECRET;
    
    try {
      const response = await fetch(
        `https://graph.facebook.com/v17.0/oauth/access_token?` +
        `grant_type=fb_exchange_token&` +
        `client_id=${appId}&` +
        `client_secret=${appSecret}&` +
        `fb_exchange_token=${shortLivedToken}`
      );
      
      const data = await response.json();
      return data.access_token;
    } catch (error) {
      console.error('Error exchanging token:', error);
      throw error;
    }
  };

  const handleFacebookConnect = () => {
    setIsConnectingFacebook(true);
    
    if (typeof window === 'undefined' || !window.FB) {
      toast({
        title: "Error",
        description: "Facebook SDK not loaded. Please try again.",
        status: "error",
        duration: 5000,
        isClosable: true,
      });
      setIsConnectingFacebook(false);
      return;
    }

    try {
      window.FB.getLoginStatus(function(response: any) {
        console.log(response)
        if (response && response.status === 'connected') {
          // Already logged in
          const shortLivedToken = response.authResponse.accessToken;
          exchangeForLongLivedToken(shortLivedToken)
            .then(longLivedToken => {
              setAccessToken(longLivedToken);
              toast({
                title: "Success",
                description: "Already connected to Facebook",
                status: "success",
                duration: 5000,
                isClosable: true,
              });
              setIsConnectingFacebook(false);
            })
            .catch(() => {
              toast({
                title: "Error",
                description: "Failed to get long-lived token",
                status: "error",
                duration: 5000,
                isClosable: true,
              });
              setIsConnectingFacebook(false);
            });
        } else {
          // Need to log in
          window.FB.login(function(loginResponse: any) {
            if (loginResponse && loginResponse.authResponse) {
              const shortLivedToken = loginResponse.authResponse.accessToken;
              exchangeForLongLivedToken(shortLivedToken)
                .then(longLivedToken => {
                  setAccessToken(longLivedToken);
                  toast({
                    title: "Success",
                    description: "Connected to Facebook",
                    status: "success",
                    duration: 5000,
                    isClosable: true,
                  });
                  setIsConnectingFacebook(false);
                })
                .catch(() => {
                  toast({
                    title: "Error",
                    description: "Failed to get long-lived token",
                    status: "error",
                    duration: 5000,
                    isClosable: true,
                  });
                  setIsConnectingFacebook(false);
                });
            } else {
              toast({
                title: "Error",
                description: "Failed to connect to Facebook",
                status: "error",
                duration: 5000,
                isClosable: true,
              });
              setIsConnectingFacebook(false);
            }
          }, { scope: 'public_profile,email' });
        }
      });
    } catch (error) {
      console.error('Error:', error);
      toast({
        title: "Error",
        description: "Failed to connect to Facebook",
        status: "error",
        duration: 5000,
        isClosable: true,
      });
      setIsConnectingFacebook(false);
    }
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

  // Only enhance schema for Facebook connector
  const isFacebookConnector = connector === 'FacebookCustomAudience';
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
              {!accessToken && connector === 'FacebookCustomAudience' && connectorType === "destination" && (
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

// Add TypeScript interface for the Facebook SDK
declare global {
  interface Window {
    FB: any;
    fbAsyncInit: () => void;
  }
}

export default ConnectorConfigForm;