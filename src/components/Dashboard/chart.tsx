import React from 'react';
import Highcharts from 'highcharts/highstock';
import HighchartsReact from 'highcharts-react-official';

const options = {
  chart: {
    type: 'line',
  },
  title: {
    text: null, // Remove the default title
  },
  xAxis: {
    categories: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
  },
  yAxis: {
    title: {
      text: 'Number of Rows',
    },
  },
  series: [
    {
      name: 'Rows Processed',
      data: [15, 20, 25, 18, 22],
      color:"lightgreen",
    },
    {
      name: 'Rows Failed',
      data: [5, 8, 10, 6, 9],
      color:"red",
    },
  ],
};

export const LineChart = () => (
    <div className='p-3 bg-white'>
        <HighchartsReact highcharts={Highcharts} options={options} />
    </div>
);

