import {
  Box,
  Image,
  Input,
  InputGroup,
  InputRightElement,
  Radio,
  RadioGroup,
  Select,
  Stack,
  Switch,
  Text,
  Textarea,
  Tooltip,
} from '@chakra-ui/react';
import ContentContainer from '@/components/ContentContainer';
import { useState } from 'react';
import { FiInfo } from 'react-icons/fi';
import FormFooter from '@/components/FormFooter';
import { useFormik } from 'formik';
import CodePlugin from '@/assets/icons/code.svg';
import NoCode from '@/assets/icons/connector-placeholder.svg';
import Badge from '@/components/Badge';
import { CreateDataAppPayload, DataAppsResponse } from '@/enterprise/services/types';
import EmbedCodeModal from '@/enterprise/views/DataApps/EmbedCodeModal.tsx';
import { RENDERING_OPTION_TYPE } from '@/enterprise/views/DataApps/DataAppsForm/types';
import ChromeExtensionModal from '@/enterprise/views/DataApps/ChromeExtensionModal';
import { CHATBOT_PROPERTIES } from '@/enterprise/dataApps/visualTypes';
import useDataAppMutations from '@/enterprise/hooks/mutations/useDataAppMutations';
import FiAIMessageCircle from '@/assets/icons/FiAIMessageCircle.svg';
import PreviewDataApp from '../BuildDataApp/PreviewDataApp';
import { useNavigate } from 'react-router-dom';
import useSteppedForm from '@/stores/useSteppedForm';

type RenderingOptionProps = {
  optionText: string;
  optionDesc: string;
  optionIcon: string;
  optionValue: RENDERING_OPTION_TYPE;
};

const RenderingOption = ({
  optionText,
  optionDesc,
  optionIcon,
  optionValue,
}: RenderingOptionProps) => (
  <Box
    paddingX='20px'
    paddingY='16px'
    backgroundColor='gray.100'
    flex={1}
    borderRadius='8px'
    borderColor='gray.400'
    borderWidth='1px'
  >
    <Radio
      value={optionValue}
      paddingY='8px'
      borderColor='gray.400'
      borderWidth='1.5px'
      width='100%'
      justifyContent='space-between'
      flexDirection='row-reverse'
    >
      <Box display='flex' gap='12px' alignItems='center'>
        <Image
          src={optionIcon}
          alt='rendering-option'
          maxHeight='100%'
          height='24px'
          width='24px'
          color='gray.600'
        />
        <Stack gap='2px' alignItems='start'>
          <Text size='sm' fontWeight='semibold'>
            {optionText}
          </Text>
          <Text size='xs' fontWeight='400' color='black.100'>
            {optionDesc}
          </Text>
        </Stack>
      </Box>
    </Radio>
  </Box>
);

