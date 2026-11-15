import { Box, Button, Image, Text } from '@chakra-ui/react';
import AISAuthIcon from '@/assets/images/ais-icon.svg';
import useProtectedNavigate from '@/enterprise/hooks/useProtectedNavigate';
import { UserActions } from '@/enterprise/types';
import useHostedStoreQueries from '@/enterprise/hooks/queries/useHostedStoreQueries';
import useHostedStoreMutations from '@/enterprise/hooks/mutations/useHostedStoreMutations';
import { HostedStoreTemplateResponse } from '@/enterprise/services/types';
import { HostedStoreTemplateActionState } from './types';
import { useAPIErrorsToast } from '@/hooks/useErrorToast';
import Loader from '@/components/Loader';

const ResourceCard = ({
  title,
  description,
  actionState = HostedStoreTemplateActionState.ComingSoon,
  onClick,
  ctaText = 'Setup',
  isCtaLoading = false,
  ctaTestId,
}: {
  title: string;
  description: string;
  actionState?: HostedStoreTemplateActionState;
  onClick?: () => void;
  ctaText?: string;
  isCtaLoading?: boolean;
  ctaTestId?: string;
}) => (
  <Box position='relative' flex='1'>
    <Box
      padding='20px'
      backgroundColor='gray.100'
      borderRadius='8px'
      border='1px solid'
      borderColor='gray.400'
      display='flex'
      flexDirection='column'
      gap='8px'
      justifyContent='start'
      alignItems='start'
      position='relative'
      opacity={actionState === HostedStoreTemplateActionState.ComingSoon ? 0.5 : 1}
    >
      <Box display='flex' flexDirection='row' gap='12px' alignItems='center'>
        <Box
          h='40px'
          w={'40px'}
          display='flex'
          justifyContent='center'
          alignItems='center'
          borderRadius='12px'
          boxShadow='0 2px 2px 0 rgba(255, 255, 255, 0.40) inset'
          border='1px solid'
          borderColor='gray.400'
          background='radial-gradient(49.67% 100% at 50% 0%, #7594FA 0%, #436DF8 100%), #FFF;'
        >
          <Image src={AISAuthIcon} alt='AI Squared Icon' h='20px' w='20px' />
        </Box>
        <Text size='lg' fontWeight='semibold'>
          {title}
        </Text>
      </Box>
      <Text size='sm' fontWeight='400' color='black.100'>
        {description}
      </Text>
      <Button
        data-testid={ctaTestId}
        variant='shell'
        size='sm'
        minWidth={0}
        width='auto'
        paddingX='12px'
        marginTop='12px'
        borderRadius='6px'
        fontWeight={700}
        fontSize='12px'
        isDisabled={actionState === HostedStoreTemplateActionState.ComingSoon}
        onClick={onClick}
        isLoading={isCtaLoading && actionState !== HostedStoreTemplateActionState.ComingSoon}
      >
        {ctaText}
      </Button>
    </Box>
    {actionState === HostedStoreTemplateActionState.ComingSoon && (
      <Box
        position='absolute'
        right='20px'
        top='20px'
        backgroundColor='gray.200'
        borderColor='gray.500'
        borderWidth='1px'
        borderStyle='solid'
        padding='2px 8px'
        borderRadius='4px'
        zIndex={200}
      >
        <Text size='xs' fontWeight={600} color='black.300'>
          Coming soon
        </Text>
      </Box>
    )}
  </Box>
);

const ListResources = () => {
  const navigate = useProtectedNavigate();
  const { useGetHostedDBTemplates } = useHostedStoreQueries();
  const { data: hostedDBTemplates, isLoading } = useGetHostedDBTemplates();
  const { createHostedDataStoreMutation } = useHostedStoreMutations();
  const apiErrorToast = useAPIErrorsToast();

  const handleStoreSetupOrManage = async (template: HostedStoreTemplateResponse) => {
    if (template.linked && template.linked_data_store_id) {
      navigate({
        to: `manage/vector-store/${template.linked_data_store_id}`,
        location: 'alerts',
        action: UserActions.Update,
      });
    } else {
      const payload = {
        hosted_data_store: {
          name: template.name,
          database_type: template.database_type,
          description: template.description,
          template_id: template.template_id,
        },
      };
      const response = await createHostedDataStoreMutation.mutateAsync(payload);
      if (response.errors) {
        apiErrorToast(response.errors);
        return;
      }

      if (response.data?.id) {
        navigate({
          to: `manage/vector-store/${response.data?.id}`,
          location: 'alerts',
          action: UserActions.Update,
        });
      }
    }
  };

  if (isLoading) {
    return <Loader />;
  }

  if (hostedDBTemplates?.errors) {
    apiErrorToast(hostedDBTemplates.errors);
    return;
  }

  return (
    <Box display='flex' flexDirection='row' gap='24px' w='100%'>
      {hostedDBTemplates?.data?.map((template: HostedStoreTemplateResponse) => (
        <ResourceCard
          key={template.id}
          title={template.name}
          description={template.description}
          onClick={() => handleStoreSetupOrManage(template)}
          actionState={template.action_state as HostedStoreTemplateActionState}
          ctaText={template.linked ? 'Manage' : 'Setup'}
          isCtaLoading={createHostedDataStoreMutation.isPending}
          ctaTestId={`resource-card-cta-${template.template_id}`}
        />
      ))}
    </Box>
  );
};

export default ListResources;
