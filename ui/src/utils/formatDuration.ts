const formatDuration = (durationInSeconds: number): string => {
  if (
    durationInSeconds === null ||
    durationInSeconds === undefined ||
    Number.isNaN(durationInSeconds) ||
    durationInSeconds < 0
  ) {
    return '';
  }

  let duration: number;
  let unit: string;

  if (durationInSeconds >= 3600) {
    duration = durationInSeconds / 3600;
    unit = 'hour';
  } else if (durationInSeconds >= 60) {
    duration = durationInSeconds / 60;
    unit = 'minute';
  } else {
    duration = durationInSeconds;
    unit = 'second';
  }

  const roundedDuration = Math.round(duration * 10) / 10;
  return `${roundedDuration} ${unit}${roundedDuration === 1 ? '' : 's'}`;
};

export default formatDuration;
