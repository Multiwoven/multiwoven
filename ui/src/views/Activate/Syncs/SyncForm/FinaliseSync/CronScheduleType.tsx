import { Box, Input, Text } from '@chakra-ui/react';
import { parseExpression } from 'cron-parser';
import { isValidCron } from 'cron-validator';
import { FormikContextType } from 'formik';

import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc';
import customParseFormat from 'dayjs/plugin/customParseFormat';
import { useState, ChangeEvent } from 'react';
dayjs.extend(utc);
dayjs.extend(customParseFormat);

const CronScheduleType = ({ formik }: { formik: FormikContextType<any> }): JSX.Element => {
  const [isValidCronExpression, setIsValidCronExpression] = useState(true);

  const getNextCronRuns = (cronExpression: string, count: number) => {
    const options = {
      currentDate: new Date(), // Start from current date
      endDate: '2100-01-01', // End date for calculating runs (can be adjusted based on your needs)
      iterator: true, // Return an iterator to get multiple occurrences
    };

    const interval = parseExpression(cronExpression, options);
    const nextRuns: string[] = [];

    for (let i = 0; i < count; i++) {
      const nextRun = interval.next();
      if ('value' in nextRun) {
        // Handle case when nextRun is a CronDate
        nextRuns.push(
          dayjs(nextRun.value.toString()).utc().format('MMM DD, YYYY, hh:mm:ss A [UTC]'),
        );
      } else {
        // Handle case when nextRun is an IteratorResult
        nextRuns.push(dayjs(nextRun.toString()).utc().format('MMM DD, YYYY, hh:mm:ss A [UTC]'));
      }
    }

    return nextRuns;
  };

  const handleCronExpressionChange = (inputEle: ChangeEvent<HTMLInputElement>) => {
    const {
      target: { value },
    } = inputEle;
    formik.handleChange(inputEle);

    if (!isValidCron(value)) {
      setIsValidCronExpression(false);
    } else {
      setIsValidCronExpression(true);
    }
  };

  let nextCronRuns: string[] = [];

  if (isValidCronExpression && formik.values.cron_expression > '') {
    nextCronRuns = getNextCronRuns(formik.values.cron_expression, 5);
  }

  return (
    <>
      <Text mb={4} fontWeight='600' size='sm'>
        Cron Expression
      </Text>
      <Box
        border='thin'
        padding='5px 10px 5px 10px'
        display='flex'
        backgroundColor='gray.100'
        borderRadius='8px'
        alignItems='center'
        borderWidth='1px'
        borderStyle='solid'
        borderColor='gray.400'
        height='40px'
      >
        <Input
          name='cron_expression'
          type='text'
          placeholder='Enter cron expression'
          border='none'
          _focusVisible={{ border: '#fff' }}
          value={formik.values.cron_expression}
          onChange={handleCronExpressionChange}
          isRequired
          color='gray.600'
          height='35px'
          padding={0}
          autoComplete='off'
        />
      </Box>
      {!isValidCronExpression && formik.values.cron_expression > '' && (
        <Text size='xs' color='red.500' mt={2}>
          Invalid Cron Expression
        </Text>
      )}
      {nextCronRuns.length > 0 && (
        <Box>
          <Text fontWeight='500' size='sm' mb={4} mt={4}>
            The next five sync runs will trigger at:
          </Text>
          {nextCronRuns.map((nextRun, index) => (
            <Text size='xs' color='black.200' mb={2} key={index}>
              {nextRun}
            </Text>
          ))}
        </Box>
      )}
    </>
  );
};

export default CronScheduleType;