const DataAppsFinaliseForm = ({
  isEdit = false,
  dataAppDetails,
  prefillDataAppProperties,
}: {
  isEdit?: boolean;
  dataAppDetails?: DataAppsResponse;
  prefillDataAppProperties?: CreateDataAppPayload;
}) => {
  const { createDataApp, updateDataApp } = useDataAppMutations();
  const [selectedRenderingOption, setSelectedRenderingOption] = useState(
    (dataAppDetails?.attributes?.rendering_type as RENDERING_OPTION_TYPE) ||
      RENDERING_OPTION_TYPE.EMBED,
  );
  const navigate = useNavigate();

  const { forms, handleMoveBack, stepInfo } = useSteppedForm();

  const dataAppProperties = forms.find(({ stepKey }) => stepKey === 'buildDataApp')?.data?.[
    'buildDataApp'
  ] as CreateDataAppPayload;

  const isChatBot = isEdit
    ? dataAppDetails?.attributes?.visual_components?.[0]?.component_type ===
      CHATBOT_PROPERTIES.value
    : dataAppProperties?.data_app?.visual_components?.[0]?.component_type ===
      CHATBOT_PROPERTIES.value;

  const getPayload = (
    payload: CreateDataAppPayload,
    data: {
      app_name: string;
      description: string;
      query_selector: string;
      container_position: string;
      whitelist_urls: string;
      auto_refresh_enabled: boolean;
    },
  ) => {
    payload.data_app.rendering_type = selectedRenderingOption;
    payload.data_app.meta_data = {
      rendering_type: selectedRenderingOption,
    };

    payload.data_app.name = data.app_name;
    payload.data_app.description = data.description;

    payload.data_app.meta_data = {
      ...payload.data_app.meta_data,
      query_selector: data.query_selector,
      run_method: 'auto',
      container_position: data.container_position,
      whitelist_urls: data.whitelist_urls.split(','),
      auto_refresh_enabled: data.auto_refresh_enabled,
    };
    return payload;
  };

  const formik = useFormik({
    enableReinitialize: true,
    initialValues: {
      app_name: dataAppDetails?.attributes?.name ?? dataAppProperties?.data_app?.name ?? '',
      description:
        dataAppDetails?.attributes?.description ?? dataAppProperties?.data_app?.description ?? '',
      query_selector:
        dataAppDetails?.attributes?.meta_data?.query_selector ??
        dataAppProperties?.data_app?.meta_data?.query_selector ??
        '',
      container_position:
        dataAppDetails?.attributes?.meta_data?.container_position ??
        dataAppProperties?.data_app?.meta_data?.container_position ??
        (isChatBot ? 'bottom_right' : 'prepend'),
      whitelist_urls:
        dataAppDetails?.attributes?.meta_data?.whitelist_urls?.join(',') ??
        dataAppProperties?.data_app?.meta_data?.whitelist_urls?.join(',') ??
        '',
      auto_refresh_enabled:
        dataAppDetails?.attributes?.meta_data?.auto_refresh_enabled ??
        dataAppProperties?.data_app?.meta_data?.auto_refresh_enabled ??
        true,
    },

    onSubmit: async (data) => {
      const dataAppPayload = getPayload(
        isEdit ? (prefillDataAppProperties as CreateDataAppPayload) : dataAppProperties,
        data,
      );
      const response =
        isEdit && dataAppDetails
          ? await updateDataApp.mutateAsync({
              id: dataAppDetails.id.toString(),
              data: dataAppPayload,
            })
          : await createDataApp.mutateAsync(dataAppPayload);

      if (response?.data?.attributes) {
        if (!isEdit) {
          navigate(`/data-apps/list/${response.data.id}?showModal=true`);
        }
      }
    },
  });

  const isContinueEnabled = isChatBot
    ? formik.values.app_name > '' && formik.values.container_position > ''
    : formik.values.app_name > '' &&
      formik.values.container_position > '' &&
      formik.values.query_selector > '';

  return (
    <Box display='flex' width='100%' justifyContent='center' marginBottom={isEdit ? '0' : '100px'}>
      <ContentContainer applyPadding={!isEdit}>
        <form onSubmit={formik.handleSubmit}>
          {!isEdit && (
            <Box
              backgroundColor={isEdit ? 'gray.100' : 'gray.200'}
              borderRadius='8px'
              marginBottom='16px'
              border={!isEdit ? '1px solid' : ''}
              borderColor={!isEdit ? 'gray.400' : ''}
            >
              <Text size='md' fontWeight='semibold' padding={isEdit ? '0px' : '24px'}>
                Review
              </Text>
              <PreviewDataApp visuals={dataAppProperties.data_app.visual_components} />
            </Box>
          )}
          <Box
            backgroundColor={isEdit ? 'gray.100' : 'gray.200'}
            padding={isEdit ? '0px' : '24px'}
            borderRadius='8px'
            borderWidth={isEdit ? '0px' : '1px'}
            marginBottom='16px'
            border={!isEdit ? '1px solid' : ''}
            borderColor={!isEdit ? 'gray.400' : ''}
          >
            <Box display='flex' flexDirection='column' gap='24px'>
              <Text size='md' fontWeight='semibold'>
                Configure your rendering settings
              </Text>
              <RadioGroup
                onChange={(value: RENDERING_OPTION_TYPE) => setSelectedRenderingOption(value)}
                value={selectedRenderingOption}
              >
                <Box display='flex' gap='24px' flexDirection={{ sm: 'column', md: 'row' }}>
                  <RenderingOption
                    optionIcon={CodePlugin}
                    optionText='Embeddable Code'
                    optionDesc='Generate a code snippet to embed your data app'
                    optionValue={RENDERING_OPTION_TYPE.EMBED}
                  />
                  <RenderingOption
                    optionIcon={NoCode}
                    optionText='No-Code Integration'
                    optionDesc='Use the Chrome Extension to integrate your data app'
                    optionValue={RENDERING_OPTION_TYPE.NO_CODE}
                  />
                  {isChatBot && (
                    <RenderingOption
                      optionIcon={FiAIMessageCircle}
                      optionText='Deploy to Assistant'
                      optionDesc={`Enable your chatbot in the Assistant's interface.`}
                      optionValue={RENDERING_OPTION_TYPE.ASSISTANT}
                    />
                  )}
                </Box>
              </RadioGroup>

              {!isChatBot && (
                <Box width='100%' display='flex' flexDirection='column' gap='8px'>
                  <Text fontWeight='semibold' size='sm'>
                    Query Selector
                  </Text>

                  <Input
                    data-testid='data-app-query-selector-input'
                    backgroundColor='gray.100'
                    placeholder='[data-id = "tabpanel-general"]'
                    onChange={formik.handleChange}
                    value={formik.values.query_selector}
                    borderStyle='solid'
                    borderWidth='1px'
                    borderColor='gray.400'
                    fontSize='14px'
                    borderRadius='6px'
                    _focusVisible={{ border: 'gray.400' }}
                    _hover={{ border: 'gray.400' }}
                    name='query_selector'
                  />
                  <Text color='gray.600' size='xs' fontWeight={500}>
                    Container is injected at the body of the content by default. Use query selectors
                    to inject in specific elements.
                  </Text>
                </Box>
              )}
              {selectedRenderingOption !== RENDERING_OPTION_TYPE.ASSISTANT && (
                <Box display='flex' gap='24px'>
                  <Box width='100%' display='flex' flexDirection='column' gap='8px'>
                    <Text fontWeight='semibold' size='sm'>
                      Container Position
                    </Text>
                    <Select
                      placeholder='Select container position'
                      backgroundColor='gray.100'
                      onChange={formik.handleChange}
                      value={formik.values.container_position}
                      borderStyle='solid'
                      borderWidth='1px'
                      borderColor='gray.400'
                      fontSize='14px'
                      name='container_position'
                    >
                      <option value={isChatBot ? 'bottom_left' : 'prepend'}>
                        {isChatBot ? 'Bottom Left' : 'Prepend (Before Content)'}
                      </option>
                      <option value={isChatBot ? 'bottom_right' : 'append'}>
                        {isChatBot ? 'Bottom Right' : 'Append (After Content)'}
                      </option>
                    </Select>
                    <Text color='gray.600' size='xs' fontWeight={500}>
                      Container position defines where the container is placed in relation to the
                      target content.
                    </Text>
                  </Box>
                  {selectedRenderingOption === RENDERING_OPTION_TYPE.NO_CODE && (
                    <Box width='100%' display='flex' flexDirection='column' gap='8px'>
                      <Box display='flex' gap='8px'>
                        <Text fontWeight='semibold' size='sm' color='gray.600'>
                          Run Method
                        </Text>
                        <Badge text='coming soon' variant='default' width='fit-content' />
                      </Box>
                      <Input
                        backgroundColor='gray.300'
                        value='Auto Run'
                        borderStyle='solid'
                        borderWidth='1px'
                        borderColor='gray.400'
                        fontSize='14px'
                        borderRadius='6px'
                        _focusVisible={{ border: 'gray.400' }}
                        _hover={{ border: 'gray.400' }}
                        name='run_method'
                        isDisabled
                      />
                    </Box>
                  )}
                </Box>
              )}
              {selectedRenderingOption === RENDERING_OPTION_TYPE.NO_CODE && (
                <Box width='100%' display='flex' flexDirection='column' gap='8px'>
                  <Box display='flex' alignItems='center'>
                    <Text size='sm' fontWeight='semibold'>
                      Whitelist URL
                    </Text>
                    <Text size='xs' color='gray.600' ml={1} fontWeight={400}>
                      (Optional)
                    </Text>
                  </Box>

                  <Input
                    backgroundColor='gray.100'
                    placeholder='Enter URL'
                    onChange={formik.handleChange}
                    value={formik.values.whitelist_urls}
                    borderStyle='solid'
                    borderWidth='1px'
                    borderColor='gray.400'
                    fontSize='14px'
                    borderRadius='6px'
                    _focusVisible={{ border: 'gray.400' }}
                    _hover={{ border: 'gray.400' }}
                    name='whitelist_urls'
                  />
                  <Text color='gray.600' size='xs' fontWeight={500}>
                    Comma separated list of urls to whitelist
                  </Text>
                </Box>
              )}
              <Box width='100%' display='flex' flexDirection='column' gap='8px'>
                <Box display='flex' justifyContent='space-between' alignItems='center'>
                  <Box display='flex' alignItems='center' gap='8px'>
                    <Text size='sm' fontWeight='semibold'>
                      Enable Auto Refresh
                    </Text>
                    <Tooltip
                      hasArrow
                      label='Automatically refresh data app content at intervals. When disabled, use the manual refresh button to update content.'
                      fontSize='xs'
                      placement='top'
                      backgroundColor='black.500'
                      color='gray.100'
                      borderRadius='6px'
                      padding='8px'
                      width='auto'
                    >
                      <Text color='gray.600'>
                        <FiInfo />
                      </Text>
                    </Tooltip>
                  </Box>
                  <Switch
                    name='auto_refresh_enabled'
                    isChecked={formik.values.auto_refresh_enabled}
                    onChange={(e) => formik.setFieldValue('auto_refresh_enabled', e.target.checked)}
                  />
                </Box>
                <Text color='gray.600' size='xs' fontWeight={500}>
                  When enabled, the data app will automatically refresh its content periodically.
                </Text>
              </Box>
            </Box>
          </Box>
          <Box
            backgroundColor={isEdit ? 'gray.100' : 'gray.200'}
            padding={isEdit ? '0px' : '24px'}
            borderRadius='8px'
            marginBottom='16px'
            border={!isEdit ? '1px solid' : ''}
            borderColor={!isEdit ? 'gray.400' : ''}
          >
            {!isEdit && (
              <Text size='md' fontWeight='semibold' marginBottom='24px'>
                Finalize settings for this app
              </Text>
            )}
            <Box>
              <Text marginBottom='8px' fontWeight='semibold' size='sm'>
                Data App Name
              </Text>
              <InputGroup>
                <InputRightElement>
                  <Tooltip
                    hasArrow
                    label='Please provide a name for your data app that include details about its content and business purpose for better clarity.'
                    fontSize='xs'
                    placement='top'
                    backgroundColor='black.500'
                    color='gray.100'
                    borderRadius='6px'
                    padding='8px'
                    width='auto'
                    marginLeft='8px'
                  >
                    <Text color='gray.600' marginLeft='8px'>
                      <FiInfo />
                    </Text>
                  </Tooltip>
                </InputRightElement>
                <Input
                  name='app_name'
                  type='text'
                  placeholder={`Enter data app name`}
                  background='gray.100'
                  marginBottom='24px'
                  onChange={formik.handleChange}
                  value={formik.values.app_name}
                  required
                  borderStyle='solid'
                  borderWidth='1px'
                  borderColor='gray.400'
                  fontSize='14px'
                  data-testid='data-app-name-input'
                />
              </InputGroup>
              <Box display='flex' alignItems='center' marginBottom='8px'>
                <Text size='sm' fontWeight='semibold'>
                  Description
                </Text>
                <Text size='xs' color='gray.600' ml={1} fontWeight={400}>
                  (Optional)
                </Text>
              </Box>
              <Textarea
                name='description'
                placeholder='Enter a description'
                background='gray.100'
                resize='none'
                onChange={formik.handleChange}
                value={formik.values.description}
                borderStyle='solid'
                borderWidth='1px'
                borderColor='gray.400'
                fontSize='14px'
              />
            </Box>
            <FormFooter
              ctaName={isEdit ? 'Save Changes' : 'Finish'}
              ctaType='submit'
              isCtaLoading={createDataApp.isPending || updateDataApp.isPending}
              isContinueCtaRequired
              isBackRequired={!isEdit}
              isDocumentsSectionRequired
              isAlignToContentContainer={isEdit}
              isCtaDisabled={!isContinueEnabled}
              onBackCtaClick={() =>
                handleMoveBack(
                  stepInfo?.formKey ?? '',
                  getPayload(
                    isEdit ? (prefillDataAppProperties as CreateDataAppPayload) : dataAppProperties,
                    formik.values,
                  ),
                )
              }
              extra={
                selectedRenderingOption !== RENDERING_OPTION_TYPE.ASSISTANT ? (
                  isEdit && selectedRenderingOption === RENDERING_OPTION_TYPE.EMBED ? (
                    <EmbedCodeModal
                      id={dataAppDetails?.id as unknown as string}
                      token={dataAppDetails?.attributes?.data_app_token as string}
                      variant='shell'
                    />
                  ) : isEdit ? (
                    <ChromeExtensionModal />
                  ) : undefined
                ) : undefined
              }
            />
          </Box>
        </form>
      </ContentContainer>
    </Box>
  );
};

export default DataAppsFinaliseForm;
