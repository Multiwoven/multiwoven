import { Box, Divider, Input, Radio, RadioGroup, Select, Stack, Text } from '@chakra-ui/react';
import { FormikProps } from 'formik';
import { FinalizeSyncFormFields } from '../types';
import CronScheduleType from '../SyncForm/FinaliseSync/CronScheduleType';

type ScheduleFormProps = {
  formik: FormikProps<FinalizeSyncFormFields>;
  isEdit?: boolean;
};

const ScheduleForm = ({ formik, isEdit }: ScheduleFormProps) => {
  return (
    <Box
      backgroundColor={isEdit ? 'gray.100' : 'gray.200'}
      padding='24px'
      borderRadius='8px'
      marginBottom={'100px'}
    >
      <Text fontWeight='semibold' mb='6' size='md'>
        Finalise setting for this sync
      </Text>
      <Box display='flex' flexDir={{ base: 'column', md: 'row' }} justifyContent='space-between'>
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
                    <option value='minutes'>Minute(s)</option>
                    <option value='hours'>Hour(s)</option>
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
  );
};

export default ScheduleForm;
