import ContentContainer from '@/components/ContentContainer';
import { SteppedFormContext } from '@/components/SteppedForm/SteppedForm';
import { createSync } from '@/services/syncs';
import FormFooter from '@/components/FormFooter';
import {
  Box,
  Divider,
  Input,
  Radio,
  RadioGroup,
  Select,
  Stack,
  Text,
  Textarea,
} from '@chakra-ui/react';
import { useFormik } from 'formik';
import { useContext, useState } from 'react';
import { ConfigSync } from '../../types';
import { useNavigate } from 'react-router-dom';
import { CustomToastStatus } from '@/components/Toast/index';
import useCustomToast from '@/hooks/useCustomToast';
import CronScheduleType from './CronScheduleType';

const FinaliseSync = (): JSX.Element => {
  const { state } = useContext(SteppedFormContext);
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const showToast = useCustomToast();
  const navigate = useNavigate();

  const { forms } = state;
  const syncConfigForm = forms.find((form) => form.stepKey === 'configureSyncs');
  const syncConfigData = syncConfigForm?.data;

  const formik = useFormik({
    initialValues: {
      name: '',
      description: '',
      sync_mode: 'full_refresh',
      sync_interval: 0,
      sync_interval_unit: 'days',
      schedule_type: 'interval',
      cron_expression: '',
    },
    onSubmit: async (data) => {
      setIsLoading(true);
      try {
        const payload = {
          sync: {
            ...data,
            ...((syncConfigData?.configureSyncs ?? {}) as ConfigSync),
          },
        };

        const response = await createSync(payload);
        if (response?.data?.attributes) {
          showToast({
            status: CustomToastStatus.Success,
            title: 'Success!',
            description: 'Sync created successfully!',
            position: 'bottom-right',
          });

          navigate('/activate/syncs');
          return;
        }
        throw new Error();
      } catch {
        showToast({
          status: CustomToastStatus.Error,
          title: 'An error occurred.',
          description: 'Something went wrong while creating Sync.',
          position: 'bottom-right',
          isClosable: true,
        });
      } finally {
        setIsLoading(false);
      }
    },
  });

  return (
    <Box display='flex' width='100%' justifyContent='center'>
      <ContentContainer>
        <form onSubmit={formik.handleSubmit}>
          <Box backgroundColor='gray.300' padding='20px' borderRadius='8px' marginBottom='100px'>
            <Text fontWeight='600' mb='6' size='md'>
              Finalise setting for this sync
            </Text>
            <Box display='flex' alignItems='center' marginBottom='8px'>
              <Text size='sm' fontWeight='semibold'>
                Name
              </Text>
              <Text size='xs' color='gray.600' ml={1} fontWeight={400}>
                (Required)
              </Text>
            </Box>

            <Input
              name='name'
              value={formik.values.name}
              onChange={(e) => {
                // Prevent spaces at the beginning of the name
                const value = e.target.value;
                if (value === ' ' || value.startsWith(' ')) {
                  e.target.value = value.trimStart();
                }
                formik.handleChange(e);
              }}
              placeholder='Enter a name for this sync'
              background='gray.100'
              marginBottom='16px'
              isRequired
            />

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
              value={formik.values.description}
              placeholder='Enter a description'
              background='gray.100'
              resize='none'
              mb='6'
              onChange={formik.handleChange}
              borderWidth='1px'
              borderStyle='solid'
              borderColor='gray.400'
            />
            <Box
              display='flex'
              flexDir={{ base: 'column', md: 'row' }}
              justifyContent='space-between'
            >
              <Box>
                <Text mb='4' fontWeight='semibold' size='sm'>
                  Schedule type
                </Text>
                <RadioGroup
                  name='schedule_type'
                  value={formik.values.schedule_type}
                  onClick={formik.handleChange}
                >
                  <Stack direction='column'>
                    <Radio
                      value='manual'
                      display='flex'
                      alignItems='flex-start'
                      marginBottom='10px'
                      isDisabled
                    >
                      <Box position='relative' top='-5px'>
                        <Text fontWeight='medium' size='sm'>
                          Manual{' '}
                        </Text>
                        <Text size='xs' color='black.200'>
                          Trigger your sync manually in the app or using our API{' '}
                        </Text>
                      </Box>
                    </Radio>
                    <Radio
                      value='interval'
                      display='flex'
                      alignItems='flex-start'
                      backgroundColor='gray.100'
                      marginBottom='10px'
                    >
                      <Box position='relative' top='-5px'>
                        <Text fontWeight='medium' size='sm'>
                          Interval{' '}
                        </Text>
                        <Text size='xs' color='black.200'>
                          Schedule your sync to run on a set interval (e.g., once per hour)
                        </Text>
                      </Box>
                    </Radio>
                    <Radio
                      value='cron_expression'
                      display='flex'
                      alignItems='flex-start'
                      backgroundColor='gray.100'
                      marginBottom='10px'
                    >
                      <Box position='relative' top='-5px'>
                        <Text fontWeight='500' size='sm'>
                          Cron Expression{' '}
                        </Text>
                        <Text size='xs' color='black.200'>
                          Schedule your sync using a cron expression
                        </Text>
                      </Box>
                    </Radio>
                  </Stack>
                </RadioGroup>
              </Box>
              <Box width={{ base: '100%', lg: '40%' }}>
                {formik.values.schedule_type === 'interval' ? (
                  <>
                    <Text mb={4} fontWeight='semibold' size='sm'>
                      Schedule Configuration
                    </Text>
                    <Box
                      border='thin'
                      display='flex'
                      backgroundColor='gray.100'
                      borderRadius='8px'
                      alignItems='center'
                      borderWidth='1px'
                      borderStyle='solid'
                      borderColor='gray.400'
                      height='40px'
                      gap='12px'
                      maxW='450px'
                      w='fit-content'
                      px='12px'
                    >
                      <Box>
                        <Text size='sm' fontWeight='medium'>
                          Every
                        </Text>
                      </Box>
                      <Box>
                        <Input
                          name='sync_interval'
                          type='number'
                          placeholder='Enter a value'
                          border='none'
                          _focusVisible={{ border: 'gray.100' }}
                          value={formik.values.sync_interval}
                          onChange={formik.handleChange}
                          isRequired
                          height='35px'
                          minW='60px'
                          maxW='280px'
                        />
                      </Box>
                      <Divider orientation='vertical' height='24px' color='gray.400' />
                      <Box>
                        <Select
                          name='sync_interval_unit'
                          border='none'
                          _focusVisible={{ border: 'gray.100' }}
                          value={formik.values.sync_interval_unit}
                          onChange={formik.handleChange}
                          height='35px'
                          minW='120px'
                          w='full'
                          fontWeight='medium'
                          size='sm'
                        >
                          <option value='days'>Day(s)</option>
                          <option value='weeks'>Week(s)</option>
                        </Select>
                      </Box>
                    </Box>
                  </>
                ) : null}
                {formik.values.schedule_type === 'cron_expression' ? (
                  <CronScheduleType formik={formik} />
                ) : null}
              </Box>
            </Box>
          </Box>
          <FormFooter
            ctaName='Finish'
            ctaType='submit'
            isCtaLoading={isLoading}
            isBackRequired
            isContinueCtaRequired
          />
        </form>
      </ContentContainer>
    </Box>
  );
};

export default FinaliseSync;
